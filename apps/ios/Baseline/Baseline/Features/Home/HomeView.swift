import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    private let tennisGreen = Color(red: 0.45, green: 0.73, blue: 0.29)

    private var lastSessionDate: String {
        guard let date = sessions.first?.date else { return "No sessions yet" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        ZStack {
            BaselineScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BaselineCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Baseline")
                                .font(BaselineTypography.hero)
                                .kerning(-0.8)
                                .foregroundStyle(BaselineTheme.primaryText)
                            Text("Last session: \(lastSessionDate)")
                                .font(BaselineTypography.body)
                                .foregroundStyle(BaselineTheme.secondaryText)
                        }
                    }

                    HStack(spacing: 12) {
                        metricCard(
                            title: "Avg Rushed",
                            value: String(format: "%.1f", SessionMetrics.rollingAverageRushed(for: sessions))
                        )
                        metricCard(
                            title: "Avg Composure",
                            value: String(format: "%.1f", SessionMetrics.rollingAverageComposure(for: sessions))
                        )
                    }

                SparklineView(
                    title: "Rushed Shots",
                    points: SessionMetrics.rushedTrendPoints(from: sessions),
                    lineColor: BaselineTheme.accent,
                    fillColor: BaselineTheme.accentSoft.opacity(0.3),
                    pointColor: tennisGreen
                )

                SparklineView(
                    title: "Composure",
                    points: SessionMetrics.composureTrendPoints(from: sessions),
                    lineColor: Color(red: 0.34, green: 0.36, blue: 0.39),
                    fillColor: Color(red: 0.95, green: 0.94, blue: 0.92).opacity(0.42),
                    pointColor: tennisGreen
                )
            }
            .padding(16)
        }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metricCard(title: String, value: String) -> some View {
        BaselineCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(BaselineTypography.cardLabel)
                    .foregroundStyle(BaselineTheme.secondaryText)
                Text(value)
                    .font(BaselineTypography.cardValue)
                    .kerning(-0.4)
                    .foregroundStyle(BaselineTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
