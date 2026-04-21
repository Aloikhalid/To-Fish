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
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    private func loadTasks() -> [WidgetTask] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: "activeTasks"),
            let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return tasks.filter { !$0.isComplete }
    }
}

// MARK: - Helpers

private func fishImageName(for task: WidgetTask) -> String {
    if task.isMultiStep { return "seahorse" }
    let pool = ["fish_pink", "fish_blue", "fish_yellow"]
    let idx = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) } % pool.count
    return pool[idx]
}

private let cardColor = Color(red: 0.05, green: 0.27, blue: 0.39)

// MARK: - Next Task Card

struct NextTaskCard: View {
    let task: WidgetTask?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(cardColor.opacity(0.84))

            if let task {
                // Fish fills the card, padded to leave room for the bottom label
                Image(fishImageName(for: task))
                    .resizable()
                    .scaledToFit()
                    .padding(.top, 10)
                    .padding(.bottom, 46)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bubbles overlaid top-right above the fish
                VStack(spacing: 4) {
                    Image("bubble_button")
                        .resizable().scaledToFit()
                        .frame(width: 14)
                    Image("bubble_button")
                        .resizable().scaledToFit()
                        .frame(width: 22)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
                .padding(.trailing, 16)

                // Label pinned to bottom-left
                HStack(alignment: .center, spacing: 6) {
                    Image("choice_star")
                        .resizable().scaledToFit()
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.fishName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(task.duration) left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.88, blue: 0.98))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            } else {
                VStack(spacing: 8) {
                    Image("fish_sad")
                        .resizable().scaledToFit()
                        .frame(width: 55)
                    Text("No tasks!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Checklist Card

struct ChecklistCard: View {
    let tasks: [WidgetTask]

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(cardColor.opacity(0.84))

            VStack(alignment: .leading, spacing: 14) {
                if tasks.isEmpty {
                    HStack(spacing: 8) {
                        Image("choice_star")
                            .resizable().scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("No fish yet!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                } else {
                    ForEach(Array(tasks.prefix(4))) { task in
                        HStack(spacing: 8) {
                            Image("choice_star")
                                .resizable().scaledToFit()
                                .frame(width: 22, height: 22)
                            Text(task.fishName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Entry view

struct ToFishWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AquariumEntry

    var body: some View {
        if family == .systemSmall {
            NextTaskCard(task: entry.tasks.first)
                .padding(10)
                .containerBackground(for: .widget) {
                    Image("small_background")
                        .resizable()
                        .scaledToFill()
                }
        } else {
            HStack(spacing: 10) {
                ChecklistCard(tasks: entry.tasks)
                NextTaskCard(task: entry.tasks.first)
            }
            .padding(12)
            .containerBackground(for: .widget) {
                Image("medium_background")
                    .resizable()
                    .scaledToFill()
            }
        }
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

private let previewTasks: [WidgetTask] = [
    WidgetTask(id: UUID(), fishName: "lolo",  taskDescription: "Study",  duration: "One day",  isMultiStep: false, subtasks: [], dateAdded: Date(), completedDate: nil, isComplete: false),
    WidgetTask(id: UUID(), fishName: "Meme",  taskDescription: "Cook",   duration: "3 days",   isMultiStep: false, subtasks: [], dateAdded: Date(), completedDate: nil, isComplete: false),
    WidgetTask(id: UUID(), fishName: "Fajer", taskDescription: "Work",   duration: "One week", isMultiStep: false, subtasks: [], dateAdded: Date(), completedDate: nil, isComplete: false),
    WidgetTask(id: UUID(), fishName: "Alia",  taskDescription: "Read",   duration: "One week", isMultiStep: true,  subtasks: [], dateAdded: Date(), completedDate: nil, isComplete: false),
]

#Preview("Small – with task", as: .systemSmall) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: previewTasks)
}

#Preview("Small – empty", as: .systemSmall) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: [])
}

#Preview("Medium – with tasks", as: .systemMedium) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: previewTasks)
}

#Preview("Medium – empty", as: .systemMedium) {
    AquariumWidget()
} timeline: {
    AquariumEntry(date: .now, tasks: [])
}
