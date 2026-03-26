import Foundation

struct Incident: Identifiable, Codable, Hashable {
    static func == (lhs: Incident, rhs: Incident) -> Bool { lhs.uuid == rhs.uuid }
    func hash(into hasher: inout Hasher) { hasher.combine(uuid) }

    let uuid: String
    let name: String?
    let type: String?
    let date: String?
    let incNum: String?
    let fireNum: String?
    let ic: String?
    let acres: String?
    let fuels: String?
    let latitude: String?
    let longitude: String?
    let location: String?
    let resources: [String?]?
    let webComment: String?
    let fireStatus: String?
    let fiscalData: String?

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, name, type, date, ic, acres, fuels, latitude, longitude, location, resources, webComment
        case incNum = "inc_num"
        case fireNum = "fire_num"
        case fireStatus = "fire_status"
        case fiscalData = "fiscal_data"
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let fallbackFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let jsonDecoder = JSONDecoder()

    var parsedDate: Date? {
        if let d = Self.isoFormatter.date(from: date ?? "") { return d }
        return Self.fallbackFormatter.date(from: date ?? "")
    }

    var parsedFireStatus: FireStatus? {
        guard let data = fireStatus?.data(using: .utf8) else { return nil }
        return try? Self.jsonDecoder.decode(FireStatus.self, from: data)
    }

    var isMasked: Bool {
        name?.allSatisfy({ $0 == "*" }) ?? false
    }

    var displayName: String {
        name ?? "Incident #\(incNum ?? "Unknown")"
    }

    var incidentIcon: String {
        let n = displayName.uppercased()

        // Name-based icons take priority
        if n == "DAILY STATUS" { return "clock.fill" }
        if n.contains("SAR") || n.contains("SEARCH AND RESCUE") || n.contains("SEARCH & RESCUE") { return "binoculars.fill" }
        if n.contains("MEDICAL") || n.contains("MED AID") { return "cross.fill" }
        if n.contains("TRAFFIC") || n.contains("T/C") || n.contains("VEH") { return "car.fill" }
        if n.contains("FLIGHT FOLLOWING") { return "airplane" }
        if n.contains("PREPOSITION") || n.contains("PREPO") || n.contains("STAFFING") || n.contains("DUTY") || n.contains("SEVERITY") { return "person.2.fill" }
        if n.contains("RX") { return "flame" }
        if n.contains("PROPERTY DAMAGE") { return "house.fill" }
        if n.contains("CITATION") || n.contains("WARNING") || n.contains("NON-PAYMENT") || n.contains("NON PAYMENT") { return "doc.text.fill" }
        if n.contains("CAMPFIRE") { return "flame.circle.fill" }
        if n.contains("DOWN TREE") || n.contains("ROCK RUN") { return "tree.fill" }
        if n.contains("ILLEGAL DUMP") { return "trash.fill" }
        if n.contains("FALSE ALARM") { return "bell.slash.fill" }
        if n.contains("GATE") || n.contains("LOCK") { return "lock.fill" }

        // Fall back to type-based icons
        switch type?.lowercased() {
        case "wildfire": return "flame.fill"
        case "prescribed fire": return "flame"
        case "law enforcement": return "shield.fill"
        case "motor vehicle accident": return "car.fill"
        case "medical aid": return "cross.fill"
        case "resource order": return "doc.plaintext.fill"
        case "aircraft": return "airplane"
        case "marine search/rescue/recovery": return "binoculars.fill"
        case "preparedness/preposition": return "person.2.fill"
        case "severe winter weather": return "snowflake"
        case "miscellaneous": return "ellipsis.circle.fill"
        case "hazmat": return "exclamationmark.triangle.fill"
        default: return "mappin.circle.fill"
        }
    }

    var incidentColor: String {
        let n = displayName.uppercased()

        // Name-based colors
        if n == "DAILY STATUS" { return "gray" }
        if n.contains("SAR") || n.contains("SEARCH AND RESCUE") || n.contains("SEARCH & RESCUE") { return "yellow" }
        if n.contains("MEDICAL") || n.contains("MED AID") { return "pink" }
        if n.contains("TRAFFIC") || n.contains("T/C") || n.contains("VEH") { return "orange" }

        // Fall back to type-based colors
        switch type?.lowercased() {
        case "wildfire": return "red"
        case "prescribed fire": return "orange"
        case "law enforcement": return "blue"
        case "motor vehicle accident": return "orange"
        case "medical aid": return "pink"
        case "resource order": return "cyan"
        case "aircraft": return "purple"
        case "marine search/rescue/recovery": return "yellow"
        case "preparedness/preposition": return "teal"
        case "severe winter weather": return "cyan"
        case "miscellaneous": return "gray"
        case "hazmat": return "purple"
        default: return "gray"
        }
    }

    var typeDescription: String? {
        let n = displayName.uppercased()

        // Name-based descriptions take priority
        if n == "DAILY STATUS" {
            return "A routine daily status report filed by ANF dispatch summarizing current forest conditions, staffing levels, and any ongoing incidents."
        }
        if n.contains("SAR") || n.contains("SEARCH AND RESCUE") || n.contains("SEARCH & RESCUE") {
            return "A search and rescue operation, typically involving a missing, injured, or stranded person in the forest. These operations may involve ground teams, helicopters, and K-9 units."
        }

        // Fall back to type-based descriptions
        switch type?.lowercased() {
        case "wildfire":
            return "This incident has been marked as a wildfire by ANF dispatch. Most of these are small fires that never make the news, some are false reports, and others may grow into large news-worthy incidents."
        case "prescribed fire":
            return "A planned, controlled burn conducted by forest personnel to reduce hazardous fuels, restore ecosystem health, or manage vegetation. These are intentional and carefully monitored."
        case "law enforcement":
            return "A law enforcement incident handled by Forest Service LEOs (Law Enforcement Officers). These can range from traffic stops and citations to more serious criminal investigations within the forest."
        case "motor vehicle accident":
            return "A vehicle collision on or near a forest road. ANF roads can be narrow, winding, and steep — these incidents may require specialized extrication or medevac resources."
        case "medical aid":
            return "A medical emergency involving a visitor or forest worker. Response times in the backcountry can be significantly longer than in urban areas due to remote terrain and limited access."
        case "resource order":
            return "Forests and Regions within the U.S. Forest Service share resources when needed. A resource order means ANF is either requesting or providing crews, engines, aircraft, or other assets to assist with incidents elsewhere."
        case "aircraft":
            return "An aircraft-related incident, which may involve helicopters or fixed-wing planes used for firefighting, search and rescue, or reconnaissance over the forest."
        case "marine search/rescue/recovery":
            return "A water-related search, rescue, or recovery operation. While uncommon in the ANF, these can occur at reservoirs, rivers, or other water features within the forest."
        case "preparedness/preposition":
            return "Resources are being pre-positioned or staffing is being increased in anticipation of elevated fire danger, severe weather, or a major event. This is a proactive measure, not a response to an active incident."
        case "severe winter weather":
            return "A weather-related incident involving snow, ice, high winds, or other winter conditions affecting the forest. This may include road closures, stranded visitors, or infrastructure damage at higher elevations."
        case "miscellaneous":
            return "A general incident that doesn't fit neatly into other categories. These can include downed trees, property damage, illegal dumping, gate issues, or other non-emergency situations within the forest."
        case "hazmat":
            return "A hazardous materials incident involving chemical spills, illegal substance labs, or other toxic materials found within the forest. These require specialized response teams."
        default:
            return nil
        }
    }

    var hasValidCoordinates: Bool {
        guard let lat = latitude.flatMap(Double.init),
              let lon = longitude.flatMap(Double.init) else { return false }
        return lat != 0 && lon != 0
    }
}

struct FireStatus: Codable {
    let out: String?
    let contain: String?
    let control: String?
}
