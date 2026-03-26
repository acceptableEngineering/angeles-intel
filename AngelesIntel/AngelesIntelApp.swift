import SwiftUI
import TelemetryDeck

@main
struct AngelesIntelApp: App {
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    @State private var showingSplash = true

    init() {
        let config = TelemetryDeck.Config(appID: Secrets.telemetryDeckAppID)
        TelemetryDeck.initialize(config: config)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(audioPlayer)

                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeOut(duration: 0.4)) {
                    showingSplash = false
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        Image("LaunchImage")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}
