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
final class Opponent {
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute(.unique) var normalizedName: String
    var name: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    @Relationship(inverse: \Session.opponent) var sessions: [Session] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        let trimmedName = Self.cleanedName(name)
        self.name = trimmedName
        self.normalizedName = Self.normalize(trimmedName)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    static func cleanedName(_ name: String) -> String {
        let collapsed = name
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalize(_ name: String) -> String {
        cleanedName(name).lowercased()
    }
}

@Model
final class MatchSetScore {
    @Attribute(.unique) var id: UUID = UUID()
    var setNumber: Int
    var playerGames: Int
    var opponentGames: Int
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    @Relationship var session: Session?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        playerGames: Int,
        opponentGames: Int,
        session: Session? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.playerGames = playerGames
        self.opponentGames = opponentGames
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.session = session
    }
}

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var sessionName: String?
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
    var isMatchWin: Bool?

    @Relationship(deleteRule: .nullify) var opponent: Opponent?
    @Relationship(deleteRule: .cascade, inverse: \MatchSetScore.session) var matchSetScores: [MatchSetScore]

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var syncState: SyncState
    var remoteID: String?

    init(
        id: UUID = UUID(),
        sessionName: String? = nil,
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
        isMatchWin: Bool? = nil,
        opponent: Opponent? = nil,
        matchSetScores: [MatchSetScore] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncState: SyncState = .localOnly,
        remoteID: String? = nil
    ) {
        self.id = id
        let cleanedSessionName = sessionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.sessionName = cleanedSessionName.isEmpty ? nil : cleanedSessionName
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
        self.isMatchWin = isMatchWin
        self.opponent = opponent
        self.matchSetScores = matchSetScores
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncState = syncState
        self.remoteID = remoteID
    }

    static func defaultName(for date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    var displayName: String {
        let cleanedSessionName = sessionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return cleanedSessionName.isEmpty ? Self.defaultName(for: date) : cleanedSessionName
    }
}
