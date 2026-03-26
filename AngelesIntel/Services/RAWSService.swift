import Foundation

class RAWSService {
    private let token = Secrets.rawsAPIToken
    private let baseURL = "https://api.synopticdata.com/v2/stations/latest"

    // ANF-area RAWS stations — update this list as stations come online/offline
    static let anfStations = [
        "SAUC1",   // Saugus
        "CHLC1",   // Chilao
        "CLKC1",   // Clear Creek
        "BLRC1",   // Blue Ridge
        "PCFC1",   // Pacifico
        "DLSC1",   // Del Sur
        "BRFC1",   // Barley Flats
        "MWSC1",   // Mt Wilson
    ]

    func fetchLatest() async throws -> [RAWSStation] {
        let stids = Self.anfStations.joined(separator: ",")
        let vars = "air_temp,relative_humidity,wind_speed,wind_direction,wind_gust,fuel_moisture"

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "stid", value: stids),
            URLQueryItem(name: "vars", value: vars),
            URLQueryItem(name: "units", value: "english"),
            URLQueryItem(name: "within", value: "120"),
            URLQueryItem(name: "output", value: "json"),
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(SynopticResponse.self, from: data)
        return result.STATION ?? []
    }
}
