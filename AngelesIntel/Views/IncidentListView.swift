import SwiftUI
import MapKit

struct IncidentListView: View {
    @StateObject private var viewModel = IncidentViewModel()
    @State private var searchText = ""
    @AppStorage("filterFireOnly") private var fireOnly = false
    @AppStorage("filterHideMasked") private var hideMasked = true
    @AppStorage("agencyVerified") private var agencyVerified = false
    @State private var filterInfoText: String?
    @State private var showingFullMap = false

    private var mappableIncidents: [Incident] {
        filteredIncidents.filter { $0.hasValidCoordinates }
    }

    var filteredIncidents: [Incident] {
        viewModel.incidents.filter { incident in
            if fireOnly && incident.type?.lowercased() != "wildfire" {
                return false
            }
            if hideMasked && incident.isMasked {
                return false
            }
            if !searchText.isEmpty {
                let matchesSearch =
                    incident.displayName.localizedCaseInsensitiveContains(searchText) ||
                    (incident.type?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    (incident.location?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    (incident.incNum?.localizedCaseInsensitiveContains(searchText) ?? false)
                if !matchesSearch { return false }
            }
            return true
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.incidents.isEmpty {
                ProgressView("Loading incidents...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.incidents.isEmpty {
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.fetchIncidents() }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                List {
                    if !mappableIncidents.isEmpty {
                        Section {
                            IncidentMapPreview(incidents: mappableIncidents) {
                                showingFullMap = true
                            }
                        }
                    }

                    Section {
                        HStack(spacing: 12) {
                            filterChip(
                                "Fire Only",
                                icon: "flame.fill",
                                color: .red,
                                isOn: $fireOnly
                            )
                            if !fireOnly {
                                filterChip(
                                    "Hide Masked",
                                    icon: "shield.slash",
                                    color: .blue,
                                    isOn: $hideMasked,
                                    helpText: "Some law enforcement incidents have their details redacted (shown as *******). Enable this to hide those entries and reduce clutter (\(viewModel.incidents.filter(\.isMasked).count) incidents in current view)."
                                )
                            }
                            Spacer()
                            CountdownText(viewModel: viewModel)
                        }
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(filteredIncidents) { incident in
                            NavigationLink(destination: IncidentDetailView(incident: incident)) {
                                IncidentRow(incident: incident)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .contentMargins(.top, 0, for: .scrollContent)
                .contentMargins(.bottom, 120, for: .scrollContent)
                .if(agencyVerified) { view in
                    view.refreshable {
                        await viewModel.fetchIncidents()
                        viewModel.nextRefreshAt = Date().addingTimeInterval(60)
                    }
                }
                .overlay {
                    if filteredIncidents.isEmpty {
                        if !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else if fireOnly || hideMasked {
                            ContentUnavailableView(
                                "No Matching Incidents",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("Try adjusting your filters.")
                            )
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search incidents")
        .alert("Filter Info", isPresented: Binding(
            get: { filterInfoText != nil },
            set: { if !$0 { filterInfoText = nil } }
        )) {
            Button("OK") { filterInfoText = nil }
        } message: {
            Text(filterInfoText ?? "")
        }
        .fullScreenCover(isPresented: $showingFullMap) {
            IncidentMapView(incidents: mappableIncidents)
        }
        .task {
            await viewModel.fetchIncidents()
            viewModel.startAutoRefresh()
        }
    }

    private func filterChip(
        _ title: String,
        icon: String,
        color: Color,
        isOn: Binding<Bool>,
        helpText: String? = nil
    ) -> some View {
        HStack(spacing: 6) {
            Toggle(isOn: isOn) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                }
                .font(.caption)
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .tint(isOn.wrappedValue ? color : .secondary)

            if let helpText {
                Button {
                    filterInfoText = helpText
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
    }

}

private struct CountdownText: View {
    @ObservedObject var viewModel: IncidentViewModel
    @State private var remaining: Int = 0
    @State private var timer: Timer?

    var body: some View {
        Group {
            if viewModel.isOffline {
                Text("OFFLINE")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                    .fixedSize()
            } else if viewModel.nextRefreshAt != nil {
                Text("Checking in \(remaining)s")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .fixedSize()
            }
        }
        .onAppear {
            updateRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func updateRemaining() {
        guard let nextAt = viewModel.nextRefreshAt else { return }
        remaining = max(0, Int(nextAt.timeIntervalSince(Date())))
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
