import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var sessionToEdit: Session?
    @State private var sessionToDelete: Session?
    @State private var hiddenSessionIDs = Set<UUID>()

    private var visibleSessions: [Session] {
        sessions.filter { !hiddenSessionIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(BaselineTypography.hero)
                    .kerning(-0.8)
                    .foregroundStyle(BaselineTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                List {
                    ForEach(visibleSessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            BaselineCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.displayName)
                                            .font(BaselineTypography.bodyStrong)
                                            .kerning(-0.2)
                                            .foregroundStyle(BaselineTheme.primaryText)
                                        Text(summarySubtitle(for: session))
                                            .font(BaselineTypography.caption)
                                            .foregroundStyle(BaselineTheme.secondaryText)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        metricPill("C \(session.composure)")
                                        metricPill("R \(session.rushedShots)")
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
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
        }
        .toolbar(.hidden, for: .navigationBar)
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
                hiddenSessionIDs.insert(session.id)
                sessionToDelete = nil
                modelContext.delete(session)
                do {
                    try modelContext.save()
                } catch {
                    hiddenSessionIDs.remove(session.id)
                }
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

    private func summarySubtitle(for session: Session) -> String {
        let dateText = session.date.formatted(date: .abbreviated, time: .shortened)
        if let opponent = session.opponent?.name {
            return "\(session.sessionType.rawValue.capitalized) • vs \(opponent) • \(dateText)"
        }
        return "\(session.sessionType.rawValue.capitalized) • \(dateText)"
    }
}
