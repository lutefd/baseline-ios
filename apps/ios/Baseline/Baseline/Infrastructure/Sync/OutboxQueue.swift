import Foundation
import SwiftData

struct OutboxQueue {
    static func enqueueCreate(for session: Session, context: ModelContext) {
        context.insert(SyncOutboxItem(operation: .createSession, sessionID: session.id))
    }

    static func enqueueUpdate(for session: Session, context: ModelContext) {
        context.insert(SyncOutboxItem(operation: .updateSession, sessionID: session.id))
    }
}
