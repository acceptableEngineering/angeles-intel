import Foundation
import TelemetryDeck

@MainActor
class RAWSViewModel: ObservableObject {
    @Published var stations: [RAWSStation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = RAWSService()
    private var hasFetched = false

    func fetchIfNeeded() async {
        guard !hasFetched else { return }
        await fetch()
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil

        do {
            stations = try await service.fetchLatest()
            hasFetched = true
            TelemetryDeck.signal("RAWS.loaded", parameters: ["stationCount": "\(stations.count)"])
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
