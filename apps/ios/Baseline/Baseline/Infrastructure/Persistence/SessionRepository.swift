import Foundation
import SwiftData

struct SessionRepository {
    let context: ModelContext

    func insert(_ session: Session) throws {
        context.insert(session)
        try context.save()
        Task { @MainActor in
            await SyncEngine.shared.syncNow(reason: .postMutation, context: context)
        }
    }

    func delete(_ session: Session) throws {
        session.deletedAt = Date()
        session.updatedAt = Date()
        session.syncState = session.remoteID == nil ? .localOnly : .pendingUpdate
        if session.remoteID != nil {
            OutboxQueue.enqueueUpdate(for: session, context: context)
        }
        try context.save()
        Task { @MainActor in
            await SyncEngine.shared.syncNow(reason: .postMutation, context: context)
        }
    }
}
