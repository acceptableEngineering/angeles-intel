import SwiftUI
import MapKit
import TelemetryDeck

struct IncidentDetailView: View {
    let incident: Incident
    @State private var showingMapOptions = false
    @State private var copiedFormat: CoordFormat?
    @State private var showingRAWS = false
    @State private var showingADSB = false

    var coordinate: CLLocationCoordinate2D? {
        incident.coordinate
    }

    private enum CoordFormat: String, CaseIterable {
        case dd, dms, dmm

        var label: String {
            switch self {
            case .dd: return "DD"
            case .dms: return "DMS"
            case .dmm: return "DMM"
            }
        }

        func format(_ coord: CLLocationCoordinate2D) -> String {
            switch self {
            case .dd:
                return String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
            case .dms:
                return "\(Self.toDMS(coord.latitude, isLat: true)), \(Self.toDMS(coord.longitude, isLat: false))"
            case .dmm:
                return "\(Self.toDMM(coord.latitude, isLat: true)), \(Self.toDMM(coord.longitude, isLat: false))"
            }
        }

        private static func toDMS(_ decimal: Double, isLat: Bool) -> String {
            let direction = isLat ? (decimal >= 0 ? "N" : "S") : (decimal >= 0 ? "E" : "W")
            let absolute = abs(decimal)
            let degrees = Int(absolute)
            let minutesDecimal = (absolute - Double(degrees)) * 60
            let minutes = Int(minutesDecimal)
            let seconds = (minutesDecimal - Double(minutes)) * 60
            return String(format: "%d°%02d'%05.2f\"%@", degrees, minutes, seconds, direction)
        }

        private static func toDMM(_ decimal: Double, isLat: Bool) -> String {
            let direction = isLat ? (decimal >= 0 ? "N" : "S") : (decimal >= 0 ? "E" : "W")
            let absolute = abs(decimal)
            let degrees = Int(absolute)
            let minutes = (absolute - Double(degrees)) * 60
            return String(format: "%d°%06.3f'%@", degrees, minutes, direction)
        }
    }

    var body: some View {
        List {
            if let coord = coordinate {
                Section {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )), interactionModes: []) {
                        Marker(incident.displayName, coordinate: coord)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .onTapGesture {
                        showingMapOptions = true
                    }
                }

                Section {
                    Button {
                        showingMapOptions = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text("Open in Maps App")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }

                    if let coord = coordinate {
                        HStack(spacing: 8) {
                            ForEach(CoordFormat.allCases, id: \.self) { format in
                                let formatted = format.format(coord)
                                let isCopied = copiedFormat == format
                                Button {
                                    UIPasteboard.general.string = formatted
                                    withAnimation { copiedFormat = format }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            if copiedFormat == format { copiedFormat = nil }
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                                .font(.caption2)
                                            Text(isCopied ? "Copied!" : "Copy \(format.label)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        Text(formatted)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(isCopied ? Color.green.opacity(0.1) : Color(.tertiarySystemFill))
                                    .foregroundStyle(isCopied ? .green : Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Button {
                        showingRAWS = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cloud.sun.fill")
                                .foregroundStyle(.cyan)
                                .frame(width: 24)
                            Text("Nearby RAWS")
                            Spacer()
                        }
                    }

                    Button {
                        showingADSB = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "airplane")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            Text("ADS-B Exchange")
                            Spacer()
                        }
                    }
                }
            }

            Section("Details") {
                detailRow("Type", value: incident.type)
                detailRow("Incident #", value: incident.incNum)
                detailRow("Fire #", value: incident.fireNum)
                detailRow("IC", value: incident.ic)
                detailRow("Acres", value: incident.acres)
                detailRow("Fuels", value: incident.fuels)
                detailRow("Location", value: incident.location)

                if let date = incident.parsedDate {
                    HStack {
                        Text("Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(date, format: .dateTime.month(.wide).day().year().hour().minute())
                    }
                }
            }

            if let status = incident.parsedFireStatus,
               (status.contain != nil || status.control != nil || status.out != nil) {
                Section("Fire Status") {
                    detailRow("Contained", value: status.contain)
                    detailRow("Controlled", value: status.control)
                    detailRow("Out", value: status.out)
                }
            }

            if let resources = incident.resources?.compactMap({ $0 }), !resources.isEmpty {
                Section("Resources") {
                    ForEach(resources, id: \.self) { resource in
                        Text(resource)
                    }
                }
            }

            if let comment = incident.webComment, !comment.isEmpty {
                Section("Comments") {
                    Text(comment)
                }
            }

            if let description = incident.typeDescription {
                Section {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About Type: \(incident.type ?? "Unknown")")
                }
            }
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .contentMargins(.bottom, 120, for: .scrollContent)
        .navigationTitle(incident.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryDeck.signal("Incident.viewed", parameters: ["type": incident.type ?? "unknown"])
        }
        .confirmationDialog("If installed, open in:", isPresented: $showingMapOptions, titleVisibility: .visible) {
            if let coord = coordinate {
                Button("Apple Maps") {
                    let placemark = MKPlacemark(coordinate: coord)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = incident.displayName
                    mapItem.openInMaps()
                }

                Button("Google Maps") {
                    let urlString = "comgooglemaps://?q=\(coord.latitude),\(coord.longitude)"
                    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    } else if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(coord.latitude),\(coord.longitude)") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Waze") {
                    let urlString = "waze://?ll=\(coord.latitude),\(coord.longitude)&navigate=yes"
                    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Gaia GPS") {
                    let urlString = "gaiagps://?ll=\(coord.latitude),\(coord.longitude)&zoom=14"
                    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $showingRAWS) {
            if let coord = coordinate {
                InAppBrowserSheet(title: "Nearby RAWS", url: URL(string: "https://viewer.synopticdata.com/map/data/now/air-temperature#map=10/\(coord.latitude)/\(coord.longitude)")!)
            }
        }
        .sheet(isPresented: $showingADSB) {
            if let coord = coordinate {
                InAppBrowserSheet(title: "ADS-B Exchange", url: URL(string: "https://globe.adsbexchange.com/?lat=\(coord.latitude)&lon=\(coord.longitude)&zoom=12")!)
            }
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
            }
        }
    }
}
