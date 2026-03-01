import SwiftUI
 
struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var titleScale = 0.8
    @State private var waveOffset: CGFloat = 0
    @State private var starsOffset: CGFloat = 0
    @State private var sunlightOpacity: Double = 0.6
 
    var viewModel: TaskViewModel
 
    var body: some View {
        if isActive {
            ContentView(viewModel: viewModel)
        } else {
            GeometryReader { geo in
                ZStack {
                    // MARK: - Layer 1: Background
                    Image("bg_aquarium")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
 
                    // MARK: - Layer 2: Sunlight
                    Image("layer_sunlight")
                        .resizable()
                        .scaledToFill()
                        .opacity(sunlightOpacity)
                        .blendMode(.screen)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
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
 
                    // MARK: - Seahorse + Title
                    VStack(spacing: 1) {
                       
                        Spacer()
 
                        Image("seahorse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.70)
 

                       
                        ZStack {
                            Text("To Fish")
                                .font(.custom("Kavoon-Regular", size: geo.size.width * 0.13))
                                .foregroundStyle(.white)
                                .shadow(color: .white.opacity(0.6), radius: 8)
 
                            Image("sprinkle_all")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width * 0.65)
                                .allowsHitTesting(false)
                        }
 
                      
                        Spacer().frame(height: geo.size.height * 0.20)                    }
                   
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(titleScale)
                    .opacity(opacity)
                    .onAppear {
                        startBackgroundMusic()
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                            opacity = 1.0
                            titleScale = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isActive = true
                            }
                        }
                    }
 
                    // MARK: - Layer 5: Seaweed 1
                    Image("layer_seaweed1")
                        .resizable()
                        .scaledToFill()
                        .offset(x: waveOffset)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                                waveOffset = 6
                            }
                        }
 
                    // MARK: - Layer 6: Seaweed 2
                    Image("layer_seaweed2")
                        .resizable()
                        .scaledToFill()
                        .offset(x: -waveOffset * 1.3)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                // KEY: explicit frame forces the ZStack to fill the GeometryReader,
                // so its children are centered on the physical screen — not the
                // safe-area content region.
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
    }
}
