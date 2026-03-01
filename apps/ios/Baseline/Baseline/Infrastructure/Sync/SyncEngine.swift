import Foundation
import SwiftData

@MainActor
final class SyncEngine {
    static let shared = SyncEngine()

    enum SyncReason: String {
        case appLaunch
        case appForeground
        case postMutation
        case manual
    }

    private var isSyncInFlight = false
    private var debouncedTask: Task<Void, Never>?

    private init() {}

    func enqueueAndSyncAfterMutation(context: ModelContext) {
        debouncedTask?.cancel()
        debouncedTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await self?.syncNow(reason: .postMutation, context: context)
        }
    }

    func syncNow(reason: SyncReason, context: ModelContext) async {
        guard !isSyncInFlight else { return }

        let cursor = ensureCursor(in: context)
        if reason == .appLaunch || reason == .appForeground {
            cursor.consecutiveFailures = 0
            cursor.lastErrorAt = nil
            cursor.lastErrorMessage = nil
        }
        isSyncInFlight = true
        cursor.isSyncing = true
        try? context.save()

        defer {
            cursor.isSyncing = false
            isSyncInFlight = false
            try? context.save()
        }

        do {
            try migrateLegacyOpponentIdentityKeys(in: context)

            let runtimeConfig = try RuntimeConfig.load()
            let client = SyncAPIClient(config: runtimeConfig)

            let outboxItems = try fetchOutboxItems(in: context)
            let validOutboxItems = try pruneStaleOutboxItems(outboxItems, in: context)
            let pushPayload = try buildPushPayload(from: validOutboxItems, in: context)

            if hasPushChanges(payload: pushPayload) {
                let pushResponse = try await client.push(pushPayload)
                applyPushSuccess(in: context, outboxItems: validOutboxItems, pushedSessions: pushPayload.sessions)
                cursor.lastPushAt = pushResponse.serverTimestamp
            }

            let pullSince = cursor.lastPulledAt ?? Date(timeIntervalSince1970: 0)
            let pullResponse = try await client.pull(updatedAfter: pullSince)
            try applyPull(response: pullResponse, in: context)

            cursor.lastPulledAt = Date()
            cursor.lastErrorAt = nil
            cursor.lastErrorMessage = nil
            cursor.consecutiveFailures = 0
            try context.save()
        } catch {
            cursor.lastErrorAt = Date()
            cursor.lastErrorMessage = compactErrorMessage(for: error)
            cursor.consecutiveFailures += 1
            try? context.save()
        }
    }

    private func compactErrorMessage(for error: Error) -> String {
        if let apiError = error as? SyncAPIClient.APIError {
            switch apiError {
            case .invalidResponse:
                return "Invalid sync response."
            case let .httpError(status):
                return "Sync failed (HTTP \(status))."
            }
        }
        if error is RuntimeConfig.ConfigError {
            return "Sync is not configured."
        }
        return "Sync failed."
    }

    private func hasPushChanges(payload: SyncPushRequestDTO) -> Bool {
        !payload.sessions.isEmpty || !payload.matchSets.isEmpty || !payload.opponents.isEmpty
    }

    private func ensureCursor(in context: ModelContext) -> SyncCursor {
        if let existing = try? fetchCursor(in: context) {
            return existing
        }
        let cursor = SyncCursor()
        context.insert(cursor)
        try? context.save()
        return cursor
    }

    private func fetchCursor(in context: ModelContext) throws -> SyncCursor? {
        var descriptor = FetchDescriptor<SyncCursor>()
        descriptor.fetchLimit = 8
        return try context.fetch(descriptor).first(where: { $0.id == SyncCursor.defaultID })
    }

    private func fetchOutboxItems(in context: ModelContext) throws -> [SyncOutboxItem] {
        let sort = SortDescriptor(\SyncOutboxItem.enqueuedAt, order: .forward)
        let descriptor = FetchDescriptor<SyncOutboxItem>(sortBy: [sort])
        return try context.fetch(descriptor)
    }

    private func pruneStaleOutboxItems(_ outboxItems: [SyncOutboxItem], in context: ModelContext) throws -> [SyncOutboxItem] {
        var validItems: [SyncOutboxItem] = []
        var removedAny = false

        for outboxItem in outboxItems {
            if try fetchSession(id: outboxItem.sessionID, in: context) != nil {
                validItems.append(outboxItem)
            } else {
                context.delete(outboxItem)
                removedAny = true
            }
        }

        if removedAny {
            try context.save()
        }

        return validItems
    }

    private func migrateLegacyOpponentIdentityKeys(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Opponent>()
        let opponents = try context.fetch(descriptor)
        var didUpdate = false

        for opponent in opponents {
            let identityKey = opponent.identityKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if identityKey.isEmpty {
                opponent.identityKey = opponent.id.uuidString
                didUpdate = true
            }
        }

        if didUpdate {
            try context.save()
        }
    }

    private func buildPushPayload(from outboxItems: [SyncOutboxItem], in context: ModelContext) throws -> SyncPushRequestDTO {
        let sessionIDs = Set(outboxItems.map(\.sessionID))
        var sessionDTOs: [SessionDTO] = []
        var matchSetDTOs: [MatchSetDTO] = []
        var opponentDTOsByID: [UUID: OpponentDTO] = [:]

        for sessionID in sessionIDs {
            guard let session = try fetchSession(id: sessionID, in: context) else { continue }
            sessionDTOs.append(session.toDTO())

            for score in session.matchSetScores where score.deletedAt == nil || session.deletedAt != nil {
                matchSetDTOs.append(score.toDTO(sessionID: session.id))
            }

            if let opponent = session.opponent {
                opponentDTOsByID[opponent.id] = opponent.toDTO()
            }
        }

        return SyncPushRequestDTO(
            sessions: sessionDTOs,
            matchSets: matchSetDTOs,
            opponents: Array(opponentDTOsByID.values)
        )
    }

    private func applyPushSuccess(in context: ModelContext, outboxItems: [SyncOutboxItem], pushedSessions: [SessionDTO]) {
        let pushedSessionIDs = Set(pushedSessions.map(\.id))
        for outbox in outboxItems {
            context.delete(outbox)
        }

        for sessionID in pushedSessionIDs {
            guard let session = try? fetchSession(id: sessionID, in: context) else { continue }
            session.syncState = .synced
            session.remoteID = sessionID.uuidString
        }
    }

    private func applyPull(response: SyncPullResponseDTO, in context: ModelContext) throws {
        for opponentDTO in response.opponents {
            try upsertOpponent(from: opponentDTO, in: context)
        }

        for sessionDTO in response.sessions {
            try upsertSession(from: sessionDTO, in: context)
        }

        for matchSetDTO in response.matchSets {
            try upsertMatchSet(from: matchSetDTO, in: context)
        }
    }

    private func upsertOpponent(from dto: OpponentDTO, in context: ModelContext) throws {
        if let existing = try fetchOpponent(id: dto.id, in: context) {
            guard dto.updatedAt > existing.updatedAt else { return }
            apply(opponent: existing, from: dto)
            return
        }

        if let byIdentityKey = try fetchOpponent(identityKey: dto.identityKey, in: context) {
            guard dto.updatedAt > byIdentityKey.updatedAt else { return }
            byIdentityKey.id = dto.id
            apply(opponent: byIdentityKey, from: dto)
            return
        }

        let created = Opponent(
            id: dto.id,
            identityKey: dto.identityKey,
            name: dto.name,
            dominantHand: dto.dominantHand,
            playStyle: dto.playStyle,
            notes: dto.notes,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt
        )
        context.insert(created)
    }

    private func apply(opponent: Opponent, from dto: OpponentDTO) {
        opponent.identityKey = dto.identityKey
        opponent.name = Opponent.cleanedName(dto.name)
        opponent.normalizedName = Opponent.normalize(dto.name)
        opponent.dominantHand = dto.dominantHand
        opponent.playStyle = dto.playStyle
        opponent.notes = dto.notes
        opponent.createdAt = dto.createdAt
        opponent.updatedAt = dto.updatedAt
        opponent.deletedAt = dto.deletedAt
    }

    private func upsertSession(from dto: SessionDTO, in context: ModelContext) throws {
        let sessionType = SessionType(rawValue: dto.sessionType)
        guard let sessionType else { return }

        let followedFocus = dto.followedFocus.flatMap(FollowedFocus.init(rawValue:))
        let opponent: Opponent?
        if let opponentID = dto.opponentId {
            opponent = try fetchOpponent(id: opponentID, in: context)
        } else {
            opponent = nil
        }

        if let existing = try fetchSession(id: dto.id, in: context) {
            guard dto.updatedAt > existing.updatedAt else { return }

            existing.sessionName = dto.sessionName
            existing.date = dto.date
            existing.sessionType = sessionType
            existing.durationMinutes = dto.durationMinutes
            existing.rushedShots = dto.rushedShots
            existing.composure = dto.composure
            existing.focusText = dto.focusText
            existing.followedFocus = followedFocus
            existing.unforcedErrors = dto.unforcedErrors
            existing.longRallies = dto.longRallies
            existing.directionChanges = dto.directionChanges
            existing.notes = dto.notes
            existing.isMatchWin = dto.isMatchWin
            existing.opponent = opponent
            existing.createdAt = dto.createdAt
            existing.updatedAt = dto.updatedAt
            existing.deletedAt = dto.deletedAt
            existing.remoteID = dto.id.uuidString
            existing.syncState = .synced
            return
        }

        let session = Session(
            id: dto.id,
            sessionName: dto.sessionName,
            date: dto.date,
            sessionType: sessionType,
            durationMinutes: dto.durationMinutes,
            rushedShots: dto.rushedShots,
            composure: dto.composure,
            focusText: dto.focusText,
            followedFocus: followedFocus,
            unforcedErrors: dto.unforcedErrors,
            longRallies: dto.longRallies,
            directionChanges: dto.directionChanges,
            notes: dto.notes,
            isMatchWin: dto.isMatchWin,
            opponent: opponent,
            matchSetScores: [],
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt,
            syncState: .synced,
            remoteID: dto.id.uuidString
        )
        context.insert(session)
    }

    private func upsertMatchSet(from dto: MatchSetDTO, in context: ModelContext) throws {
        guard let session = try fetchSession(id: dto.sessionId, in: context) else { return }

        if let existing = try fetchMatchSet(id: dto.id, in: context) {
            guard dto.updatedAt > existing.updatedAt else { return }
            existing.session = session
            existing.setNumber = dto.setNumber
            existing.playerGames = dto.playerGames
            existing.opponentGames = dto.opponentGames
            existing.createdAt = dto.createdAt
            existing.updatedAt = dto.updatedAt
            existing.deletedAt = dto.deletedAt
            return
        }

        let created = MatchSetScore(
            id: dto.id,
            setNumber: dto.setNumber,
            playerGames: dto.playerGames,
            opponentGames: dto.opponentGames,
            session: session,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt
        )
        context.insert(created)
    }

    private func fetchSession(id: UUID, in context: ModelContext) throws -> Session? {
        let predicate = #Predicate<Session> { session in
            session.id == id
        }
        var descriptor = FetchDescriptor<Session>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchOpponent(id: UUID, in context: ModelContext) throws -> Opponent? {
        let predicate = #Predicate<Opponent> { opponent in
            opponent.id == id
        }
        var descriptor = FetchDescriptor<Opponent>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchOpponent(identityKey: String, in context: ModelContext) throws -> Opponent? {
        let predicate = #Predicate<Opponent> { opponent in
            opponent.identityKey == identityKey
        }
        var descriptor = FetchDescriptor<Opponent>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchMatchSet(id: UUID, in context: ModelContext) throws -> MatchSetScore? {
        let predicate = #Predicate<MatchSetScore> { matchSet in
            matchSet.id == id
        }
        var descriptor = FetchDescriptor<MatchSetScore>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

private extension Session {
    func toDTO() -> SessionDTO {
        SessionDTO(
            id: id,
            userId: nil,
            opponentId: opponent?.id,
            sessionName: sessionName ?? Self.defaultName(for: date),
            sessionType: sessionType.rawValue,
            date: date,
            durationMinutes: durationMinutes,
            rushedShots: rushedShots,
            unforcedErrors: unforcedErrors ?? 0,
            longRallies: longRallies ?? 0,
            directionChanges: directionChanges ?? 0,
            composure: composure,
            focusText: focusText,
            followedFocus: focusText == nil ? nil : followedFocus?.rawValue,
            isMatchWin: isMatchWin,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

private extension MatchSetScore {
    func toDTO(sessionID: UUID) -> MatchSetDTO {
        MatchSetDTO(
            id: id,
            sessionId: sessionID,
            setNumber: setNumber,
            playerGames: playerGames,
            opponentGames: opponentGames,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

private extension Opponent {
    func toDTO() -> OpponentDTO {
        OpponentDTO(
            id: id,
            userId: nil,
            identityKey: identityKey,
            name: name,
            dominantHand: dominantHand,
            playStyle: playStyle,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
