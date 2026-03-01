import Foundation

struct SyncPushRequestDTO: Codable {
    var sessions: [SessionDTO]
    var matchSets: [MatchSetDTO]
    var opponents: [OpponentDTO]
}

struct EntityCountsDTO: Codable {
    var inserted: Int
    var updated: Int
    var ignored: Int
}

struct SyncPushResponseDTO: Codable {
    var sessions: EntityCountsDTO
    var matchSets: EntityCountsDTO
    var opponents: EntityCountsDTO
    var serverTimestamp: Date
}

struct SyncPullResponseDTO: Codable {
    var sessions: [SessionDTO]
    var matchSets: [MatchSetDTO]
    var opponents: [OpponentDTO]
}

struct SessionDTO: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var opponentId: UUID?
    var sessionName: String
    var sessionType: String
    var date: Date
    var durationMinutes: Int
    var rushedShots: Int
    var unforcedErrors: Int
    var longRallies: Int
    var directionChanges: Int
    var composure: Int
    var focusText: String?
    var followedFocus: String?
    var isMatchWin: Bool?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

struct MatchSetDTO: Codable, Identifiable {
    var id: UUID
    var sessionId: UUID
    var setNumber: Int
    var playerGames: Int
    var opponentGames: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

struct OpponentDTO: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var identityKey: String
    var name: String
    var dominantHand: String?
    var playStyle: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID,
        userId: UUID?,
        identityKey: String?,
        name: String,
        dominantHand: String?,
        playStyle: String?,
        notes: String?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) {
        self.id = id
        self.userId = userId
        self.identityKey = Self.resolveIdentityKey(identityKey, id: id)
        self.name = name
        self.dominantHand = dominantHand
        self.playStyle = playStyle
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        identityKey = Self.resolveIdentityKey(
            try container.decodeIfPresent(String.self, forKey: .identityKey),
            id: id
        )
        name = try container.decode(String.self, forKey: .name)
        dominantHand = try container.decodeIfPresent(String.self, forKey: .dominantHand)
        playStyle = try container.decodeIfPresent(String.self, forKey: .playStyle)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }

    private static func resolveIdentityKey(_ rawIdentityKey: String?, id: UUID) -> String {
        let trimmed = rawIdentityKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? id.uuidString : trimmed
    }
}

enum SyncDateCoding {
    private static let withFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let internet: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let withFractional = withFractional.date(from: raw) {
                return withFractional
            }
            if let internet = internet.date(from: raw) {
                return internet
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid RFC3339 date")
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(withFractional.string(from: date))
        }
        return encoder
    }
}
