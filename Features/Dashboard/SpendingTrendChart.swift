import SwiftUI
import Charts

struct SpendingTrendChart: View {
    let monthlyTotals: [MonthlyTotal]

    private var maxValue: Double {
        let allValues = monthlyTotals.flatMap { [NSDecimalNumber(decimal: $0.income).doubleValue,
                                                  NSDecimalNumber(decimal: $0.expense).doubleValue] }
        return max(allValues.max() ?? 1, 1)
    }

    var body: some View {
        Chart {
            ForEach(monthlyTotals) { total in
                AreaMark(
                    x: .value("Month", monthLabel(total.month)),
                    y: .value("Expense", NSDecimalNumber(decimal: total.expense).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Palette.accentPink.opacity(0.55), Theme.Palette.accentPink.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            ForEach(monthlyTotals) { total in
                LineMark(
                    x: .value("Month", monthLabel(total.month)),
                    y: .value("Expense", NSDecimalNumber(decimal: total.expense).doubleValue)
                )
                .foregroundStyle(Theme.Palette.accentPink)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            ForEach(monthlyTotals) { total in
                LineMark(
                    x: .value("Month", monthLabel(total.month)),
                    y: .value("Income", NSDecimalNumber(decimal: total.income).doubleValue)
                )
                .foregroundStyle(Theme.Palette.accentMint)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.Palette.glassStroke)
                AxisValueLabel()
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisValueLabel().foregroundStyle(Theme.Palette.textTertiary)
            }
        }
        .frame(height: 180)
    }

    private func monthLabel(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1)) ?? Date()
        return formatter.string(from: date)
    }
}
