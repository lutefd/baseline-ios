import SwiftUI
import SwiftData

struct NewSessionView: View {
    private enum Field: Hashable {
        case sessionName
        case duration
        case focus
        case notes
        case opponentName
    }

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Opponent> { opponent in
            opponent.deletedAt == nil
        },
        sort: \Opponent.updatedAt,
        order: .reverse
    ) private var opponents: [Opponent]
    @State private var draft = SessionDraft()
    @State private var errorMessage: String?
    @State private var startedAt = Date()
    @State private var durationMinutesText = "60"
    @State private var lastDurationMinutesValue = 60
    @State private var selectedOpponentSuggestionID: UUID?
    @State private var showOpponentPicker = false
    @State private var opponentPickerQuery = ""
    @FocusState private var focusedField: Field?
    var onSessionSaved: () -> Void = {}

    private let telemetry = TelemetryStore()

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                Text("New Session")
                    .font(BaselineTypography.hero)
                    .kerning(-0.8)
                    .foregroundStyle(BaselineTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Form {
                    Section("Core") {
                        TextField("Session name", text: $draft.sessionName)
                            .focused($focusedField, equals: .sessionName)
                        DatePicker(
                            "Date & Time",
                            selection: Binding(
                                get: { draft.date },
                                set: { draft.updateDate($0) }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        Picker("Type", selection: $draft.sessionType) {
                            ForEach(SessionType.allCases) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                focusedField = nil
                            }
                        )
                        HStack {
                            Text("Duration (min)")
                            Spacer()
                            TextField("1-240", text: $durationMinutesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 84)
                                .focused($focusedField, equals: .duration)
                        }
                        Stepper("Rushed shots: \(draft.rushedShots)", value: $draft.rushedShots, in: 0...500)
                        VStack(alignment: .leading) {
                            Text("Composure: \(draft.composure)")
                            Slider(
                                value: Binding(
                                    get: { Double(draft.composure) },
                                    set: { draft.composure = Int($0.rounded()) }
                                ),
                                in: 1...10,
                                step: 1
                            )
                            .tint(BaselineTheme.accent)
                        }
                    }

                    Section("Optional") {
                        TextField("Focus", text: $draft.focusText)
                            .focused($focusedField, equals: .focus)
                        Picker("Followed focus", selection: $draft.followedFocus) {
                            ForEach(FollowedFocus.allCases) { value in
                                Text(value.rawValue.capitalized).tag(value)
                            }
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                focusedField = nil
                            }
                        )
                        Stepper("Unforced errors: \(draft.unforcedErrors)", value: $draft.unforcedErrors, in: 0...500)
                        Stepper("Long rallies: \(draft.longRallies)", value: $draft.longRallies, in: 0...500)
                        Stepper("Direction changes: \(draft.directionChanges)", value: $draft.directionChanges, in: 0...500)
                        TextField("Notes", text: $draft.notes, axis: .vertical)
                            .focused($focusedField, equals: .notes)
                    }

                    if draft.isCompetitiveSession {
                        Section("Match Result (Optional)") {
                            Toggle("Save match result", isOn: $draft.saveMatchResult)

                            if draft.saveMatchResult {
                                HStack(spacing: 8) {
                                    TextField("Opponent name", text: $draft.opponentName)
                                        .focused($focusedField, equals: .opponentName)

                                    Button {
                                        opponentPickerQuery = Opponent.cleanedName(draft.opponentName)
                                        focusedField = nil
                                        showOpponentPicker = true
                                    } label: {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(BaselineTheme.secondaryText)
                                            .frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(.plain)
                                }

                                ForEach($draft.setScores) { $setScore in
                                    VStack(alignment: .leading, spacing: 18) {
                                        Text("Set \(setScore.setNumber)")
                                            .font(BaselineTypography.bodyStrong)
                                        Stepper("Your games: \(setScore.playerGames)", value: $setScore.playerGames, in: 0...30)
                                            .padding(.top, 4)
                                            .padding(.bottom, 6)
                                        Stepper("Opponent games: \(setScore.opponentGames)", value: $setScore.opponentGames, in: 0...30)
                                    }
                                    .padding(.vertical, 10)
                                }

                                Button("Add set") {
                                    draft.addSetScore()
                                }
                                .disabled(draft.setScores.count >= 5)

                                if draft.setScores.count > 1 {
                                    Button("Remove last set", role: .destructive) {
                                        draft.removeLastSetScore()
                                    }
                                }
                            }
                        }
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Button("Save Session") {
                            save()
                        }
                        .font(BaselineTypography.bodyStrong)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .tint(BaselineTheme.accent)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if focusedField != .opponentName {
                            Spacer()
                            Button("Done") {
                                focusedField = nil
                            }
                        }
                    }
                }
            }

            if focusedField != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showOpponentPicker) {
            NavigationStack {
                List {
                    if filteredOpponents.isEmpty {
                        Text("No existing opponents found. Saving will create a new opponent.")
                            .font(BaselineTypography.caption)
                            .foregroundStyle(BaselineTheme.secondaryText)
                    } else {
                        ForEach(filteredOpponents) { opponent in
                            Button {
                                selectedOpponentSuggestionID = opponent.id
                                draft.selectExistingOpponent(opponent)
                                showOpponentPicker = false
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(opponent.name)
                                        .font(BaselineTypography.body)
                                        .foregroundStyle(BaselineTheme.primaryText)
                                    if let notes = opponent.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
                                       !notes.isEmpty {
                                        Text(notes)
                                            .font(BaselineTypography.caption)
                                            .foregroundStyle(BaselineTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $opponentPickerQuery, prompt: "Search opponents")
                .navigationTitle("Choose Opponent")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showOpponentPicker = false
                        }
                    }
                }
            }
        }
        .onAppear {
            durationMinutesText = String(draft.durationMinutes)
            lastDurationMinutesValue = draft.durationMinutes
        }
        .onChange(of: focusedField) { oldField, newField in
            if oldField == .duration, newField != .duration {
                commitDurationText()
            }
            if newField == .duration {
                lastDurationMinutesValue = draft.durationMinutes
                durationMinutesText = ""
            }
        }
        .onChange(of: durationMinutesText) { _, newValue in
            let digitsOnly = newValue.filter(\.isNumber)
            if digitsOnly != newValue {
                durationMinutesText = digitsOnly
                return
            }

            guard !digitsOnly.isEmpty, let value = Int(digitsOnly) else { return }
            draft.durationMinutes = min(max(value, 1), 240)
        }
        .onChange(of: draft.opponentName) { _, newValue in
            guard let selectedOpponentSuggestionID,
                  let selectedOpponent = opponents.first(where: { $0.id == selectedOpponentSuggestionID }),
                  Opponent.cleanedName(newValue) == selectedOpponent.name else {
                self.selectedOpponentSuggestionID = nil
                draft.clearSelectedOpponent()
                return
            }
        }
    }

    private var filteredOpponents: [Opponent] {
        let query = Opponent.cleanedName(opponentPickerQuery)
        guard !query.isEmpty else {
            return Array(opponents.prefix(30))
        }
        let loweredQuery = query.lowercased()
        return opponents
            .compactMap { opponent -> (opponent: Opponent, rank: Int)? in
                let loweredName = opponent.name.lowercased()
                if loweredName.hasPrefix(loweredQuery) {
                    return (opponent, 0)
                }
                if loweredName.contains(loweredQuery) {
                    return (opponent, 1)
                }
                let loweredNotes = (opponent.notes ?? "").lowercased()
                if !loweredNotes.isEmpty, loweredNotes.contains(loweredQuery) {
                    return (opponent, 2)
                }
                return nil
            }
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                return lhs.opponent.updatedAt > rhs.opponent.updatedAt
            }
            .prefix(30)
            .map(\.opponent)
    }

    private func commitDurationText() {
        guard let value = Int(durationMinutesText), !durationMinutesText.isEmpty else {
            draft.durationMinutes = min(max(lastDurationMinutesValue, 1), 240)
            durationMinutesText = String(draft.durationMinutes)
            return
        }

        draft.durationMinutes = min(max(value, 1), 240)
        durationMinutesText = String(draft.durationMinutes)
    }

    private func save() {
        do {
            try SessionDraftValidator.validate(draft)
            let session = draft.buildSession(in: modelContext)
            modelContext.insert(session)

            OutboxQueue.enqueueCreate(for: session, context: modelContext)

            try modelContext.save()

            telemetry.recordSave(formDurationSeconds: Date().timeIntervalSince(startedAt))
            draft = SessionDraft()
            startedAt = Date()
            durationMinutesText = String(draft.durationMinutes)
            lastDurationMinutesValue = draft.durationMinutes
            errorMessage = nil
            Task { @MainActor in
                await SyncEngine.shared.syncNow(reason: .postMutation, context: modelContext)
            }
            onSessionSaved()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
