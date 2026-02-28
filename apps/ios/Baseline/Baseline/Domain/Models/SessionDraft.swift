import Foundation

struct SessionDraft {
    var date: Date = Date()
    var sessionType: SessionType = .class
    var durationMinutes: Int = 60
    var rushedShots: Int = 0
    var composure: Int = 5

    var focusText: String = ""
    var followedFocus: FollowedFocus = .partial
    var unforcedErrors: Int = 0
    var longRallies: Int = 0
    var directionChanges: Int = 0
    var notes: String = ""

    init() {}

    init(session: Session) {
        date = session.date
        sessionType = session.sessionType
        durationMinutes = session.durationMinutes
        rushedShots = session.rushedShots
        composure = session.composure
        focusText = session.focusText ?? ""
        followedFocus = session.followedFocus ?? .partial
        unforcedErrors = session.unforcedErrors ?? 0
        longRallies = session.longRallies ?? 0
        directionChanges = session.directionChanges ?? 0
        notes = session.notes ?? ""
    }

    func buildSession() -> Session {
        Session(
            date: date,
            sessionType: sessionType,
            durationMinutes: durationMinutes,
            rushedShots: rushedShots,
            composure: composure,
            focusText: focusText.isEmpty ? nil : focusText,
            followedFocus: focusText.isEmpty ? nil : followedFocus,
            unforcedErrors: unforcedErrors,
            longRallies: longRallies,
            directionChanges: directionChanges,
            notes: notes.isEmpty ? nil : notes
        )
    }

    func apply(to session: Session) {
        session.date = date
        session.sessionType = sessionType
        session.durationMinutes = durationMinutes
        session.rushedShots = rushedShots
        session.composure = composure
        session.focusText = focusText.isEmpty ? nil : focusText
        session.followedFocus = focusText.isEmpty ? nil : followedFocus
        session.unforcedErrors = unforcedErrors
        session.longRallies = longRallies
        session.directionChanges = directionChanges
        session.notes = notes.isEmpty ? nil : notes
        session.updatedAt = Date()
        session.syncState = session.remoteID == nil ? .localOnly : .pendingUpdate
    }
}
