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
}
