import SwiftUI

struct NotificationsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Notifications", systemImage: "bell.badge.fill")
        } description: {
            Text("Push notifications for new incidents and alerts are coming to the app in April 2026")
        }
    }
}
