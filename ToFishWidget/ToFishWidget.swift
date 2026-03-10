import WidgetKit
import SwiftUI

private let appGroupID = "group.com.tofish"

// MARK: - Data models

struct WidgetSubtask: Identifiable, Decodable {
    let id: UUID
    let title: String
    let isComplete: Bool
}

struct WidgetTask: Identifiable, Decodable {
    let id: UUID
    let fishName: String
    let taskDescription: String
    let duration: String
    let isMultiStep: Bool
    let subtasks: [WidgetSubtask]
    let dateAdded: Date
    let completedDate: Date?
    let isComplete: Bool
}

// MARK: - Timeline entry

struct AquariumEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

// MARK: - Timeline provider

struct AquariumProvider: TimelineProvider {
    func placeholder(in context: Context) -> AquariumEntry {
        AquariumEntry(date: Date(), tasks: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (AquariumEntry) -> Void) {
        completion(AquariumEntry(date: Date(), tasks: loadTasks()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AquariumEntry>) -> Void) {
        let entry = AquariumEntry(date: Date(), tasks: loadTasks())
        let next  = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func loadTasks() -> [WidgetTask] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: "activeTasks"),
            let tasks    = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return tasks.filter { !$0.isComplete }
    }
}

// MARK: - Entry view

struct ToFishWidgetEntryView: View {
    let entry: AquariumEntry
    var body: some View {
        AquariumWidgetScene(
            tasks: Array(entry.tasks.prefix(5)),
            time: entry.date.timeIntervalSinceReferenceDate
        )
        .containerBackground(for: .widget) {
            Image("bg_aquarium")
                .resizable()
                .scaledToFill()
        }
    }
}

// MARK: - Scene helpers

private struct StaticFish {
    let image: String
    let phase: Double
    let swimSpeed: Double
    let floatSpeed: Double
    let yLane: Double
    let isSeahorse: Bool

    static let all: [StaticFish] = [
        StaticFish(image: "fish_pink",   phase: 0.0, swimSpeed: 0.11, floatSpeed: 0.32, yLane: -0.18, isSeahorse: false),
        StaticFish(image: "fish_blue",   phase: 2.1, swimSpeed: 0.14, floatSpeed: 0.27, yLane:  0.05, isSeahorse: false),
        StaticFish(image: "fish_yellow", phase: 4.3, swimSpeed: 0.09, floatSpeed: 0.40, yLane:  0.22, isSeahorse: false),
        StaticFish(image: "seahorse",    phase: 1.5, swimSpeed: 0.08, floatSpeed: 0.22, yLane: -0.05, isSeahorse: true),
    ]

    static func from(tasks: [WidgetTask]) -> [StaticFish] {
        guard !tasks.isEmpty else { return all }
        let images = ["fish_pink", "fish_blue", "fish_yellow"]
        return tasks.enumerated().map { idx, task in
            let phase   = task.id.uuidString.unicodeScalars
                .reduce(0.0) { $0 + Double($1.value) }
                .truncatingRemainder(dividingBy: .pi * 2)
            let uuidInt = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            let image   = task.isMultiStep ? "seahorse" : images[uuidInt % images.count]
            let yLane   = tasks.count > 1
                ? (Double(idx) / Double(tasks.count - 1) - 0.5) * 0.6
                : 0.0
            return StaticFish(
                image: image, phase: phase,
                swimSpeed: 0.09 + Double(idx) * 0.025,
                floatSpeed: 0.30 + Double(idx) * 0.08,
                yLane: yLane, isSeahorse: task.isMultiStep
            )
        }
    }
}

struct AquariumWidgetScene: View {
    let tasks: [WidgetTask]
    let time: Double

    private var fish: [StaticFish] { StaticFish.from(tasks: tasks) }
    private var sunlightOpacity: Double { 0.5 + 0.25 * sin(time * 0.2) }
    private var waveOffset: CGFloat    { CGFloat(sin(time * 0.25) * 6) }

    var body: some View {
        ZStack {
            Image("layer_sunlight")
                .resizable().scaledToFill()
                .opacity(sunlightOpacity).blendMode(.screen)
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()

            Image("layer_stars")
                .resizable().scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()

            ForEach(fish.indices, id: \.self) { i in
                let f      = fish[i]
                let xOff   = CGFloat(sin(time * f.swimSpeed + f.phase)) * 115
                let yOff   = CGFloat(f.yLane * 65 + sin(time * f.floatSpeed + f.phase * 1.3) * 8)
                let goRight = cos(time * f.swimSpeed + f.phase) > 0
                let flipX: CGFloat = f.isSeahorse ? (goRight ? -1 : 1) : (goRight ? 1 : -1)
                let size: CGFloat  = f.isSeahorse ? 38 : 52

                Image(f.image)
                    .resizable().scaledToFit()
                    .frame(width: size)
                    .scaleEffect(x: flipX, y: 1)
                    .offset(x: xOff, y: yOff)
            }

            Image("layer_seaweed1")
                .resizable().scaledToFill()
                .offset(x: waveOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()

            Image("layer_seaweed2")
                .resizable().scaledToFill()
                .offset(x: -waveOffset * 1.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()

            if tasks.isEmpty {
                VStack(spacing: 4) {
                    Text("No fish yet!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Add a task in the app")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - Widget configuration

struct AquariumWidget: Widget {
    let kind = "AquariumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AquariumProvider()) { entry in
            ToFishWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Aquarium")
        .description("Watch your fish swim.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Previews

private let previewTasks: [WidgetTask] = [
    WidgetTask(id: UUID(), fishName: "Bubbles", taskDescription: "Study for exam",
               duration: "One day", isMultiStep: false, subtasks: [],
               dateAdded: Date(), completedDate: nil, isComplete: false),
    WidgetTask(id: UUID(), fishName: "Nemo",    taskDescription: "Buy groceries",
               duration: "3 days", isMultiStep: false, subtasks: [],
               dateAdded: Date(), completedDate: nil, isComplete: false),
    WidgetTask(id: UUID(), fishName: "Coral",   taskDescription: "Write report",
               duration: "One week", isMultiStep: true,
               subtasks: [WidgetSubtask(id: UUID(), title: "Research", isComplete: true)],
               dateAdded: Date(), completedDate: nil, isComplete: false),
]

#Preview("Empty", as: .systemMedium) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: [])
}

#Preview("With fish", as: .systemMedium) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: previewTasks)
}

#Preview("Large", as: .systemLarge) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: previewTasks)
}
