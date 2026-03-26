import Foundation

@MainActor
class IncidentViewModel: ObservableObject {
    @Published var incidents: [Incident] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRetrieved: String?
    @Published var lastFetchedAt: Date?
    @Published var nextRefreshAt: Date?
    @Published var isOffline = false

    private let apiService = APIService()
    private var refreshTimer: Timer?
    private static let refreshInterval: TimeInterval = 60
    private static let cacheURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("incidents_cache.json")
    }()

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        nextRefreshAt = Date().addingTimeInterval(Self.refreshInterval)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchIncidents()
                self.nextRefreshAt = Date().addingTimeInterval(Self.refreshInterval)
            }
        }
    }

    func fetchIncidents() async {
        isLoading = true
        errorMessage = nil

        do {
            let responses = try await apiService.fetchIncidents()
            if let first = responses.first {
                self.incidents = first.data.sorted { a, b in
                    (a.parsedDate ?? .distantPast) > (b.parsedDate ?? .distantPast)
                }
                self.lastRetrieved = first.retrieved
                self.lastFetchedAt = Date()
                self.isOffline = false
                saveCache(first)
            }
        } catch {
            if incidents.isEmpty {
                loadCache()
            }
            self.isOffline = true
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func saveCache(_ response: IncidentResponse) {
        let url = Self.cacheURL
        Task.detached {
            try? JSONEncoder().encode(response).write(to: url, options: .atomic)
        }
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: Self.cacheURL),
              let cached = try? JSONDecoder().decode(IncidentResponse.self, from: data) else { return }
        self.incidents = cached.data.sorted { a, b in
            (a.parsedDate ?? .distantPast) > (b.parsedDate ?? .distantPast)
        }
        self.lastRetrieved = cached.retrieved
    }
}
