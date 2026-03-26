import Foundation

struct IncidentResponse: Codable {
    let data: [Incident]
    let retrieved: String?
    let webComment: String?
}
