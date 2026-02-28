import SwiftUI
import Charts
import os.log

struct SparklineView: View {
    private let logger = Logger(subsystem: "Baseline", category: "SparklineView")

    let title: String
    let points: [SessionTrendPoint]
    let lineColor: Color
    let fillColor: Color
    let pointColor: Color
    var valueFormatter: (Double) -> String = { String(format: "%.1f", $0) }
    var onSelectSession: (UUID) -> Void = { _ in }

    @State private var selectedPointID: UUID?

    // MARK: - Derived Data

    private struct ChartPoint: Identifiable {
        let id: UUID
        let index: Int
        let value: Double
        let session: SessionTrendPoint
    }

    private var chartPoints: [ChartPoint] {
        points.enumerated().map { offset, point in
            ChartPoint(id: point.id, index: offset, value: point.value, session: point)
        }
    }

    private var selectedPoint: ChartPoint? {
        guard let selectedPointID else { return nil }
        return chartPoints.first { $0.id == selectedPointID }
    }

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        if minValue == maxValue {
            let pad = max(0.5, abs(minValue) * 0.15)
            return (minValue - pad)...(maxValue + pad)
        }
        let span = maxValue - minValue
        let pad = max(0.2, span * 0.15)
        return (minValue - pad)...(maxValue + pad)
    }

    // MARK: - Body

    var body: some View {
        BaselineCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(BaselineTypography.sectionTitle)
                        .kerning(-0.2)
                        .foregroundStyle(BaselineTheme.primaryText)

                    Spacer()

                    if selectedPoint != nil {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedPointID = nil
                            }
                        } label: {
                            Text("Clear")
                                .font(BaselineTypography.caption)
                                .foregroundStyle(BaselineTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }

                // The chart with gesture overlay
                chartBody
                    .frame(height: 136)

                // Badge shown below the chart when a point is selected
                if let selectedPoint {
                    badgeButton(for: selectedPoint)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.easeOut(duration: 0.15), value: selectedPointID)
        }
    }

    // MARK: - Chart

    private var chartBody: some View {
        Chart {
            ForEach(chartPoints) { chartPoint in
                AreaMark(
                    x: .value("Index", chartPoint.index),
                    yStart: .value("Min", yDomain.lowerBound),
                    yEnd: .value("Value", chartPoint.value)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor.opacity(0.38), fillColor.opacity(0.24), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Index", chartPoint.index),
                    y: .value("Value", chartPoint.value)
                )
                .foregroundStyle(lineColor)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Index", chartPoint.index),
                    y: .value("Value", chartPoint.value)
                )
                .foregroundStyle(selectedPoint?.index == chartPoint.index ? lineColor : pointColor)
                .symbolSize(selectedPoint?.index == chartPoint.index ? 54 : 26)
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.index))
                    .foregroundStyle(lineColor.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: yDomain)
        .chartXScale(domain: 0...max(chartPoints.count - 1, 0))
        // Gesture overlay — same pattern as your working example
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else {
                                    logger.debug("plotFrame is nil")
                                    return
                                }

                                let plotOrigin = geo[plotFrame].origin
                                let locationInPlot = CGPoint(
                                    x: value.location.x - plotOrigin.x,
                                    y: 0
                                )

                                guard let rawIndex: Double = proxy.value(atX: locationInPlot.x) else {
                                    logger.debug("proxy.value returned nil at x=\(locationInPlot.x)")
                                    return
                                }

                                // Snap to nearest chart point
                                let nearest = chartPoints.min { a, b in
                                    abs(Double(a.index) - rawIndex) < abs(Double(b.index) - rawIndex)
                                }

                                if let nearest {
                                    logger.debug("Selected index=\(nearest.index) value=\(nearest.value)")
                                    selectedPointID = nearest.id
                                }
                            }
                            .onEnded { _ in
                                // Keep selection visible (don't clear on end)
                            }
                    )
            }
        }
        // Second overlay for the rule mark visual indicator
        .chartOverlay { proxy in
            if let selectedPoint {
                let xPos = proxy.position(forX: selectedPoint.index) ?? 0

                Circle()
                    .fill(lineColor)
                    .frame(width: 10, height: 10)
                    .position(
                        x: xPos,
                        y: proxy.position(forY: selectedPoint.value) ?? 0
                    )
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(BaselineTheme.chartSurface)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.6)
                )
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.black.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(BaselineTheme.secondaryText)
            }
        }
    }

    // MARK: - Badge

    private func badgeButton(for point: ChartPoint) -> some View {
        Button {
            logger.debug("Badge tapped → session \(point.session.sessionID.uuidString, privacy: .public)")
            onSelectSession(point.session.sessionID)
        } label: {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.session.date.formatted(date: .abbreviated, time: .omitted))
                        .font(BaselineTypography.caption)
                        .foregroundStyle(BaselineTheme.primaryText)
                    Text("\(point.session.sessionTypeLabel) • \(valueFormatter(point.value))")
                        .font(BaselineTypography.caption)
                        .foregroundStyle(BaselineTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(BaselineTheme.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BaselineTheme.rowSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(BaselineTheme.primaryText.opacity(0.14), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
