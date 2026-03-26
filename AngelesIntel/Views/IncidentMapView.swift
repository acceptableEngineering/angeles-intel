import SwiftUI
import MapKit

// MARK: - Compact preview for the incidents list

struct IncidentMapPreview: View {
    let incidents: [Incident]
    var onTap: () -> Void

    var body: some View {
        Map(initialPosition: .automatic, interactionModes: []) {
            ForEach(incidents) { incident in
                if let coord = incident.coordinate {
                    Marker(incident.displayName, systemImage: incident.incidentIcon, coordinate: coord)
                        .tint(incidentColor(for: incident.incidentColor))
                }
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomTrailing) {
            Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
        }
        .onTapGesture(perform: onTap)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    }
}

// MARK: - Full-screen interactive map

struct IncidentMapView: View {
    let incidents: [Incident]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTag: String?
    @State private var navigateToIncident: Incident?

    var body: some View {
        NavigationStack {
            Map(initialPosition: .automatic, selection: $selectedTag) {
                ForEach(incidents) { incident in
                    if let coord = incident.coordinate {
                        Marker(incident.displayName, systemImage: incident.incidentIcon, coordinate: coord)
                            .tint(incidentColor(for: incident.incidentColor))
                            .tag(incident.uuid)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("All Incidents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: selectedTag) { _, newValue in
                if let newValue, let incident = incidents.first(where: { $0.uuid == newValue }) {
                    navigateToIncident = incident
                    selectedTag = nil
                }
            }
            .navigationDestination(item: $navigateToIncident) { incident in
                IncidentDetailView(incident: incident)
            }
        }
    }
}

// MARK: - Shared helpers

private func incidentColor(for name: String) -> Color {
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

extension Incident {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude.flatMap(Double.init),
              let lon = longitude.flatMap(Double.init),
              lat != 0, lon != 0 else { return nil }
        let adjustedLon = lon > 0 ? -lon : lon
        return CLLocationCoordinate2D(latitude: lat, longitude: adjustedLon)
    }
}
