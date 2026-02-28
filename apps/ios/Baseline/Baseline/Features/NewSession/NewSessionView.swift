import SwiftUI
import SwiftData

struct NewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var draft = SessionDraft()
    @State private var errorMessage: String?
    @State private var startedAt = Date()
    var onSessionSaved: () -> Void = {}

    private let telemetry = TelemetryStore()

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            Form {
                Section("Core") {
                    DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                    Picker("Type", selection: $draft.sessionType) {
                        ForEach(SessionType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("1-240", value: durationMinutesBinding, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 84)
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
                    Picker("Followed focus", selection: $draft.followedFocus) {
                        ForEach(FollowedFocus.allCases) { value in
                            Text(value.rawValue.capitalized).tag(value)
                        }
                    }
                    Stepper("Unforced errors: \(draft.unforcedErrors)", value: $draft.unforcedErrors, in: 0...500)
                    Stepper("Long rallies: \(draft.longRallies)", value: $draft.longRallies, in: 0...500)
                    Stepper("Direction changes: \(draft.directionChanges)", value: $draft.directionChanges, in: 0...500)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
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
        }
        .navigationTitle("New Session")
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { draft.durationMinutes },
            set: { draft.durationMinutes = min(max($0, 1), 240) }
        )
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
            errorMessage = nil
            onSessionSaved()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
