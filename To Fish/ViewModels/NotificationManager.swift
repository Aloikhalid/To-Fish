import UserNotifications

struct NotificationManager {

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(for task: TaskModel, dueDate: Date) {
        let center = UNUserNotificationCenter.current()

        let slots: [(id: String, fireDate: Date, body: String)] = [
            (
                "\(task.id.uuidString)-12h",
                dueDate.addingTimeInterval(-12 * 3600),
                "Don't forget \(task.fishName)'s task, 12 hours left"
            ),
            (
                "\(task.id.uuidString)-1h",
                dueDate.addingTimeInterval(-3600),
                "Help \(task.fishName) out, one hour left"
            )
        ]

        for slot in slots {
            guard slot.fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "ToFish"
            content.body = slot.body
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: slot.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            // BUG-21: pass completion handler to surface scheduling errors
            center.add(UNNotificationRequest(identifier: slot.id, content: content, trigger: trigger)) { error in
                if let error { print("Notification scheduling error (\(slot.id)): \(error)") }
            }
        }
    }

    static func cancel(for taskID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "\(taskID.uuidString)-12h",
                "\(taskID.uuidString)-1h"
            ]
        )
    }
}
