import Foundation

struct SessionTrendPoint: Identifiable {
    let id: UUID
    let sessionID: UUID
    let date: Date
    let value: Double
    let sessionTypeLabel: String
}

enum SessionMetrics {
    private static func sessionSort(_ lhs: Session, _ rhs: Session) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    static func rushingRate(for session: Session) -> Double {
        Double(session.rushedShots) / Double(max(session.durationMinutes, 1))
    }

    static func rollingAverageRushed(for sessions: [Session], window: Int = 5) -> Double {
        average(of: sessions, window: window) { Double($0.rushedShots) }
    }

    static func rollingAverageComposure(for sessions: [Session], window: Int = 5) -> Double {
        average(of: sessions, window: window) { Double($0.composure) }
    }

    static func rushedTrendPoints(from sessions: [Session], limit: Int = 20) -> [SessionTrendPoint] {
        sessions
            .sorted(by: sessionSort)
            .suffix(limit)
            .map {
                SessionTrendPoint(
                    id: $0.id,
                    sessionID: $0.id,
                    date: $0.date,
                    value: Double($0.rushedShots),
                    sessionTypeLabel: $0.sessionType.rawValue.capitalized
                )
            }
    }

    static func composureTrendPoints(from sessions: [Session], limit: Int = 20) -> [SessionTrendPoint] {
        sessions
            .sorted(by: sessionSort)
            .suffix(limit)
            .map {
                SessionTrendPoint(
                    id: $0.id,
                    sessionID: $0.id,
                    date: $0.date,
                    value: Double($0.composure),
                    sessionTypeLabel: $0.sessionType.rawValue.capitalized
                )
            }
    }

    private static func average(of sessions: [Session], window: Int, transform: (Session) -> Double) -> Double {
        let values = sessions
            .sorted(by: sessionSort)
            .suffix(window)
            .map(transform)

        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
}
