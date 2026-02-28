import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: Session
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            List {
                row("Date", session.date.formatted(date: .complete, time: .shortened))
                row("Type", session.sessionType.rawValue.capitalized)
                row("Duration", "\(session.durationMinutes) min")
                row("Rushed shots", "\(session.rushedShots)")
                row("Composure", "\(session.composure)")
                row("Rushing rate", String(format: "%.3f", SessionMetrics.rushingRate(for: session)))
                row("Focus", session.focusText ?? "-")
                row("Followed focus", session.followedFocus?.rawValue.capitalized ?? "-")
                row("Unforced errors", session.unforcedErrors.map(String.init) ?? "-")
                row("Long rallies", session.longRallies.map(String.init) ?? "-")
                row("Direction changes", session.directionChanges.map(String.init) ?? "-")
                row("Notes", session.notes ?? "-")
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .listRowSpacing(8)
        }
        .navigationTitle("Session")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            SessionEditorView(session: session)
        }
        .alert("Delete this session?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(session)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(BaselineTypography.body)
            Spacer()
            Text(value)
                .font(BaselineTypography.body)
                .foregroundStyle(BaselineTheme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
        .listRowBackground(BaselineTheme.rowSurface)
    }
}
