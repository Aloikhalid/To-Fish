import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var fishName = ""
    @State private var taskDescription = ""
    @State private var selectedDuration: TaskDuration = .oneDay
    @State private var isMultiStep = false
    @State private var subtaskTitles = ["", "", ""]
    @Environment(\.dismiss) var dismiss

    // BUG-12: single static formatter instead of per-call allocation
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("bg_aquarium")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(1.05)
                    .ignoresSafeArea()

                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 16)

                        // MARK: - Fish Name
                        VStack(alignment: .leading, spacing: 15) {
                            TextField("", text: $fishName,
                                      prompt: Text("The fish's name")
                                          .foregroundColor(.white.opacity(0.55))
                                          .font(.custom("Kavoon-Regular", size: geo.size.width * 0.08)))
                                .font(.custom("Kavoon-Regular", size: geo.size.width * 0.08))
                                .foregroundColor(.white)

                            Text(formattedDate())
                                .font(.custom("Kavoon-Regular", size: 14))
                                .foregroundColor(.white)

                            TextField("", text: $taskDescription, prompt: Text("What's the task for your fish?")
                                          .foregroundColor(.white.opacity(0.55))
                                          .font(.custom("Kavoon-Regular", size: 20)),
                                      axis: .vertical)
                                .font(.custom("Kavoon-Regular", size: 20))
                                .foregroundColor(.white)
                                .lineLimit(nil)

                            Divider().background(Color.white.opacity(0.3))
                        }

                        // MARK: - Duration
                        VStack(alignment: .center, spacing: 15) {
                            Text("how long will this take?")
                                .font(.custom("Kavoon-Regular", size: 20))
                                .foregroundColor(.white)

                            HStack(spacing: 24) {
                                ForEach(TaskDuration.allCases, id: \.self) { duration in
                                    VStack(spacing: 6) {
                                        Text(duration.rawValue)
                                            .font(.custom("Kavoon-Regular", size: 13))
                                            .foregroundColor(.cyan)

                                        Button(action: { selectedDuration = duration }) {
                                            ZStack {
                                                Image("bubble_button")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: geo.size.width * 0.14)
                                                    .opacity(selectedDuration == duration ? 1 : 0.4)

                                                if selectedDuration == duration {
                                                    Image("choice_star")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: geo.size.width * 0.075)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Divider().background(Color.white.opacity(0.3))

                        // MARK: - Task Type
                        VStack(alignment: .center, spacing: 12) {
                            HStack(spacing: 40) {
                                // BUG-19: animation on the toggle call site, not on the VStack
                                taskTypeButton(
                                    label: "Single task",
                                    isSelected: !isMultiStep,
                                    starSize: geo.size.width * 0.075,
                                    bubbleSize: geo.size.width * 0.14,
                                    action: { withAnimation(.easeInOut) { isMultiStep = false } }
                                )

                                taskTypeButton(
                                    label: "Multi-step task",
                                    isSelected: isMultiStep,
                                    starSize: geo.size.width * 0.075,
                                    bubbleSize: geo.size.width * 0.14,
                                    action: { withAnimation(.easeInOut) { isMultiStep = true } }
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            // MARK: - Subtasks
                            if isMultiStep {
                                VStack(spacing: 10) {
                                    ForEach(0..<3, id: \.self) { index in
                                        HStack {
                                            Image("bubble_button")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: geo.size.width * 0.075)
                                                .opacity(subtaskTitles[index].isEmpty ? 0.3 : 1.0)

                                            TextField("", text: $subtaskTitles[index],
                                                      prompt: Text("Task \(index + 1)")
                                                          .foregroundColor(.white.opacity(0.55))
                                                          .font(.custom("Kavoon-Regular", size: 15)))
                                                .font(.custom("Kavoon-Regular", size: 15))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                // BUG-19: .animation(…value:) removed; transition fires via withAnimation at call site
                                .transition(.opacity)
                            }
                        }

                        // MARK: - Save Button
                        Button(action: saveTask) {
                            Text("Release into Aquarium")
                                .font(.custom("Kavoon-Regular", size: 18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Capsule().fill(Color.cyan.opacity(0.5)))
                        }
                        .disabled(fishName.isEmpty || (isMultiStep && subtaskTitles.allSatisfy { $0.isEmpty }))
                        .opacity((fishName.isEmpty || (isMultiStep && subtaskTitles.allSatisfy { $0.isEmpty })) ? 0.5 : 1)
                    }
                    .padding()
                }
                .padding(.bottom)
                .background(Color.clear)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func taskTypeButton(label: String, isSelected: Bool, starSize: CGFloat, bubbleSize: CGFloat, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.custom("Kavoon-Regular", size: 13))
                .foregroundColor(.cyan)

            Button(action: action) {
                ZStack {
                    Image("bubble_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: bubbleSize)
                        .opacity(isSelected ? 1 : 0.4)

                    if isSelected {
                        Image("choice_star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: starSize)
                    }
                }
            }
        }
    }

    func saveTask() {
        let subtasks: [Subtask] = isMultiStep
            ? subtaskTitles
                .filter { !$0.isEmpty }
                .map { title in Subtask(title: title) }
            : [Subtask]()

        // BUG-08: block release if multi-step but no subtasks entered
        if isMultiStep && subtasks.isEmpty { return }

        let newTask = TaskModel(
            fishName: fishName,
            taskDescription: taskDescription,
            duration: selectedDuration,
            isMultiStep: isMultiStep,
            subtasks: subtasks
        )
        // BUG-06: derive dueDate from newTask.dateAdded, not a second Date() call
        let dueDate = newTask.dateAdded.addingTimeInterval(selectedDuration.timeInterval)
        playBubblesSound()
        viewModel.addTask(newTask)
        NotificationManager.schedule(for: newTask, dueDate: dueDate)
        dismiss()
    }

    func formattedDate() -> String {
        AddTaskView.dateFormatter.string(from: Date())
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel())
}
