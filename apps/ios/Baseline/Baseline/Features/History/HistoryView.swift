import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            List(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            Text(session.sessionType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(BaselineTheme.secondaryText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            metricPill("C \(session.composure)")
                            metricPill("R \(session.rushedShots)")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.62))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("History")
    }

    private func metricPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(BaselineTheme.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(BaselineTheme.accentSoft.opacity(0.35))
            .clipShape(Capsule())
    }
}
