import Foundation
import SwiftData

@Model
final class SyncCursor {
    @Attribute(.unique) var id: String
    var lastPulledAt: Date?
    var lastPushAt: Date?
    var lastErrorAt: Date?
    var lastErrorMessage: String?
    var consecutiveFailures: Int
    var isSyncing: Bool

    init(
        id: String = SyncCursor.defaultID,
        lastPulledAt: Date? = nil,
        lastPushAt: Date? = nil,
        lastErrorAt: Date? = nil,
        lastErrorMessage: String? = nil,
        consecutiveFailures: Int = 0,
        isSyncing: Bool = false
    ) {
        self.id = id
        self.lastPulledAt = lastPulledAt
        self.lastPushAt = lastPushAt
        self.lastErrorAt = lastErrorAt
        self.lastErrorMessage = lastErrorMessage
        self.consecutiveFailures = consecutiveFailures
        self.isSyncing = isSyncing
    }

    static let defaultID = "default"
}
