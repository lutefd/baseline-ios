import Foundation

enum SessionValidationError: LocalizedError, Equatable {
    case invalidDuration
    case invalidRushedShots
    case invalidComposure
    case invalidSessionName
    case missingOpponentName
    case missingSetScores
    case invalidSetGames

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Duration must be greater than zero."
        case .invalidRushedShots:
            return "Rushed shots cannot be negative."
        case .invalidComposure:
            return "Composure must be between 1 and 10."
        case .invalidSessionName:
            return "Session name cannot be empty."
        case .missingOpponentName:
            return "Opponent name is required when saving match results."
        case .missingSetScores:
            return "Add at least one set score."
        case .invalidSetGames:
            return "Set games must be between 0 and 30."
        }
    }
}

enum SessionDraftValidator {
    static func validate(_ draft: SessionDraft) throws {
        guard !draft.sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SessionValidationError.invalidSessionName
        }
        guard draft.durationMinutes > 0 else {
            throw SessionValidationError.invalidDuration
        }
        guard draft.rushedShots >= 0 else {
            throw SessionValidationError.invalidRushedShots
        }
        guard (1...10).contains(draft.composure) else {
            throw SessionValidationError.invalidComposure
        }
        guard !draft.shouldPersistMatchResult ||
            !draft.opponentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw SessionValidationError.missingOpponentName
        }
        guard !draft.shouldPersistMatchResult || !draft.setScores.isEmpty else {
            throw SessionValidationError.missingSetScores
        }
        guard !draft.shouldPersistMatchResult ||
            draft.setScores.allSatisfy({ (0...30).contains($0.playerGames) && (0...30).contains($0.opponentGames) })
        else {
            throw SessionValidationError.invalidSetGames
        }
    }
}
