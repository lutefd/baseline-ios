import Foundation

struct SessionTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum SessionMetrics {
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
            .sorted(by: { $0.date < $1.date })
            .suffix(limit)
            .map { SessionTrendPoint(date: $0.date, value: Double($0.rushedShots)) }
    }

    static func composureTrendPoints(from sessions: [Session], limit: Int = 20) -> [SessionTrendPoint] {
        sessions
            .sorted(by: { $0.date < $1.date })
            .suffix(limit)
            .map { SessionTrendPoint(date: $0.date, value: Double($0.composure)) }
    }

    private static func average(of sessions: [Session], window: Int, transform: (Session) -> Double) -> Double {
        let values = sessions
            .sorted(by: { $0.date < $1.date })
            .suffix(window)
            .map(transform)

        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
}
