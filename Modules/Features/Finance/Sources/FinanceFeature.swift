import SwiftUI
import SwiftData
import Charts
import DesignSystem
import SharedUI
import PersistenceKit

public enum FinanceFeature {
    public enum Route: Hashable, Sendable {
        case detail(UUID)
        case newExpense
    }

    @MainActor
    public static func rootView() -> some View {
        FinanceScreen()
    }
}

@MainActor
struct FinanceScreen: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var expenses: [Expense]

    @State private var draft: Expense? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        summaryCard
                        weeklyChartCard
                        categoryCard
                        recentCard
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Finance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        draft = Expense(amount: 0)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            .sheet(item: $draft) { e in
                ExpenseEditor(expense: e) { result in
                    handle(result, for: e)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Derived state

    private struct DailyBucket: Identifiable {
        var id: Date { date }
        let date: Date
        let total: Double
    }

    private var currencyCode: String {
        expenses.first?.currencyCode ?? (Locale.current.currency?.identifier ?? "USD")
    }

    private var monthStart: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }

    private var lastMonthStart: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
    }

    private var monthTotal: Double {
        expenses.filter { $0.date >= monthStart }.map(\.amount).reduce(0, +)
    }

    private var lastMonthTotal: Double {
        expenses
            .filter { $0.date >= lastMonthStart && $0.date < monthStart }
            .map(\.amount)
            .reduce(0, +)
    }

    private var monthDelta: Double { monthTotal - lastMonthTotal }

    private var deltaPercent: Double? {
        guard lastMonthTotal > 0 else { return nil }
        return (monthTotal - lastMonthTotal) / lastMonthTotal
    }

    private var byCategory: [(category: ExpenseCategory, total: Double)] {
        let monthSpends = expenses.filter { $0.date >= monthStart }
        return Dictionary(grouping: monthSpends, by: \.category)
            .map { ($0.key, $0.value.map(\.amount).reduce(0, +)) }
            .sorted { $0.1 > $1.1 }
    }

    private var weeklyBuckets: [DailyBucket] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now)!)
        let start = cal.date(byAdding: .day, value: -7, to: end)!
        let recent = expenses.filter { $0.date >= start && $0.date < end }
        let grouped = Dictionary(grouping: recent) {
            cal.startOfDay(for: $0.date)
        }
        // Fill every day in range, even if empty, so the chart x-axis is continuous.
        return stride(from: 0, to: 7, by: 1).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let total = grouped[day]?.map(\.amount).reduce(0, +) ?? 0
            return DailyBucket(date: day, total: total)
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: 6) {
                Text("This month")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.textSecondary)
                Text(monthTotal.formatted(.currency(code: currencyCode)))
                    .font(Type.numeral)
                    .foregroundStyle(Palette.textPrimary)
                comparisonRow
            }
        }
    }

    @ViewBuilder
    private var comparisonRow: some View {
        if lastMonthTotal > 0 {
            HStack(spacing: 8) {
                Image(systemName: monthDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(monthDelta >= 0 ? Palette.danger : Palette.success)
                let absPct = abs(deltaPercent ?? 0)
                Text("\((absPct * 100).formatted(.number.precision(.fractionLength(0))))% vs last month")
                    .font(Type.captionTight)
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Text(lastMonthTotal.formatted(.currency(code: currencyCode)))
                    .font(Type.monoCaption)
                    .foregroundStyle(Palette.textTertiary)
            }
        } else {
            Text("\(expenses.count) total entries")
                .font(Type.captionTight)
                .foregroundStyle(Palette.textTertiary)
        }
    }

    private var weeklyChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Last 7 days",
                              subtitle: "Daily spending")
                if weeklyBuckets.allSatisfy({ $0.total == 0 }) {
                    Text("Nothing logged in the last week.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                        .frame(height: 140, alignment: .center)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(weeklyBuckets) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Total", day.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.accent, Palette.accent.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                                .foregroundStyle(Palette.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                            AxisGridLine().foregroundStyle(Palette.separator)
                            AxisValueLabel().foregroundStyle(Palette.textTertiary)
                        }
                    }
                    .frame(height: 140)
                }
            }
        }
    }

    private var categoryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                SectionHeader("By category", subtitle: "This month")
                if byCategory.isEmpty {
                    Text("Tap + to log your first expense.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    HStack(alignment: .center, spacing: Spacing.md.value) {
                        donut
                            .frame(width: 130, height: 130)
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(byCategory.prefix(5), id: \.category) { row in
                                HStack(spacing: 8) {
                                    Circle().fill(row.category.tint).frame(width: 8, height: 8)
                                    Text(row.category.label)
                                        .font(Type.captionTight)
                                        .foregroundStyle(Palette.textSecondary)
                                    Spacer()
                                    Text(row.total.formatted(.currency(code: currencyCode)))
                                        .font(Type.monoCaption)
                                        .foregroundStyle(Palette.textPrimary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var donut: some View {
        Chart(byCategory, id: \.category) { row in
            SectorMark(
                angle: .value("Total", row.total),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .foregroundStyle(row.category.tint)
            .cornerRadius(2)
        }
        .chartLegend(.hidden)
    }

    private var recentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Recent")
                if expenses.isEmpty {
                    Text("Nothing yet.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(expenses.prefix(8)) { e in
                        HStack {
                            Image(systemName: e.category.symbol)
                                .frame(width: 24)
                                .foregroundStyle(e.category.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.note.isEmpty ? e.category.label : e.note)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                Text(e.date, format: .dateTime.month().day())
                                    .font(Type.captionTight)
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            Spacer()
                            Text(e.formattedAmount)
                                .font(Type.mono)
                                .foregroundStyle(Palette.textPrimary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                ctx.delete(e)
                                try? ctx.save()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mutations

    private func handle(_ result: ExpenseEditor.Result, for e: Expense) {
        switch result {
        case .saved:
            if e.modelContext == nil { ctx.insert(e) }
            try? ctx.save()
            Haptics.commit()
        case .cancelled:
            break
        }
        draft = nil
    }
}
