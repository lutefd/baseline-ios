import SwiftUI
import SwiftData

@main
struct BaselineApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Opponent.self,
            MatchSetScore.self,
            SyncOutboxItem.self,
            SyncCursor.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            if shouldResetStore(after: error) {
                resetDefaultStoreFiles()
                do {
                    return try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch {
                    fatalError("Could not create ModelContainer after reset: \(error)")
                }
            }
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private func shouldResetStore(after error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain && nsError.code == 134110 {
        return true
    }

    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
       underlyingError.domain == NSCocoaErrorDomain,
       underlyingError.code == 134110 {
        return true
    }

    return false
}

private func resetDefaultStoreFiles() {
    let fileManager = FileManager.default
    guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        return
    }

    let baseStoreURL = appSupportURL.appendingPathComponent("default.store")
    let storeCandidates = [
        baseStoreURL,
        appSupportURL.appendingPathComponent("default.store-shm"),
        appSupportURL.appendingPathComponent("default.store-wal")
    ]

    for storeURL in storeCandidates where fileManager.fileExists(atPath: storeURL.path) {
        try? fileManager.removeItem(at: storeURL)
    }
}
