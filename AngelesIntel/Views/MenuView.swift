import SwiftUI

struct MenuItem: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let icon: String
    let colorName: String

    var color: Color {
        switch colorName {
        case "red": return .red
        case "cyan": return .cyan
        case "green": return .green
        case "orange": return .orange
        case "indigo": return .indigo
        default: return .primary
        }
    }

    static let incidents = MenuItem(id: "incidents", title: "Incidents", icon: "flame.fill", colorName: "red")
    static let raws = MenuItem(id: "raws", title: "RAWS", icon: "cloud.sun.fill", colorName: "cyan")
    static let notifications = MenuItem(id: "notifications", title: "Notifications", icon: "bell.badge.fill", colorName: "orange")
    static let status = MenuItem(id: "status", title: "System Status", icon: "server.rack", colorName: "green")
    static let resources = MenuItem(id: "resources", title: "Resources / Links", icon: "link.circle.fill", colorName: "indigo")

    static let defaultOrder: [MenuItem] = [.incidents, .resources, .notifications]

    var appSection: AppSection? {
        switch id {
        case "incidents": return .incidents
        case "raws": return .raws
        case "notifications": return .notifications
        case "resources": return .resources
        default: return nil
        }
    }
}

struct MenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSection: AppSection
    @Binding var menuItems: [MenuItem]
    @State private var showingStatus = false
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(menuItems) { item in
                    if item.id == "status" {
                        Button {
                            showingStatus = true
                        } label: {
                            menuLabel(item)
                        }
                    } else if let section = item.appSection {
                        Button {
                            selectedSection = section
                            dismiss()
                        } label: {
                            menuLabel(item, showCheckmark: selectedSection == section)
                        }
                    }
                }
                .onMove { from, to in
                    menuItems.move(fromOffsets: from, toOffset: to)
                    saveOrder()
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditing ? "Done" : "Reorder") {
                        withAnimation { isEditing.toggle() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingStatus) {
                StatusWebView()
            }
        }
    }

    private func menuLabel(_ item: MenuItem, showCheckmark: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
                .frame(width: 28)
            Text(item.title)
                .foregroundStyle(.primary)
            Spacer()
            if showCheckmark {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func saveOrder() {
        if let data = try? JSONEncoder().encode(menuItems.map(\.id)) {
            UserDefaults.standard.set(data, forKey: "menuOrder")
        }
    }

    static func loadOrder() -> [MenuItem] {
        guard let data = UserDefaults.standard.data(forKey: "menuOrder"),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return MenuItem.defaultOrder
        }
        let lookup = Dictionary(uniqueKeysWithValues: MenuItem.defaultOrder.map { ($0.id, $0) })
        let ordered = ids.compactMap { lookup[$0] }
        let missing = MenuItem.defaultOrder.filter { item in !ids.contains(item.id) }
        return ordered + missing
    }
}

struct StatusWebView: View {
    var body: some View {
        InAppBrowserSheet(title: "System Status", url: URL(string: "https://status.landmark717.com/status/anf-firebot")!)
    }
}
