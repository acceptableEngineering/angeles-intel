import Foundation

class APIService {
    func fetchIncidents() async throws -> [IncidentResponse] {
        guard let url = URL(string: "https://landmark717.com/centers/CAANCC/incidents") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([IncidentResponse].self, from: data)
    }
}
