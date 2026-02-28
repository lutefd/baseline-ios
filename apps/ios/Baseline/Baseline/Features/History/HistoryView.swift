import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var sessionToEdit: Session?
    @State private var sessionToDelete: Session?

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            List {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        BaselineCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(BaselineTypography.bodyStrong)
                                        .kerning(-0.2)
                                        .foregroundStyle(BaselineTheme.primaryText)
                                    Text(session.sessionType.rawValue.capitalized)
                                        .font(BaselineTypography.caption)
                                        .foregroundStyle(BaselineTheme.secondaryText)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    metricPill("C \(session.composure)")
                                    metricPill("R \(session.rushedShots)")
                                }
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BaselineTheme.secondaryText.opacity(0.8))
                                    .padding(.leading, 4)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            sessionToEdit = session
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(BaselineTheme.accent)

                        Button(role: .destructive) {
                            sessionToDelete = session
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("History")
        .sheet(item: $sessionToEdit) { session in
            SessionEditorView(session: session)
        }
        .alert("Delete this session?", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                guard let session = sessionToDelete else { return }
                modelContext.delete(session)
                try? modelContext.save()
                sessionToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func metricPill(_ text: String) -> some View {
        Text(text)
            .font(BaselineTypography.caption)
            .foregroundStyle(BaselineTheme.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(BaselineTheme.rowSurface, in: Capsule())
            .overlay(
                Capsule()
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
            )
            .clipShape(Capsule())
    }
}
