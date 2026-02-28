import SwiftUI

private enum RootTab: Hashable {
    case home
    case newSession
    case history
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .home
    @State private var snackbarMessage: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(RootTab.home)
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                NewSessionView {
                    selectedTab = .home
                    showSnackbar("Session saved")
                }
            }
            .tag(RootTab.newSession)
            .tabItem {
                Label("New", systemImage: "plus.circle")
            }

            NavigationStack {
                HistoryView()
            }
            .tag(RootTab.history)
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
        .overlay(alignment: .bottom) {
            if let snackbarMessage {
                Text(snackbarMessage)
                    .font(BaselineTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BaselineTheme.primaryText.opacity(0.9), in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .tint(BaselineTheme.accent)
        .animation(.easeInOut(duration: 0.2), value: snackbarMessage)
    }

    private func showSnackbar(_ message: String) {
        snackbarMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if snackbarMessage == message {
                snackbarMessage = nil
            }
        }
    }
}
