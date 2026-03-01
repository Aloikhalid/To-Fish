import Foundation
import Combine
import SwiftData
import WidgetKit

class TaskViewModel: ObservableObject {
    @Published var activeTasks: [TaskModel] = []
    @Published var achievements: [TaskModel] = []

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetch()
    }

    // MARK: - Fetch
    func fetch() {
        guard let context = modelContext else { return }

        // Fetch all tasks and filter in memory to avoid #Predicate Bool comparison
        // issues that can silently return empty results on some SwiftData versions.
        let descriptor = FetchDescriptor<TaskModel>(
            sortBy: [SortDescriptor(\.dateAdded)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        activeTasks = all.filter { !$0.isComplete }
        achievements = all
            .filter { $0.isComplete }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
        syncToWidget()
    }

    // MARK: - Add & Remove
    func addTask(_ task: TaskModel) {
        modelContext?.insert(task)
        save()
        // Directly append instead of re-fetching: SwiftData may not surface a
        // just-inserted object to an immediate same-context fetch, so the task
        // would silently disappear from activeTasks until the next cold launch.
        activeTasks.append(task)
        syncToWidget()
    }

    func releaseTask(_ task: TaskModel) {
        NotificationManager.cancel(for: task.id)
        task.completedDate = Date()
        task.isComplete = true
        save()
        fetch()
    }

    func deleteTask(_ task: TaskModel) {
        NotificationManager.cancel(for: task.id)
        modelContext?.delete(task)
        save()
        fetch()
    }

    func deleteAchievement(_ task: TaskModel) {
        modelContext?.delete(task)
        save()
        fetch()
    }

    // MARK: - Subtasks
    func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        if let task = activeTasks.first(where: { $0.id == taskID }),
           let subtask = task.subtasks.first(where: { $0.id == subtaskID }) {
            subtask.isComplete.toggle()
            save()
            fetch()
        }
    }

    // BUG-08: returns false when isMultiStep but no subtasks exist (prevents vacuous-truth bypass)
    func allSubtasksComplete(for task: TaskModel) -> Bool {
        guard task.isMultiStep else { return true }
        guard !task.subtasks.isEmpty else { return false }
        return task.subtasks.allSatisfy { $0.isComplete }
    }

    // MARK: - Time Calculations
    // BUG-01 & BUG-04: single secondsRemaining helper; no force-unwrap; consistent time source
    func secondsRemaining(for task: TaskModel) -> TimeInterval {
        guard let deadline = Calendar.current.date(
            byAdding: .day,
            value: daysForDuration(task.duration),
            to: task.dateAdded
        ) else { return 0 }
        return max(0, deadline.timeIntervalSinceNow)
    }

    func daysRemaining(for task: TaskModel) -> Int {
        Int(secondsRemaining(for: task) / 86400)
    }

    func hoursRemaining(for task: TaskModel) -> Int {
        Int(secondsRemaining(for: task) / 3600)
    }

    // BUG-04: correct last-day check using total seconds
    func isLastDay(for task: TaskModel) -> Bool {
        let secs = secondsRemaining(for: task)
        return secs > 0 && secs < 86400
    }

    private func daysForDuration(_ duration: TaskDuration) -> Int {
        switch duration {
        case .oneDay:    return 1
        case .threeDays: return 3
        case .oneWeek:   return 7
        }
    }

    // MARK: - Widget Sync
    private func syncToWidget() {
        let payload = activeTasks.map { task in
            WidgetTaskData(
                id: task.id,
                fishName: task.fishName,
                taskDescription: task.taskDescription,
                duration: task.duration.rawValue,
                isMultiStep: task.isMultiStep,
                subtasks: task.subtasks.map {
                    WidgetSubtaskData(id: $0.id, title: $0.title, isComplete: $0.isComplete)
                },
                dateAdded: task.dateAdded,
                completedDate: task.completedDate,
                isComplete: task.isComplete
            )
        }
        guard
            let data = try? JSONEncoder().encode(payload),
            let defaults = UserDefaults(suiteName: "group.com.tofish")
        else { return }
        defaults.set(data, forKey: "activeTasks")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Save
    // BUG-20: print encoding failures instead of silently dropping them
    private func save() {
        do {
            try modelContext?.save()
        } catch {
            print("TaskViewModel save error: \(error)")
        }
    }
}

// MARK: - Widget DTOs
private struct WidgetTaskData: Codable {
    let id: UUID
    let fishName: String
    let taskDescription: String
    let duration: String
    let isMultiStep: Bool
    let subtasks: [WidgetSubtaskData]
    let dateAdded: Date
    let completedDate: Date?
    let isComplete: Bool
}

private struct WidgetSubtaskData: Codable {
    let id: UUID
    let title: String
    let isComplete: Bool
}
