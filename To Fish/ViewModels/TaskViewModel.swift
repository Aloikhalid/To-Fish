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

        let activeDescriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate<TaskModel> { task in task.isComplete == false },
            sortBy: [SortDescriptor(\.dateAdded)]
        )
        let achievementDescriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate<TaskModel> { task in task.isComplete == true },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )

        activeTasks = (try? context.fetch(activeDescriptor)) ?? []
        achievements = (try? context.fetch(achievementDescriptor)) ?? []
        syncToWidget()
    }

    // MARK: - Add & Remove
    func addTask(_ task: TaskModel) {
        modelContext?.insert(task)
        save()
        fetch()
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

    func allSubtasksComplete(for task: TaskModel) -> Bool {
        guard task.isMultiStep else { return true }
        return task.subtasks.allSatisfy { $0.isComplete }
    }

    // MARK: - Time Calculations
    func daysRemaining(for task: TaskModel) -> Int {
        let deadline = Calendar.current.date(byAdding: .day, value: daysForDuration(task.duration), to: task.dateAdded)!
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        return max(0, remaining)
    }

    func hoursRemaining(for task: TaskModel) -> Int {
        let deadline = Calendar.current.date(byAdding: .day, value: daysForDuration(task.duration), to: task.dateAdded)!
        let remaining = Calendar.current.dateComponents([.hour], from: Date(), to: deadline).hour ?? 0
        return max(0, remaining)
    }

    func isLastDay(for task: TaskModel) -> Bool {
        return daysRemaining(for: task) == 0 && hoursRemaining(for: task) > 0
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
    private func save() {
        try? modelContext?.save()
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
