import Foundation

enum SessionValidationError: LocalizedError, Equatable {
    case invalidDuration
    case invalidRushedShots
    case invalidComposure

    var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Duration must be greater than zero."
        case .invalidRushedShots:
            return "Rushed shots cannot be negative."
        case .invalidComposure:
            return "Composure must be between 1 and 10."
        }
    }
}

enum SessionDraftValidator {
    static func validate(_ draft: SessionDraft) throws {
        guard draft.durationMinutes > 0 else {
            throw SessionValidationError.invalidDuration
        }
        guard draft.rushedShots >= 0 else {
            throw SessionValidationError.invalidRushedShots
        }
        guard (1...10).contains(draft.composure) else {
            throw SessionValidationError.invalidComposure
        }
    }
}
