import Foundation

struct SiteSettings: Codable {
    let appAlert: String?

    enum CodingKeys: String, CodingKey {
        case appAlert = "app_alert"
    }
}

@MainActor
class SiteSettingsService: ObservableObject {
    @Published var appAlert: String?

    private let url = URL(string: "https://landmark717.com/data/site-settings.json")!
    private var pollTask: Task<Void, Never>?
    private var shownAlerts: Set<String> = []

    func startPolling() {
        Task { await fetch() }

        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1800))
                if Task.isCancelled { break }
                await fetch()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func fetch() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let settings = try JSONDecoder().decode(SiteSettings.self, from: data)
            if let alert = settings.appAlert, !alert.isEmpty, !shownAlerts.contains(alert) {
                shownAlerts.insert(alert)
                self.appAlert = alert
            }
        } catch {
            // Silently ignore — this is a best-effort check
        }
    }
}
