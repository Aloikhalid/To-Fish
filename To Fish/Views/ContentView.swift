import SwiftUI
import AVFoundation

struct ContentView: View {
    // BUG-16: @ObservedObject because the view model is owned by ToFishApp / AppRoot
    @ObservedObject var viewModel: TaskViewModel
    @State private var showAddTask = false
    @State private var showAchievements = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            AquariumView(viewModel: viewModel)
                .ignoresSafeArea()

            GeometryReader { geo in
                VStack {
                    // Top right – Achievements bubble
                    HStack {
                        Spacer()
                        Button(action: { showAchievements = true }) {
                            ZStack {
                                Image("bubble_button")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.2)

                                Image("shell")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.1)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, geo.safeAreaInsets.top + 55)

                    Spacer()

                    // Bottom center – Add a fish bubble
                    Button(action: { showAddTask = true }) {
                        ZStack {
                            Image("bubble_button")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.25)

                            Text("Add a\nfish")
                                .font(.custom("Kavoon-Regular", size: geo.size.width * 0.045))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        //.onAppear { startBackgroundMusic() }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementsView(viewModel: viewModel)
        }
    }

    
}
