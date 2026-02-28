import Foundation
import SwiftData

struct MatchSetScoreDraft: Identifiable, Equatable {
    let id: UUID
    var setNumber: Int
    var playerGames: Int
    var opponentGames: Int

    init(
        id: UUID = UUID(),
        setNumber: Int,
        playerGames: Int = 0,
        opponentGames: Int = 0
    ) {
        self.id = id
        self.setNumber = setNumber
        self.playerGames = playerGames
        self.opponentGames = opponentGames
    }
}

struct SessionDraft {
    var date: Date
    var sessionName: String
    var sessionType: SessionType
    var durationMinutes: Int
    var rushedShots: Int
    var composure: Int

    var focusText: String
    var followedFocus: FollowedFocus
    var unforcedErrors: Int
    var longRallies: Int
    var directionChanges: Int
    var notes: String
    var saveMatchResult: Bool
    var opponentName: String
    var setScores: [MatchSetScoreDraft]

    var isCompetitiveSession: Bool {
        sessionType == .friendly || sessionType == .match
    }

    var shouldPersistMatchResult: Bool {
        isCompetitiveSession && saveMatchResult
    }

    init() {
        let initialDate = Date()
        date = initialDate
        sessionName = Session.defaultName(for: initialDate)
        sessionType = .class
        durationMinutes = 60
        rushedShots = 0
        composure = 5
        focusText = ""
        followedFocus = .partial
        unforcedErrors = 0
        longRallies = 0
        directionChanges = 0
        notes = ""
        saveMatchResult = false
        opponentName = ""
        setScores = [MatchSetScoreDraft(setNumber: 1)]
    }

    init(session: Session) {
        date = session.date
        sessionName = session.displayName
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
        opponentName = session.opponent?.name ?? ""
        setScores = session.matchSetScores
            .sorted { lhs, rhs in
                if lhs.setNumber != rhs.setNumber { return lhs.setNumber < rhs.setNumber }
                return lhs.playerGames < rhs.playerGames
            }
            .enumerated()
            .map { index, score in
                MatchSetScoreDraft(
                    setNumber: index + 1,
                    playerGames: score.playerGames,
                    opponentGames: score.opponentGames
                )
            }
        if setScores.isEmpty {
            setScores = [MatchSetScoreDraft(setNumber: 1)]
        }
        saveMatchResult = session.opponent != nil || !session.matchSetScores.isEmpty
    }

    mutating func updateDate(_ newDate: Date) {
        let previousDate = date
        let previousDefaultName = Session.defaultName(for: previousDate)
        date = newDate

        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty || trimmedName == previousDefaultName {
            sessionName = Session.defaultName(for: newDate)
        }
    }

    mutating func addSetScore() {
        guard setScores.count < 5 else { return }
        setScores.append(MatchSetScoreDraft(setNumber: setScores.count + 1))
    }

    mutating func removeLastSetScore() {
        guard !setScores.isEmpty else { return }
        setScores.removeLast()
        if setScores.isEmpty {
            setScores = [MatchSetScoreDraft(setNumber: 1)]
        }
        renumberSetScores()
    }

    func buildSession(in modelContext: ModelContext) -> Session {
        let session = Session(
            sessionName: sessionName,
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
            notes: notes.isEmpty ? nil : notes,
            opponent: resolvedOpponent(in: modelContext)
        )

        session.matchSetScores = buildPersistedSetScores(for: session)
        return session
    }

    func apply(to session: Session, in modelContext: ModelContext) {
        session.date = date
        let trimmedSessionName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        session.sessionName = trimmedSessionName.isEmpty ? nil : trimmedSessionName
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
        session.opponent = resolvedOpponent(in: modelContext)
        for score in session.matchSetScores {
            modelContext.delete(score)
        }
        session.matchSetScores = buildPersistedSetScores(for: session)
        session.updatedAt = Date()
        session.syncState = session.remoteID == nil ? .localOnly : .pendingUpdate
    }

    private func buildPersistedSetScores(for session: Session) -> [MatchSetScore] {
        guard shouldPersistMatchResult else { return [] }
        return sanitizedSetScores()
            .enumerated()
            .map { index, score in
                MatchSetScore(
                    setNumber: index + 1,
                    playerGames: score.playerGames,
                    opponentGames: score.opponentGames,
                    session: session
                )
            }
    }

    private func resolvedOpponent(in modelContext: ModelContext) -> Opponent? {
        guard shouldPersistMatchResult else { return nil }
        let cleanedName = Opponent.cleanedName(opponentName)
        guard !cleanedName.isEmpty else { return nil }

        let normalized = Opponent.normalize(cleanedName)
        let predicate = #Predicate<Opponent> { candidate in
            candidate.normalizedName == normalized
        }
        var descriptor = FetchDescriptor<Opponent>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existingOpponents = try? modelContext.fetch(descriptor),
           let existing = existingOpponents.first {
            existing.name = cleanedName
            return existing
        }

        let opponent = Opponent(name: cleanedName)
        modelContext.insert(opponent)
        return opponent
    }

    private func sanitizedSetScores() -> [MatchSetScoreDraft] {
        guard shouldPersistMatchResult else { return [] }
        let normalized = setScores.enumerated().map { index, score in
            MatchSetScoreDraft(
                id: score.id,
                setNumber: index + 1,
                playerGames: max(0, score.playerGames),
                opponentGames: max(0, score.opponentGames)
            )
        }
        return normalized.isEmpty ? [MatchSetScoreDraft(setNumber: 1)] : normalized
    }

    private mutating func renumberSetScores() {
        for index in setScores.indices {
            setScores[index].setNumber = index + 1
        }
    }
}
