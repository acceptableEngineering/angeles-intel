import SwiftUI

struct RAWSPlaceholderView: View {
    @StateObject private var viewModel = RAWSViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stations.isEmpty {
                ProgressView("Loading RAWS data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.stations.isEmpty {
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.fetch() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.stations.isEmpty {
                ContentUnavailableView {
                    Label("No Data", systemImage: "cloud.sun.fill")
                } description: {
                    Text("No RAWS observations available right now.")
                }
            } else {
                List(viewModel.stations) { station in
                    RAWSStationCard(station: station)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetch()
                }
            }
        }
        .task {
            await viewModel.fetchIfNeeded()
        }
    }
}

struct RAWSStationCard: View {
    let station: RAWSStation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.displayName)
                        .font(.headline)
                    Text(station.STID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let date = station.observationDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        + Text(" ago")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            HStack(spacing: 0) {
                weatherCell(
                    label: "Temp",
                    value: station.airTemp.map { String(format: "%.0f°F", $0) },
                    icon: "thermometer.medium"
                )
                weatherCell(
                    label: "RH",
                    value: station.relativeHumidity.map { String(format: "%.0f%%", $0) },
                    icon: "humidity.fill"
                )
                weatherCell(
                    label: "Wind",
                    value: station.windSpeed.map { "\(String(format: "%.0f", $0)) \(station.windCardinal)" },
                    icon: "wind"
                )
                weatherCell(
                    label: "Gust",
                    value: station.windGust.map { String(format: "%.0f mph", $0) },
                    icon: "wind"
                )
                weatherCell(
                    label: "Fuel M.",
                    value: station.fuelMoisture.map { String(format: "%.0f%%", $0) },
                    icon: "leaf.fill"
                )
            }
        }
        .padding(.vertical, 6)
    }

    private func weatherCell(label: String, value: String?, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "--")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
