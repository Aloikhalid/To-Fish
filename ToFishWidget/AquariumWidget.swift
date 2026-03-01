//
//  AquariumWidget.swift
//  To Fish
//
//  Created by alya Alabdulrahim on 10/09/1447 AH.
//
//import WidgetKit
//import SwiftUI
//
//private let appGroupID = "group.com.tofish"
//
//// MARK: - Data models
//// `duration` is a plain String so there is no enum raw-value mismatch
//// between the widget and the main app's TaskDuration enum.
//// All other property names must stay identical to what TaskViewModel encodes.
//
//struct WidgetSubtask: Identifiable, Codable {
//    let id: UUID
//    let title: String
//    let isComplete: Bool
//}
//
//struct WidgetTask: Identifiable, Codable {
//    let id: UUID
//    let fishName: String
//    let taskDescription: String
//    let duration: String        
//    let isMultiStep: Bool
//    let subtasks: [WidgetSubtask]
//    let dateAdded: Date
//    let completedDate: Date?
//    let isComplete: Bool
//}
//
//// MARK: - Timeline entry
//
//struct AquariumEntry: TimelineEntry {
//    let date: Date
//    let tasks: [WidgetTask]
//}
//
//// MARK: - Timeline provider
//
//struct AquariumProvider: TimelineProvider {
//
//    func placeholder(in context: Context) -> AquariumEntry {
//        let sample = WidgetTask(
//            id: UUID(), fishName: "Bubbles", taskDescription: "",
//            duration: "One day", isMultiStep: false, subtasks: [],
//            dateAdded: Date(), completedDate: nil, isComplete: false
//        )
//        return AquariumEntry(date: Date(), tasks: [sample])
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (AquariumEntry) -> Void) {
//        completion(AquariumEntry(date: Date(), tasks: loadTasks()))
//    }
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<AquariumEntry>) -> Void) {
//        let entry = AquariumEntry(date: Date(), tasks: loadTasks())
//        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
//        completion(Timeline(entries: [entry], policy: .after(next)))
//    }
//
//    private func loadTasks() -> [WidgetTask] {
//        guard
//            let defaults = UserDefaults(suiteName: appGroupID),
//            let data = defaults.data(forKey: "activeTasks"),
//            let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
//        else { return [] }
//        return tasks.filter { !$0.isComplete }
//    }
//}
//
//// MARK: - Widget entry view
//
//struct AquariumWidgetEntryView: View {
//    let entry: AquariumEntry
//
//    var body: some View {
//        TimelineView(.animation) { context in
//            AquariumWidgetScene(
//                tasks: Array(entry.tasks.prefix(5)),
//                time: context.date.timeIntervalSinceReferenceDate
//            )
//        }
//        .containerBackground(for: .widget) { Color.clear }
//    }
//}
//
//// MARK: - Aquarium scene
//
//struct AquariumWidgetScene: View {
//    let tasks: [WidgetTask]
//    let time: Double
//
//    private var sunlightOpacity: Double {
//        0.5 + 0.25 * sin(time * 0.2)
//    }
//
//    private var waveOffset: CGFloat {
//        CGFloat(sin(time * 0.25) * 6)
//    }
//
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                Image("bg_aquarium")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//
//                Image("layer_sunlight")
//                    .resizable()
//                    .scaledToFill()
//                    .opacity(sunlightOpacity)
//                    .blendMode(.screen)
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//
//                Image("layer_stars")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//
//                ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
//                    WidgetFishView(
//                        task: task,
//                        time: time,
//                        index: idx,
//                        totalCount: tasks.count,
//                        width: geo.size.width,
//                        height: geo.size.height
//                    )
//                }
//
//                ForEach(tasks.filter { $0.isMultiStep }, id: \.id) { task in
//                    ForEach(task.subtasks.filter { $0.isComplete }, id: \.id) { sub in
//                        WidgetBabySeahorseView(
//                            subtask: sub,
//                            parentID: task.id,
//                            time: time,
//                            width: geo.size.width,
//                            height: geo.size.height
//                        )
//                    }
//                }
//
//                Image("layer_seaweed1")
//                    .resizable()
//                    .scaledToFill()
//                    .offset(x: waveOffset)
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//
//                Image("layer_seaweed2")
//                    .resizable()
//                    .scaledToFill()
//                    .offset(x: -waveOffset * 1.3)
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//
//                if tasks.isEmpty {
//                    VStack(spacing: 4) {
//                        Text("No fish yet!")
//                            .font(.custom("Kavoon-Regular", size: 15))
//                            .foregroundColor(.white)
//                        Text("Add a task in the app")
//                            .font(.custom("Kavoon-Regular", size: 11))
//                            .foregroundColor(.white.opacity(0.75))
//                    }
//                }
//            }
//            .frame(width: geo.size.width, height: geo.size.height)
//            .clipped()
//        }
//    }
//}
//
//// MARK: - Fish view
//
//struct WidgetFishView: View {
//    let task: WidgetTask
//    let time: Double
//    let index: Int
//    let totalCount: Int
//    let width: CGFloat
//    let height: CGFloat
//
//    private var phase: Double {
//        task.id.uuidString.unicodeScalars
//            .reduce(0.0) { $0 + Double($1.value) }
//            .truncatingRemainder(dividingBy: .pi * 2)
//    }
//
//    private var swimSpeed: Double { 0.12 + Double(index) * 0.025 }
//    private var floatSpeed: Double { 0.35 + Double(index) * 0.08 }
//
//    private var xOffset: CGFloat {
//        CGFloat(sin(time * swimSpeed + phase)) * width * 0.38
//    }
//
//    private var yOffset: CGFloat {
//        let spread = totalCount > 1 ? Double(height) * 0.32 : 0
//        let baseY = totalCount > 1
//            ? (Double(index) / Double(totalCount - 1) - 0.5) * spread
//            : 0
//        let drift = sin(time * floatSpeed + phase * 1.3) * Double(height) * 0.05
//        return CGFloat(baseY + drift)
//    }
//
//    private var movingRight: Bool {
//        cos(time * swimSpeed + phase) > 0
//    }
//
//    private var fishImage: String {
//        if task.isMultiStep { return "seahorse" }
//        let images = ["fish_pink", "fish_blue", "fish_yellow"]
//        let uuidInt = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
//        return images[uuidInt % images.count]
//    }
//
//    private var fishSize: CGFloat {
//        task.isMultiStep ? width * 0.16 : width * 0.22
//    }
//
//    private var flipX: CGFloat {
//        task.isMultiStep ? (movingRight ? -1 : 1) : (movingRight ? 1 : -1)
//    }
//
//    var body: some View {
//        Image(fishImage)
//            .resizable()
//            .scaledToFit()
//            .frame(width: fishSize)
//            .scaleEffect(x: flipX, y: 1)
//            .offset(x: xOffset, y: yOffset)
//    }
//}
//
//// MARK: - Baby seahorse view
//
//struct WidgetBabySeahorseView: View {
//    let subtask: WidgetSubtask
//    let parentID: UUID
//    let time: Double
//    let width: CGFloat
//    let height: CGFloat
//
//    private var phase: Double {
//        (subtask.id.uuidString + parentID.uuidString)
//            .unicodeScalars
//            .reduce(0.0) { $0 + Double($1.value) }
//            .truncatingRemainder(dividingBy: .pi * 2)
//    }
//
//    private var movingRight: Bool {
//        cos(time * 0.18 + phase) > 0
//    }
//
//    var body: some View {
//        Image("seahorse_baby")
//            .resizable()
//            .scaledToFit()
//            .frame(width: width * 0.07)
//            .scaleEffect(x: movingRight ? 1 : -1, y: 1)
//            .offset(
//                x: CGFloat(sin(time * 0.18 + phase)) * width * 0.28,
//                y: CGFloat(sin(time * 0.28 + phase * 1.5)) * height * 0.3
//            )
//    }
//}
//
//// MARK: - Widget configuration
//
//struct AquariumWidget: Widget {
//    let kind = "AquariumWidget"
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: AquariumProvider()) { entry in
//            AquariumWidgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("My Aquarium")
//        .description("Watch your fish swim.")
//        .supportedFamilies([.systemMedium, .systemLarge])
//    }
//}
//
//// MARK: - Widget bundle
//
//@main
//struct AquariumWidgetBundle: WidgetBundle {
//    var body: some Widget {
//        AquariumWidget()
//    }
//}
import WidgetKit
import SwiftUI
 
// MARK: - Timeline entry
 
struct AquariumEntry: TimelineEntry {
    let date: Date
}
 
// MARK: - Timeline provider
 
struct AquariumProvider: TimelineProvider {
    func placeholder(in context: Context) -> AquariumEntry {
        AquariumEntry(date: Date())
    }
 
    func getSnapshot(in context: Context, completion: @escaping (AquariumEntry) -> Void) {
        completion(AquariumEntry(date: Date()))
    }
 
    func getTimeline(in context: Context, completion: @escaping (Timeline<AquariumEntry>) -> Void) {
        let entry = AquariumEntry(date: Date())
        // Refresh every hour — nothing to update, just keeps the widget alive
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
 
// MARK: - Widget entry view
 
struct AquariumWidgetEntryView: View {
    let entry: AquariumEntry
 
    var body: some View {
        TimelineView(.animation) { context in
            AquariumWidgetScene(time: context.date.timeIntervalSinceReferenceDate)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}
 
// MARK: - Aquarium scene
 
private struct StaticFish {
    let image: String
    let phase: Double   // unique offset so each fish is out of sync
    let swimSpeed: Double
    let floatSpeed: Double
    let yLane: Double   // -0.5 … 0.5 of height, baseline vertical position
    let isSeahorse: Bool
 
    static let all: [StaticFish] = [
        StaticFish(image: "fish_pink",   phase: 0.0,  swimSpeed: 0.11, floatSpeed: 0.32, yLane: -0.18, isSeahorse: false),
        StaticFish(image: "fish_blue",   phase: 2.1,  swimSpeed: 0.14, floatSpeed: 0.27, yLane:  0.05, isSeahorse: false),
        StaticFish(image: "fish_yellow", phase: 4.3,  swimSpeed: 0.09, floatSpeed: 0.40, yLane:  0.22, isSeahorse: false),
        StaticFish(image: "seahorse",    phase: 1.5,  swimSpeed: 0.08, floatSpeed: 0.22, yLane: -0.05, isSeahorse: true),
    ]
}
 
struct AquariumWidgetScene: View {
    let time: Double
 
    private var sunlightOpacity: Double { 0.5 + 0.25 * sin(time * 0.2) }
    private var waveOffset: CGFloat    { CGFloat(sin(time * 0.25) * 6) }
 
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Image("bg_aquarium")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
 
                // Sunlight shimmer
                Image("layer_sunlight")
                    .resizable()
                    .scaledToFill()
                    .opacity(sunlightOpacity)
                    .blendMode(.screen)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
 
                // Stars / sparkles
                Image("layer_stars")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
 
                // Fish
                ForEach(StaticFish.all.indices, id: \.self) { i in
                    let fish = StaticFish.all[i]
                    let xOff = CGFloat(sin(time * fish.swimSpeed + fish.phase)) * geo.size.width * 0.38
                    let yBase = fish.yLane * Double(geo.size.height)
                    let yDrift = sin(time * fish.floatSpeed + fish.phase * 1.3) * Double(geo.size.height) * 0.05
                    let yOff = CGFloat(yBase + yDrift)
                    let movingRight = cos(time * fish.swimSpeed + fish.phase) > 0
                    let flipX: CGFloat = fish.isSeahorse
                        ? (movingRight ? -1 : 1)
                        : (movingRight ? 1 : -1)
                    let size: CGFloat = fish.isSeahorse ? geo.size.width * 0.16 : geo.size.width * 0.22
 
                    Image(fish.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size)
                        .scaleEffect(x: flipX, y: 1)
                        .offset(x: xOff, y: yOff)
                }
 
                // Seaweed (foreground)
                Image("layer_seaweed1")
                    .resizable()
                    .scaledToFill()
                    .offset(x: waveOffset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
 
                Image("layer_seaweed2")
                    .resizable()
                    .scaledToFill()
                    .offset(x: -waveOffset * 1.3)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}
 
// MARK: - Widget configuration
 
struct AquariumWidget: Widget {
    let kind = "AquariumWidget"
 
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AquariumProvider()) { entry in
            AquariumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Aquarium")
        .description("Watch your fish swim.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
 
// MARK: - Widget bundle
 
@main
struct AquariumWidgetBundle: WidgetBundle {
    var body: some Widget {
        AquariumWidget()
    }
}
