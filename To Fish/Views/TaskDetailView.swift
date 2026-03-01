import SwiftUI

struct TaskDetailView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: TaskModel?
    @State private var showDeleteConfirm = false
    @State private var showReleaseConfirm = false

    var liveSubtasks: [Subtask] {
        viewModel.activeTasks.first(where: { $0.id == task.id })?.subtasks ?? task.subtasks
    }

    var fishImage: String {
        if task.isMultiStep {
            return viewModel.hoursRemaining(for: task) == 0 ? "seahorse_sad" : "seahorse"
        }
        let images = ["fish_pink", "fish_blue", "fish_yellow"]
        let uuidInt = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let baseFish = images[uuidInt % images.count]
        return viewModel.hoursRemaining(for: task) == 0 ? "fish_sad" : baseFish
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("bg_aquarium")
                    .resizable()
                    .scaledToFill()
                    .clipped()

                Color.black.opacity(0.2)

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Fish + Name Row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.fishName)
                                .font(.custom("Kavoon-Regular", size: geo.size.width * 0.09))
                                .foregroundColor(.white)

                            Text(formattedDate(task.dateAdded))
                                .font(.custom("Kavoon-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.5))

                            Text(task.taskDescription)
                                .font(.custom("Kavoon-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(fishImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.width * 0.28)
                    }

                    // MARK: - Days Remaining
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)

                        if viewModel.hoursRemaining(for: task) == 0 {
                            Text("Time's up!")
                                .font(.custom("Kavoon-Regular", size: 22))
                                .foregroundColor(.red.opacity(0.8))
                        } else if viewModel.isLastDay(for: task) {
                            Text("\(viewModel.hoursRemaining(for: task)) hours left")
                                .font(.custom("Kavoon-Regular", size: 22))
                                .foregroundColor(.orange)
                        } else {
                            Text("\(viewModel.daysRemaining(for: task)) days left")
                                .font(.custom("Kavoon-Regular", size: 22))
                                .foregroundColor(.white)
                        }
                    }

                    // MARK: - Subtasks
                    if task.isMultiStep {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(liveSubtasks) { subtask in
                                HStack {
                                    Button(action: {
                                        if !subtask.isComplete { playBubblesSound() }
                                        viewModel.toggleSubtask(taskID: task.id, subtaskID: subtask.id)
                                    }) {
                                        Image(systemName: subtask.isComplete ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(subtask.isComplete ? .orange : .white.opacity(0.6))
                                            .font(.title3)
                                    }
                                    Text(subtask.title)
                                        .font(.custom("Kavoon-Regular", size: 15))
                                        .foregroundColor(.white)
                                        .strikethrough(subtask.isComplete)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Spacer()

                    // MARK: - Action Buttons
                    HStack(spacing: 16) {
                        Button(action: { showDeleteConfirm = true }) {
                            Text("\(task.fishName)\ncan't do it")
                                .font(.custom("Kavoon-Regular", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Capsule().fill(Color.white.opacity(0.2)))
                        }

                        Button(action: { showReleaseConfirm = true }) {
                            Text("Release into Ocean!")
                                .font(.custom("Kavoon-Regular", size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Capsule().fill(Color.cyan.opacity(0.6)))
                        }
                        .disabled(!viewModel.allSubtasksComplete(for: task))
                        .opacity(!viewModel.allSubtasksComplete(for: task) ? 0.5 : 1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()

                // MARK: - Delete Confirmation Overlay
                if showDeleteConfirm {
                    Color.black.opacity(0.5).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image(fishImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.width * 0.2)

                        Text("Are you sure you want to delete \(task.fishName)'s task?")
                            .font(.custom("Kavoon-Regular", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button(action: { showDeleteConfirm = false }) {
                                Text("Cancel")
                                    .font(.custom("Kavoon-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(Color.gray.opacity(0.9)))
                            }

                            Button(action: {
                                viewModel.deleteTask(task)
                                withAnimation(.spring(response: 0.35)) { selectedTask = nil }
                            }) {
                                Text("Delete")
                                    .font(.custom("Kavoon-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(Color.red.opacity(0.9)))
                            }
                        }
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.teal.opacity(0.9)))
                    .padding(40)
                }

                // MARK: - Release Confirmation Overlay
                if showReleaseConfirm {
                    Color.black.opacity(0.5).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image(fishImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.width * 0.2)

                        Text("Are you done with \(task.fishName)'s task?")
                            .font(.custom("Kavoon-Regular", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button(action: { showReleaseConfirm = false }) {
                                Text("Cancel")
                                    .font(.custom("Kavoon-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(Color.gray.opacity(0.9)))
                            }

                            Button(action: {
                                playBubblesSound()
                                viewModel.releaseTask(task)
                                withAnimation(.spring(response: 0.35)) { selectedTask = nil }
                            }) {
                                Text("Yes!")
                                    .font(.custom("Kavoon-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(Color.cyan.opacity(0.7)))
                            }
                        }
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.teal.opacity(0.6)))
                    .padding(40)
                }
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    let vm = TaskViewModel()
    let task = TaskModel(
        fishName: "Nemo",
        taskDescription: "Finish the project",
        duration: .threeDays,
        isMultiStep: false,
        subtasks: []
    )
    return TaskDetailView(task: task, viewModel: vm, selectedTask: .constant(task))
}
