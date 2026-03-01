import SwiftUI

struct AchievementsView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTask: TaskModel? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("bg_aquarium")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(1.2)
                     
                Color.black.opacity(0.2)
                    .scaleEffect(1.2)

                VStack(spacing: 16) {

                    // MARK: - Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Image("shell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.25)

                    Text("Achievements")
                        .font(.custom("Kavoon-Regular", size: 32))
                        .foregroundColor(.white)

                    if viewModel.achievements.isEmpty {
                        Spacer()
                        Text("No achievements yet!\nRelease a fish to see it here")
                            .font(.custom("Kavoon-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.achievements) { task in
                                    AchievementCard(task: task, viewModel: viewModel,
                                                    cardWidth: geo.size.width - 32,
                                                    isExpanded: selectedTask?.id == task.id)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedTask = selectedTask?.id == task.id ? nil : task
                                            }
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation { viewModel.deleteAchievement(task) }
                                            } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let task: TaskModel
    let viewModel: TaskViewModel
    let cardWidth: CGFloat
    let isExpanded: Bool

    var fishImage: String {
        if task.isMultiStep { return "seahorse" }
        let images = ["fish_pink", "fish_blue", "fish_yellow"]
        let uuidInt = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return images[uuidInt % images.count]
    }

    var fishSize: CGFloat { cardWidth * 0.18 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Always visible row
            HStack(spacing: 16) {
                Image(fishImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fishSize, height: fishSize)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(task.fishName)
                            .font(.custom("Kavoon-Regular", size: 22))
                            .foregroundColor(.white)
                    }
                    Text(formattedDate(task.completedDate ?? task.dateAdded))
                        .font(.custom("Kavoon-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            // MARK: - Expanded details
            if isExpanded {
                Text(task.taskDescription)
                    .font(.custom("Kavoon-Regular", size: 15))
                    .foregroundColor(.white)

                if task.isMultiStep {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(task.subtasks) { subtask in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                                Text(subtask.title)
                                    .font(.custom("Kavoon-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }
                }

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Completed \(formattedDate(task.completedDate ?? task.dateAdded))")
                        .font(.custom("Kavoon-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.teal.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
