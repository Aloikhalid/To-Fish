import Foundation
import SwiftData

enum TaskDuration: String, Codable, CaseIterable {
    case oneDay = "One day"
    case threeDays = "3 days"
    case oneWeek = "One week"

    var timeInterval: TimeInterval {
        switch self {
        case .oneDay:    return 86400
        case .threeDays: return 259200
        case .oneWeek:   return 604800
        }
    }
}

@Model
class Subtask {
    var id: UUID
    var title: String
    var isComplete: Bool

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isComplete = false
    }
}

@Model
class TaskModel {
    var id: UUID
    var fishName: String
    var taskDescription: String
    var dateAdded: Date
    var duration: TaskDuration
    var isMultiStep: Bool
    @Relationship(deleteRule: .cascade) var subtasks: [Subtask]
    var isComplete: Bool
    var completedDate: Date?

    init(fishName: String, taskDescription: String, duration: TaskDuration, isMultiStep: Bool, subtasks: [Subtask]) {
        self.id = UUID()
        self.fishName = fishName
        self.taskDescription = taskDescription
        self.dateAdded = Date()
        self.duration = duration
        self.isMultiStep = isMultiStep
        self.subtasks = subtasks
        self.isComplete = false
    }
}
