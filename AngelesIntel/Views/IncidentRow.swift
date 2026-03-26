import SwiftUI

struct IncidentRow: View {
    let incident: Incident

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: incident.incidentIcon)
                .font(.title2)
                .foregroundStyle(color(for: incident.incidentColor))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(incident.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let type = incident.type {
                        Text(type)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color(for: incident.incidentColor).opacity(0.15))
                            .foregroundStyle(color(for: incident.incidentColor))
                            .clipShape(Capsule())
                    }

                    if let incNum = incident.incNum {
                        Text("#\(incNum)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                }

                if let date = incident.parsedDate {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    + Text(" ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let acres = incident.acres, !acres.isEmpty {
                    VStack(alignment: .trailing) {
                        Text(acres)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("acres")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if incident.hasValidCoordinates {
                    Image(systemName: "location.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func color(for name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "teal": return .teal
        default: return .gray
        }
    }
}
