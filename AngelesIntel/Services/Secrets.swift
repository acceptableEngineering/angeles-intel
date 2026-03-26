import Foundation

enum Secrets {
    private static let values: [String: String] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else {
            print("⚠️ Secrets.plist not found — tokens will be empty")
            return [:]
        }
        return dict
    }()

    static let telemetryDeckAppID = values["TELEMETRY_DECK_APP_ID"] ?? ""
    static let rawsAPIToken = values["RAWS_API_TOKEN"] ?? ""
}
