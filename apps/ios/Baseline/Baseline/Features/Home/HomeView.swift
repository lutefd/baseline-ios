import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    private let tennisGreen = Color(red: 0.45, green: 0.73, blue: 0.29)
    @State private var selectedSessionID: UUID?
    @State private var activeChartID: String?
    @State private var chartSelectionResetToken = 0

    private var lastSessionDate: String {
        guard let date = sessions.first?.date else { return "No sessions yet" }
        return date.formatted(date: .abbreviated, time: .shortened)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        pointColor: tennisGreen,
                        chartID: "rushed",
                        activeChartID: $activeChartID,
                        clearSelectionToken: chartSelectionResetToken,
                        valueFormatter: { String(format: "%.0f", $0) },
                        onSelectSession: { sessionID in
                            chartSelectionResetToken += 1
                            activeChartID = nil
                            selectedSessionID = sessionID
                        }
                    )

                    SparklineView(
                        title: "Composure",
                        points: SessionMetrics.composureTrendPoints(from: sessions),
                        lineColor: Color(red: 0.34, green: 0.36, blue: 0.39),
                        pointColor: tennisGreen,
                        chartID: "composure",
                        activeChartID: $activeChartID,
                        clearSelectionToken: chartSelectionResetToken,
                        valueFormatter: { String(format: "%.0f", $0) },
                        onSelectSession: { sessionID in
                            chartSelectionResetToken += 1
                            activeChartID = nil
                            selectedSessionID = sessionID
                        }
                    )
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: selectedSessionBinding) {
            if let session = selectedSession {
                SessionDetailView(session: session)
            } else {
                EmptyView()
            }
        }
    }

    private var selectedSession: Session? {
        guard let selectedSessionID else { return nil }
        return sessions.first { $0.id == selectedSessionID }
    }

    private var selectedSessionBinding: Binding<Bool> {
        Binding(
            get: { selectedSession != nil },
            set: { isPresented in
                if !isPresented {
                    selectedSessionID = nil
                    activeChartID = nil
                    chartSelectionResetToken += 1
                }
            }
        )
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
