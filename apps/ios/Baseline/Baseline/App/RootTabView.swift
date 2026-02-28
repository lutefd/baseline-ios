import SwiftUI
import SwiftData

private enum RootTab: Hashable {
    case home
    case newSession
    case history
}

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var outboxItems: [SyncOutboxItem]
    @Query private var syncCursors: [SyncCursor]
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
        .overlay(alignment: .topTrailing) {
            if shouldShowSyncStatus {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: syncStatusIconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BaselineTheme.primaryText)
                        .frame(width: 22, height: 22)

                    if pendingSyncCount > 0 {
                        Text("\(pendingSyncCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(BaselineTheme.accent, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BaselineTheme.rowSurface, in: Capsule())
                .padding(.top, 6)
                .padding(.trailing, 12)
                .accessibilityLabel(syncStatusAccessibilityLabel)
            }
        }
        .tint(BaselineTheme.accent)
        .animation(.easeInOut(duration: 0.2), value: snackbarMessage)
        .task {
            await SyncEngine.shared.syncNow(reason: .appLaunch, context: modelContext)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { @MainActor in
                await SyncEngine.shared.syncNow(reason: .appForeground, context: modelContext)
            }
        }
    }

    private var shouldShowSyncStatus: Bool {
        pendingSyncCount > 0 || syncFailureCount > 0
    }

    private var pendingSyncCount: Int {
        outboxItems.count
    }

    private var syncFailureCount: Int {
        syncCursors.first?.consecutiveFailures ?? 0
    }

    private var syncStatusIconName: String {
        if syncFailureCount > 0 {
            return "icloud.slash"
        }
        return "icloud.and.arrow.up"
    }

    private var syncStatusAccessibilityLabel: String {
        if syncFailureCount > 0 {
            if pendingSyncCount > 0 {
                return "Sync failed. \(pendingSyncCount) items pending."
            }
            return "Sync failed."
        }
        return "\(pendingSyncCount) items pending sync."
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
