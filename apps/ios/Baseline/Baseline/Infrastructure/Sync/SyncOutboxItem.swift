import Foundation
import SwiftData

enum OutboxOperation: String, Codable, CaseIterable, Identifiable {
    case createSession
    case updateSession

    var id: String { rawValue }
}

@Model
final class SyncOutboxItem {
    @Attribute(.unique) var id: UUID
    var operation: OutboxOperation
    var sessionID: UUID
    var idempotencyKey: UUID
    var enqueuedAt: Date
    var attempts: Int

    init(
        id: UUID = UUID(),
        operation: OutboxOperation,
        sessionID: UUID,
        idempotencyKey: UUID = UUID(),
        enqueuedAt: Date = Date(),
        attempts: Int = 0
    ) {
        self.id = id
        self.operation = operation
        self.sessionID = sessionID
        self.idempotencyKey = idempotencyKey
        self.enqueuedAt = enqueuedAt
        self.attempts = attempts
    }
}
