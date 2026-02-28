import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

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
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(BaselineTheme.primaryText)
                            Text("Last session: \(lastSessionDate)")
                                .font(.subheadline)
                                .foregroundStyle(BaselineTheme.secondaryText)
                        }
                    }

                    HStack(spacing: 12) {
                        metricCard(
                            title: "Avg Rushed (5)",
                            value: String(format: "%.1f", SessionMetrics.rollingAverageRushed(for: sessions))
                        )
                        metricCard(
                            title: "Avg Composure (5)",
                            value: String(format: "%.1f", SessionMetrics.rollingAverageComposure(for: sessions))
                        )
                    }

                    SparklineView(
                        title: "Rushed Shots",
                        points: SessionMetrics.rushedTrendPoints(from: sessions),
                        lineColor: BaselineTheme.accent,
                        fillColor: BaselineTheme.accentSoft.opacity(0.15)
                    )

                    SparklineView(
                        title: "Composure",
                        points: SessionMetrics.composureTrendPoints(from: sessions),
                        lineColor: Color(red: 0.15, green: 0.55, blue: 0.34),
                        fillColor: Color(red: 0.67, green: 0.86, blue: 0.76).opacity(0.2)
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
                    .font(.caption)
                    .foregroundStyle(BaselineTheme.secondaryText)
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(BaselineTheme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
