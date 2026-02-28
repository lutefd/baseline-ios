import SwiftUI
import SwiftData

struct NewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var draft = SessionDraft()
    @State private var errorMessage: String?
    @State private var startedAt = Date()
    @State private var durationMinutesText = "60"
    @State private var lastDurationMinutesValue = 60
    @FocusState private var isDurationFieldFocused: Bool
    @FocusState private var isFocusFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    var onSessionSaved: () -> Void = {}

    private let telemetry = TelemetryStore()

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            Form {
                Section("Core") {
                    DatePicker("Date & Time", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Type", selection: $draft.sessionType) {
                        ForEach(SessionType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("1-240", text: $durationMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 84)
                            .focused($isDurationFieldFocused)
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
                        .focused($isFocusFieldFocused)
                    Picker("Followed focus", selection: $draft.followedFocus) {
                        ForEach(FollowedFocus.allCases) { value in
                            Text(value.rawValue.capitalized).tag(value)
                        }
                    }
                    Stepper("Unforced errors: \(draft.unforcedErrors)", value: $draft.unforcedErrors, in: 0...500)
                    Stepper("Long rallies: \(draft.longRallies)", value: $draft.longRallies, in: 0...500)
                    Stepper("Direction changes: \(draft.directionChanges)", value: $draft.directionChanges, in: 0...500)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .focused($isNotesFieldFocused)
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
            .simultaneousGesture(
                TapGesture().onEnded {
                    isDurationFieldFocused = false
                    isFocusFieldFocused = false
                    isNotesFieldFocused = false
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isDurationFieldFocused = false
                        isFocusFieldFocused = false
                        isNotesFieldFocused = false
                    }
                }
            }
        }
        .navigationTitle("New Session")
        .onAppear {
            durationMinutesText = String(draft.durationMinutes)
            lastDurationMinutesValue = draft.durationMinutes
        }
        .onChange(of: isDurationFieldFocused) { _, isFocused in
            if isFocused {
                lastDurationMinutesValue = draft.durationMinutes
                durationMinutesText = ""
            } else {
                commitDurationText()
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
            let session = draft.buildSession()
            modelContext.insert(session)

            OutboxQueue.enqueueCreate(for: session, context: modelContext)

            try modelContext.save()

            telemetry.recordSave(formDurationSeconds: Date().timeIntervalSince(startedAt))
            draft = SessionDraft()
            startedAt = Date()
            durationMinutesText = String(draft.durationMinutes)
            lastDurationMinutesValue = draft.durationMinutes
            errorMessage = nil
            onSessionSaved()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
