import SwiftUI

struct ResourceLink: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let icon: String
}

struct ResourcesView: View {
    @Environment(\.openURL) private var openURL

    private let beforeGoing: [ResourceLink] = [
        ResourceLink(title: "Create a Hiking Plan", url: URL(string: "http://file.lacounty.gov/lasd/cms1_163961.pdf")!, icon: "figure.hiking"),
        ResourceLink(title: "Current Weather Station Data", url: URL(string: "https://viewer.synopticdata.com/map/data/now/air-temperature/CEKC1/plots/temperature#stationdensity=0&map=9.46%2F34.2358%2F-117.8931")!, icon: "cloud.sun.fill"),
    ]

    private let planning: [ResourceLink] = [
        ResourceLink(title: "Road Conditions: CA DOT", url: URL(string: "https://roads.dot.ca.gov/")!, icon: "car.fill"),
        ResourceLink(title: "Road Conditions: LA County Public Works", url: URL(string: "https://pw.lacounty.gov/roadclosures/")!, icon: "road.lanes"),
        ResourceLink(title: "Historical Weather Data & Graphs", url: URL(string: "https://weatherspark.com/y/1979/Average-Weather-in-Wrightwood-California-United-States-Year-Round")!, icon: "chart.line.uptrend.xyaxis"),
        ResourceLink(title: "Angeles Adventures", url: URL(string: "https://angelesadventures.com/")!, icon: "mountain.2.fill"),
        ResourceLink(title: "Hiking Project", url: URL(string: "https://www.hikingproject.com/directory/8011405/angeles-national-forest")!, icon: "figure.hiking"),
        ResourceLink(title: "MTB Project", url: URL(string: "https://www.mtbproject.com/directory/8011405/angeles-national-forest")!, icon: "bicycle"),
    ]

    private let monitoring: [ResourceLink] = [
        ResourceLink(title: "Twitter: @Angeles_NF", url: URL(string: "https://twitter.com/angeles_nf")!, icon: "at"),
        ResourceLink(title: "ALERTCalifornia Webcams", url: URL(string: "https://ops.alertcalifornia.org/tileset/13525")!, icon: "video.fill"),
        ResourceLink(title: "Mountain High Webcams", url: URL(string: "https://www.mthigh.com/site/mountain/mountain-info/livecams/index.html")!, icon: "video.fill"),
        ResourceLink(title: "Mountain Hardware Webcam", url: URL(string: "https://www.wrightwoodcalif.com/townlive.htm")!, icon: "video.fill"),
        ResourceLink(title: "Mt. Wilson Webcams", url: URL(string: "https://www.hpwren.ucsd.edu/cameras/#mode=realTime&realTimeShowType=&cams=wilson_wilson-n-mobo-c.wilson_wilson-e-mobo-c.wilson_wilson-s-mobo-c.wilson_wilson-w-mobo-c.wilson_wilson-n-mobo-m.wilson_wilson-e-mobo-m.wilson_wilson-s-mobo-m.wilson_wilson-w-mobo-m.wilson_wilson-e-axis.wilson_wilson-w-axis")!, icon: "video.fill"),
        ResourceLink(title: "Scanner Frequencies", url: URL(string: "https://wiki.radioreference.com/index.php/US_Forest_Service_-_Angeles_National_Forest_(CA)#Channel_Plan")!, icon: "radio.fill"),
    ]

    private let wildfireResources: [ResourceLink] = [
        ResourceLink(title: "Watch Duty", url: URL(string: "https://app.watchduty.org/")!, icon: "eye.fill"),
        ResourceLink(title: "InciWeb California", url: URL(string: "https://inciweb.wildfire.gov/state/california")!, icon: "globe"),
    ]

    var body: some View {
        List {
            Section {
                Text("What would this new app be without our age-old enormous list of links? Here are some resources we've found incredibly useful that you may enjoy.\n\nAll links open in your device's default browser:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            resourceSection("Before Going", links: beforeGoing)
            resourceSection("Planning", links: planning)
            resourceSection("Monitoring", links: monitoring)
            resourceSection("Wildfire Resources", links: wildfireResources)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 120, for: .scrollContent)
    }

    private func resourceSection(_ title: String, links: [ResourceLink]) -> some View {
        Section(title) {
            ForEach(links) { link in
                Button {
                    openURL(link.url)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: link.icon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        Text(link.title)
                            .foregroundStyle(.primary)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
    }
}
