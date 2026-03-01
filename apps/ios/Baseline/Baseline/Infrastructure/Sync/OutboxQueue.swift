import Foundation
import SwiftData

struct OutboxQueue {
    static func enqueueCreate(for session: Session, context: ModelContext) {
        session.syncState = .pendingCreate
        guard !hasPendingOutboxItem(for: session.id, in: context) else { return }
        context.insert(SyncOutboxItem(operation: .createSession, sessionID: session.id))
    }

    static func enqueueUpdate(for session: Session, context: ModelContext) {
        session.syncState = .pendingUpdate
        guard !hasPendingOutboxItem(for: session.id, in: context) else { return }
        context.insert(SyncOutboxItem(operation: .updateSession, sessionID: session.id))
    }

    private static func hasPendingOutboxItem(for sessionID: UUID, in context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<SyncOutboxItem>(
            predicate: #Predicate { item in
                item.sessionID == sessionID
            }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor).isEmpty == false) ?? false
    }
}
