import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case `class`
    case friendly
    case match

    var id: String { rawValue }
}

enum FollowedFocus: String, Codable, CaseIterable, Identifiable {
    case yes
    case partial
    case no

    var id: String { rawValue }
}

enum SyncState: String, Codable, CaseIterable, Identifiable {
    case localOnly
    case pendingCreate
    case pendingUpdate
    case synced
    case conflict

    var id: String { rawValue }
}

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sessionType: SessionType
    var durationMinutes: Int

    var rushedShots: Int
    var composure: Int

    var focusText: String?
    var followedFocus: FollowedFocus?
    var unforcedErrors: Int?
    var longRallies: Int?
    var directionChanges: Int?
    var notes: String?

    var createdAt: Date
    var updatedAt: Date
    var syncState: SyncState
    var remoteID: String?

    init(
        id: UUID = UUID(),
        date: Date,
        sessionType: SessionType,
        durationMinutes: Int,
        rushedShots: Int,
        composure: Int,
        focusText: String? = nil,
        followedFocus: FollowedFocus? = nil,
        unforcedErrors: Int? = nil,
        longRallies: Int? = nil,
        directionChanges: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncState: SyncState = .localOnly,
        remoteID: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sessionType = sessionType
        self.durationMinutes = durationMinutes
        self.rushedShots = rushedShots
        self.composure = composure
        self.focusText = focusText
        self.followedFocus = followedFocus
        self.unforcedErrors = unforcedErrors
        self.longRallies = longRallies
        self.directionChanges = directionChanges
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncState = syncState
        self.remoteID = remoteID
    }
}
