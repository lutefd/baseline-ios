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
    containsMigrationFailure(error as NSError)
}

private func containsMigrationFailure(_ nsError: NSError) -> Bool {
    if nsError.domain == NSCocoaErrorDomain && nsError.code == 134110 {
        return true
    }

    let nestedErrors = nsError.userInfo.values.flatMap { value -> [NSError] in
        if let error = value as? NSError {
            return [error]
        }
        if let errors = value as? [NSError] {
            return errors
        }
        return []
    }

    if nestedErrors.contains(where: containsMigrationFailure) {
        return true
    }

    return nsError.localizedDescription.contains("134110")
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
