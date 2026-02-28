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
    var name: String
    var dominantHand: String?
    var playStyle: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
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
