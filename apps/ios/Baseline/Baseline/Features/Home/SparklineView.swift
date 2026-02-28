import SwiftUI
import Charts

struct SparklineView: View {
    let title: String
    let points: [SessionTrendPoint]
    let lineColor: Color
    let pointColor: Color
    let chartID: String
    @Binding var activeChartID: String?
    var clearSelectionToken: Int = 0
    var valueFormatter: (Double) -> String = { String(format: "%.1f", $0) }
    var onSelectSession: (UUID) -> Void = { _ in }

    @State private var selectedIndex: Int?

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
        guard let selectedIndex else { return nil }
        guard chartPoints.indices.contains(selectedIndex) else { return nil }
        return chartPoints[selectedIndex]
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

    var body: some View {
        BaselineCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(BaselineTypography.sectionTitle)
                    .kerning(-0.2)
                    .foregroundStyle(BaselineTheme.primaryText)

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
                                colors: [lineColor.opacity(0.30), lineColor.opacity(0.14), .clear],
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
                        .foregroundStyle(pointColor)
                        .symbolSize(selectedIndex == chartPoint.index ? 54 : 26)
                    }

                    if let selectedPoint {
                        RuleMark(x: .value("Selected Index", selectedPoint.index))
                            .foregroundStyle(lineColor.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        PointMark(
                            x: .value("Selected Index", selectedPoint.index),
                            y: .value("Selected Value", selectedPoint.value)
                        )
                        .foregroundStyle(lineColor)
                        .symbolSize(86)
                    }
                }
                .chartYScale(domain: yDomain)
                .chartXScale(domain: 0...max(chartPoints.count - 1, 0))
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
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                SpatialTapGesture()
                                    .onEnded { value in
                                        guard let plotFrame = proxy.plotFrame else {
                                            return
                                        }

                                        let plotRect = geometry[plotFrame]
                                        let xInPlot = value.location.x - plotRect.origin.x
                                        let yInPlot = value.location.y - plotRect.origin.y
                                        if xInPlot < 0 || xInPlot > plotRect.width || yInPlot < 0 || yInPlot > plotRect.height {
                                            clearSelection()
                                            return
                                        }
                                        updateSelection(atPlotX: xInPlot, plotWidth: plotRect.width)
                                    }
                            )
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard let plotFrame = proxy.plotFrame else {
                                            return
                                        }

                                        let plotRect = geometry[plotFrame]
                                        let xInPlot = value.location.x - plotRect.origin.x
                                        if xInPlot < 0 || xInPlot > plotRect.width {
                                            clearSelection()
                                            return
                                        }
                                        updateSelection(atPlotX: xInPlot, plotWidth: plotRect.width)
                                    }
                            )

                        if let selectedPoint,
                           let plotFrame = proxy.plotFrame,
                           let xPosition = proxy.position(forX: selectedPoint.index),
                           let yPosition = proxy.position(forY: selectedPoint.value) {
                            let plotRect = geometry[plotFrame]
                            Button {
                                onSelectSession(selectedPoint.session.sessionID)
                            } label: {
                                selectedBadge(for: selectedPoint)
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: min(max(plotRect.origin.x + xPosition, 70), geometry.size.width - 70),
                                y: max(18, plotRect.origin.y + yPosition - 34)
                            )
                        }
                    }
                }
                .frame(height: 136)
            }
        }
        .onChange(of: activeChartID) { _, newValue in
            if newValue != chartID {
                clearSelection()
            }
        }
        .onChange(of: clearSelectionToken) { _, _ in
            clearSelection()
        }
    }

    private func selectedBadge(for point: ChartPoint) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(BaselineTypography.caption)
                    .foregroundStyle(BaselineTheme.primaryText)
                Text("\(point.session.sessionTypeLabel) • \(valueFormatter(point.value))")
                    .font(BaselineTypography.caption)
                    .foregroundStyle(BaselineTheme.secondaryText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BaselineTheme.secondaryText.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(BaselineTheme.rowSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(BaselineTheme.primaryText.opacity(0.14), lineWidth: 0.8)
        )
    }

    private func updateSelection(atPlotX xInPlot: CGFloat, plotWidth: CGFloat) {
        guard !chartPoints.isEmpty else { return }
        guard plotWidth > 0 else { return }

        if chartPoints.count == 1 {
            activeChartID = chartID
            selectedIndex = 0
            return
        }

        let clampedX = min(max(xInPlot, 0), plotWidth)
        let step = plotWidth / CGFloat(chartPoints.count - 1)
        let nearestIndex = Int((clampedX / step).rounded())
        activeChartID = chartID
        selectedIndex = nearestIndex
    }

    private func clearSelection() {
        selectedIndex = nil
    }
}
