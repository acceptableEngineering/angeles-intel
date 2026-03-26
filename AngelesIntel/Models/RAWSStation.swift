import Foundation

struct SynopticResponse: Codable {
    let STATION: [RAWSStation]?
    let SUMMARY: SynopticSummary?
}

struct SynopticSummary: Codable {
    let RESPONSE_CODE: Int?
    let RESPONSE_MESSAGE: String?
    let NUMBER_OF_OBJECTS: Int?
}

struct RAWSStation: Identifiable, Codable {
    let STID: String
    let NAME: String?
    let LATITUDE: String?
    let LONGITUDE: String?
    let ELEVATION: String?
    let STATE: String?
    let STATUS: String?
    let OBSERVATIONS: RAWSObservations?

    var id: String { STID }

    var displayName: String {
        NAME?.replacingOccurrences(of: "_", with: " ").capitalized ?? STID
    }

    var airTemp: Double? {
        OBSERVATIONS?.air_temp_value_1?.last?.value
    }

    var relativeHumidity: Double? {
        OBSERVATIONS?.relative_humidity_value_1?.last?.value
    }

    var windSpeed: Double? {
        OBSERVATIONS?.wind_speed_value_1?.last?.value
    }

    var windDirection: Double? {
        OBSERVATIONS?.wind_direction_value_1?.last?.value
    }

    var windGust: Double? {
        OBSERVATIONS?.wind_gust_value_1?.last?.value
    }

    var fuelMoisture: Double? {
        OBSERVATIONS?.fuel_moisture_value_1?.last?.value
    }

    var observationDate: Date? {
        guard let dateStr = OBSERVATIONS?.date_time?.last else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateStr)
    }

    var windCardinal: String {
        guard let deg = windDirection else { return "--" }
        let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let idx = Int(round(deg / 22.5)) % 16
        return dirs[idx]
    }
}

struct RAWSObservations: Codable {
    let date_time: [String]?
    let air_temp_value_1: [RAWSValue]?
    let relative_humidity_value_1: [RAWSValue]?
    let wind_speed_value_1: [RAWSValue]?
    let wind_direction_value_1: [RAWSValue]?
    let wind_gust_value_1: [RAWSValue]?
    let fuel_moisture_value_1: [RAWSValue]?
}

struct RAWSValue: Codable {
    let value: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Double.self) {
            value = v
        } else {
            value = nil
        }
    }
}
