import SwiftUI
import Charts

struct SparklineView: View {
    let title: String
    let points: [SessionTrendPoint]
    let lineColor: Color
    let fillColor: Color
    
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
                    .font(.headline)
                    .foregroundStyle(BaselineTheme.primaryText)

                Chart(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(fillColor)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(lineColor)
                    .symbolSize(28)
                }
                .chartYScale(domain: yDomain)
                .chartPlotStyle { plot in
                    plot
                        .background(BaselineTheme.chartSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .frame(height: 136)
            }
        }
    }
}
