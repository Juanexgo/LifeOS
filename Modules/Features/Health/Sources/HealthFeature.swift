import SwiftUI
import Charts
import DesignSystem
import SharedUI
import HealthKitBridge

public enum HealthFeature {
    @MainActor
    public static func rootView() -> some View {
        HealthScreen()
    }
}

@MainActor
@Observable
final class HealthViewModel {
    let bridge = HealthKitBridge()
    var status: HealthKitBridge.Status = .notDetermined
    var snapshot: HealthKitBridge.Snapshot = .empty
    var week: [HealthKitBridge.DailyPoint] = []

    /// Default daily goals — Apple-Activity-app calibration.
    let stepGoal = 10_000
    let moveGoal = 500       // kcal
    let exerciseGoal = 30    // minutes

    func refresh() async {
        status = await bridge.status()
        guard status == .authorized else { return }
        async let snap = bridge.todaySnapshot()
        async let week = bridge.weekHistory()
        self.snapshot = await snap
        self.week = await week
    }

    var lastError: String? = nil

    func requestAccess() async {
        do {
            try await bridge.requestAccess()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        await refresh()
    }
}

@MainActor
struct HealthScreen: View {
    @State private var viewModel = HealthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        switch viewModel.status {
                        case .notDetermined: permissionCard
                        case .denied:        deniedCard
                        case .unavailable:   unavailableCard
                        case .authorized:
                            ringsCard
                            chartCard
                            metricsCard
                        }
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.refresh() }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Permission

    private var permissionCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                Label("Health", systemImage: "heart.fill")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.danger)
                Text("Connect to Health")
                    .font(Type.titleCard)
                    .foregroundStyle(Palette.textPrimary)
                Text("LifeOS reads steps, active calories, exercise minutes, and resting heart rate to give you a calm overview of your day. Data stays on your device.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
                if let err = viewModel.lastError {
                    Text(err)
                        .font(Type.caption)
                        .foregroundStyle(Palette.danger)
                }
                GlassButton("Allow access", systemImage: "heart") {
                    Task { await viewModel.requestAccess() }
                }
                .padding(.top, Spacing.xs.value)
            }
        }
    }

    private var deniedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Access denied")
                Text("Health access was declined. Enable it in Settings → Privacy & Security → Health → LifeOS.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var unavailableCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Not available")
                Text("HealthKit isn't available on this device.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    // MARK: - Cards

    private var ringsCard: some View {
        GlassCard(tier: .floating, radius: .lg, padding: .lg) {
            VStack(spacing: Spacing.md.value) {
                HStack(alignment: .center, spacing: Spacing.lg.value) {
                    activityRings
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        ringLegend(label: "Move",
                                   value: "\(viewModel.snapshot.activeKilocalories)",
                                   unit: "kcal",
                                   tint: .red)
                        ringLegend(label: "Exercise",
                                   value: "\(viewModel.snapshot.exerciseMinutes)",
                                   unit: "min",
                                   tint: .green)
                        ringLegend(label: "Steps",
                                   value: "\(viewModel.snapshot.steps)",
                                   unit: "",
                                   tint: .blue)
                    }
                }
            }
        }
    }

    /// Apple-style concentric activity rings — 3 layers.
    private var activityRings: some View {
        ZStack {
            ring(progress: progress(viewModel.snapshot.activeKilocalories, viewModel.moveGoal),
                 tint: .red, diameter: 140, lineWidth: 14)
            ring(progress: progress(viewModel.snapshot.exerciseMinutes, viewModel.exerciseGoal),
                 tint: .green, diameter: 104, lineWidth: 14)
            ring(progress: progress(viewModel.snapshot.steps, viewModel.stepGoal),
                 tint: .blue, diameter: 68, lineWidth: 14)
        }
        .frame(width: 140, height: 140)
    }

    private func ring(progress: Double, tint: Color, diameter: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.20), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
        .animation(Motion.gentle, value: progress)
    }

    private func ringLegend(label: String, value: String, unit: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(tint).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(Type.captionTight).foregroundStyle(Palette.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value).font(Type.bodyEmph).foregroundStyle(Palette.textPrimary).monospacedDigit()
                    if !unit.isEmpty {
                        Text(unit).font(Type.captionTight).foregroundStyle(Palette.textTertiary)
                    }
                }
            }
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Last 7 days", subtitle: "Steps")
                if viewModel.week.isEmpty {
                    Text("Walk around for a bit — your history will appear here.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    Chart(viewModel.week) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Steps", day.steps)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.accent, Palette.accent.opacity(0.5)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
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

    private var metricsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Vitals")
                HStack(spacing: Spacing.md.value) {
                    metricCell(
                        icon: "heart",
                        tint: Palette.danger,
                        label: "Resting HR",
                        value: viewModel.snapshot.restingHeartRate.map { "\($0)" } ?? "—",
                        unit: "bpm"
                    )
                    metricCell(
                        icon: "flame",
                        tint: .orange,
                        label: "Active",
                        value: "\(viewModel.snapshot.activeKilocalories)",
                        unit: "kcal"
                    )
                }
            }
        }
    }

    private func metricCell(icon: String, tint: Color, label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(Type.captionTight)
                .foregroundStyle(tint)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value).font(Type.titleCard).foregroundStyle(Palette.textPrimary).monospacedDigit()
                Text(unit).font(Type.captionTight).foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .glass(.raised, in: Radius.sm.shape)
        .clipShape(Radius.sm.shape)
    }

    // MARK: - Helpers

    private func progress(_ value: Int, _ goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return Double(value) / Double(goal)
    }
}
