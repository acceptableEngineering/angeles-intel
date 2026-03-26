import SwiftUI
import TelemetryDeck

enum AppSection: Hashable {
    case incidents
    case raws
    case notifications
    case resources
}

struct ContentView: View {
    @EnvironmentObject var audioPlayer: AudioPlayerViewModel
    @StateObject private var siteSettings = SiteSettingsService()
    @State private var showingSettings = false
    @State private var showingMenu = false
    @State private var showingAlert = false
    @State private var selectedSection: AppSection = .incidents
    @State private var menuItems: [MenuItem] = MenuView.loadOrder()

    var body: some View {
        NavigationStack {
            Group {
                switch selectedSection {
                case .incidents:
                    IncidentListView()
                case .raws:
                    RAWSPlaceholderView()
                case .notifications:
                    NotificationsPlaceholderView()
                case .resources:
                    ResourcesView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            showingMenu = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                        }

                        Image("AppIconInline")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingMenu) {
                MenuView(selectedSection: $selectedSection, menuItems: $menuItems)
                    .presentationDetents([.medium])
            }
            .onChange(of: selectedSection) {
                TelemetryDeck.signal("Navigation.sectionChanged", parameters: ["section": "\(selectedSection)"])
            }
        }
        .safeAreaInset(edge: .bottom) {
            AudioPlayerBar()
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "autoplayAudio") {
                audioPlayer.play(.forestNet)
                if UserDefaults.standard.bool(forKey: "agencyVerified") {
                    audioPlayer.play(.adminNet)
                }
            }
            siteSettings.startPolling()
        }
        .onChange(of: siteSettings.appAlert) {
            if siteSettings.appAlert != nil {
                showingAlert = true
            }
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK") { showingAlert = false }
        } message: {
            Text(siteSettings.appAlert ?? "")
        }
    }
}
