import Foundation
import SwiftData

struct OutboxQueue {
    static func enqueueCreate(for session: Session, context: ModelContext) {
        session.syncState = .pendingCreate
        context.insert(SyncOutboxItem(operation: .createSession, sessionID: session.id))
    }

    static func enqueueUpdate(for session: Session, context: ModelContext) {
        session.syncState = .pendingUpdate
        context.insert(SyncOutboxItem(operation: .updateSession, sessionID: session.id))
    }
}
