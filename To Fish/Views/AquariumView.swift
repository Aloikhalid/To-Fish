import SwiftUI

struct AquariumView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var waveOffset: CGFloat = 0
    @State private var starsOffset: CGFloat = 0
    @State private var sunlightOpacity: Double = 0.6
    @State private var selectedTask: TaskModel?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - Layer 1: Background
                Image("bg_aquarium")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // MARK: - Layer 2: Sunlight
                Image("layer_sunlight")
                    .resizable()
                    .scaledToFill()
                    .opacity(sunlightOpacity)
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                            sunlightOpacity = 1.0
                        }
                    }

                // MARK: - Layer 3: Stars
                Image("layer_stars")
                    .resizable()
                    .scaledToFill()
                    .offset(x: starsOffset)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                            starsOffset = 8
                        }
                    }

                // MARK: - Layer 4: Seaweed 1
                // BUG-17: waveOffset animation driven by ZStack.onAppear (below) so both
                // seaweed layers share one driver and layer 5 doesn't depend on layer 4
                Image("layer_seaweed1")
                    .resizable()
                    .scaledToFill()
                    .offset(x: waveOffset)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // MARK: - Layer 5: Seaweed 2
                Image("layer_seaweed2")
                    .resizable()
                    .scaledToFill()
                    .offset(x: -waveOffset * 1.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // MARK: - Layer 6: Fish & Seahorses (above seaweed so they're always visible)
                ForEach(viewModel.activeTasks) { task in
                    FishView(task: task, viewModel: viewModel, selectedTask: $selectedTask,
                             screenWidth: geo.size.width, screenHeight: geo.size.height)

                    if task.isMultiStep {
                        ForEach(task.subtasks.filter { $0.isComplete }) { subtask in
                            BabySeahorseView(parentTask: task, subtask: subtask,
                                             screenWidth: geo.size.width, screenHeight: geo.size.height)
                        }
                    }
                }

                // MARK: - Task Detail Card Overlay
                if let task = selectedTask {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTask = nil } }

                    TaskDetailView(task: task, viewModel: viewModel, selectedTask: $selectedTask)
                        .frame(width: geo.size.width * 0.88, height: geo.size.height * 0.56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(red: 0.04, green: 0.22, blue: 0.32).opacity(0.97))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.45), radius: 28)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // BUG-17: single shared animation driver for waveOffset
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    waveOffset = 6
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Individual Fish View
struct FishView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: TaskModel?
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var floatOffset: CGFloat = 0
    @State private var appeared = false
    @State private var movingRight = Bool.random()
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    // BUG-03: guard flag to break dangling asyncAfter chains on disappear
    @State private var isSwimming = false

    var swimDistance: CGFloat { screenWidth * 0.45 }
    var verticalRange: CGFloat { screenHeight * 0.35 }

    var fishImage: String {
        if task.isMultiStep {
            return viewModel.hoursRemaining(for: task) == 0 ? "seahorse_sad" : "seahorse"
        }
        let images = ["fish_pink", "fish_blue", "fish_yellow"]
        let uuidInt = task.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let baseFish = images[uuidInt % images.count]
        return viewModel.hoursRemaining(for: task) == 0 ? "fish_sad" : baseFish
    }

    var fishSize: CGFloat { task.isMultiStep ? screenWidth * 0.25 : screenWidth * 0.38 }

    var flipX: CGFloat {
        task.isMultiStep ? (movingRight ? -1 : 1) : (movingRight ? 1 : -1)
    }

    // BUG-03: guard on isSwimming so the asyncAfter chain stops after .onDisappear
    func swim() {
        guard isSwimming else { return }
        let duration = Double.random(in: 10...14)
        let goRight = !movingRight
        movingRight = goRight

        let angleDrift = Bool.random() ? CGFloat.random(in: -40...40) : 0
        let newY = max(-verticalRange, min(verticalRange, yOffset + angleDrift))

        withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: duration)) {
            xOffset = goRight ? swimDistance : -swimDistance
            yOffset = newY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { swim() }
    }

    var body: some View {
        Image(fishImage)
            .resizable()
            .scaledToFit()
            .frame(width: fishSize)
            .scaleEffect(x: flipX, y: 1)
            .scaleEffect(appeared ? 1 : 0)
            .offset(x: xOffset, y: yOffset + floatOffset)
            .onAppear {
                yOffset = CGFloat.random(in: -verticalRange...verticalRange)
                xOffset = movingRight ? -swimDistance : swimDistance

                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: Double.random(in: 3...5))
                    .repeatForever(autoreverses: true)) {
                    floatOffset = CGFloat.random(in: -15...15)
                }
                isSwimming = true
                swim()
            }
            // BUG-03: stop the chain when the view leaves the hierarchy
            .onDisappear { isSwimming = false }
            .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTask = task } }
    }
}

// MARK: - Baby Seahorse View
struct BabySeahorseView: View {
    let parentTask: TaskModel
    let subtask: Subtask
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var appeared = false
    @State private var floatOffset: CGFloat = 0
    @State private var movingRight = Bool.random()
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    // BUG-03: guard flag to break dangling asyncAfter chains on disappear
    @State private var isSwimming = false

    var swimDistance: CGFloat { screenWidth * 0.3 }
    var verticalRange: CGFloat { screenHeight * 0.25 }

    // BUG-03: guard on isSwimming so the asyncAfter chain stops after .onDisappear
    func swim() {
        guard isSwimming else { return }
        let duration = Double.random(in: 8...12)
        let goRight = !movingRight
        movingRight = goRight

        let angleDrift = Bool.random() ? CGFloat.random(in: -20...20) : 0
        let newY = max(-verticalRange, min(verticalRange, yOffset + angleDrift))

        withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: duration)) {
            xOffset = goRight ? swimDistance : -swimDistance
            yOffset = newY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { swim() }
    }

    var body: some View {
        Image("seahorse_baby")
            .resizable()
            .scaledToFit()
            .frame(width: screenWidth * 0.075)
            .scaleEffect(x: movingRight ? 1 : -1, y: 1)
            .scaleEffect(appeared ? 1 : 0)
            .offset(x: xOffset, y: yOffset + floatOffset)
            .onAppear {
                yOffset = CGFloat.random(in: -verticalRange...verticalRange)
                xOffset = movingRight ? -swimDistance : swimDistance

                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: Double.random(in: 2...3))
                    .repeatForever(autoreverses: true)) {
                    floatOffset = CGFloat.random(in: -8...8)
                }
                isSwimming = true
                swim()
            }
            // BUG-03: stop the chain when the view leaves the hierarchy
            .onDisappear { isSwimming = false }
    }
}
