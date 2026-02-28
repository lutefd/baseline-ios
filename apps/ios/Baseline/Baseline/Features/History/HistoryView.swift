import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            ScrollView {
                LazyVStack(spacing: 10) {
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
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("History")
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
