import SwiftUI
import SwiftData

struct SessionEditorView: View {
    private enum Field: Hashable {
        case sessionName
        case duration
        case focus
        case notes
        case opponentName
    }

    let session: Session

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var draft: SessionDraft
    @State private var errorMessage: String?
    @State private var durationMinutesText: String
    @State private var lastDurationMinutesValue: Int
    @FocusState private var focusedField: Field?

    init(session: Session) {
        self.session = session
        _draft = State(initialValue: SessionDraft(session: session))
        _durationMinutesText = State(initialValue: String(session.durationMinutes))
        _lastDurationMinutesValue = State(initialValue: session.durationMinutes)
    }

    var body: some View {
        NavigationStack {
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
                            TextField("Opponent name", text: $draft.opponentName)
                                .focused($focusedField, equals: .opponentName)

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
            }
            .navigationTitle("Edit Session")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .font(BaselineTypography.bodyStrong)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay {
            if focusedField != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }
            }
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
            draft.apply(to: session, in: modelContext)
            OutboxQueue.enqueueUpdate(for: session, context: modelContext)
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
