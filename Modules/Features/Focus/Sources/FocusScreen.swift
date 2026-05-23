import SwiftUI
import SwiftData
import Charts
import DesignSystem
import SharedUI
import PersistenceKit

@MainActor
struct FocusScreen: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\FocusSession.startedAt, order: .reverse)])
    private var sessions: [FocusSession]

    @State private var viewModel = FocusViewModel()
    @State private var draftIntent: String = ""
    @State private var selectedDuration: Int = 25 * 60  // 25 min default

    private let durationOptions: [(label: String, seconds: Int)] = [
        ("15", 15 * 60),
        ("25", 25 * 60),
        ("45", 45 * 60),
        ("90", 90 * 60)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg.value) {
                        if viewModel.phase == .idle {
                            startCard
                        } else {
                            timerCard
                        }
                        weeklyChartCard
                        historyCard
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: viewModel.tick) { _, _ in
                // Auto-complete when timer reaches zero.
                if viewModel.remainingSeconds == 0 && viewModel.isRunning {
                    Haptics.success()
                    viewModel.stop(saving: ctx, completed: true)
                }
            }
        }
    }

    // MARK: - Cards

    private var startCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                Label("New session", systemImage: "timer")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.accent)

                TextField("What are you focusing on?", text: $draftIntent)
                    .font(Type.titleCard)
                    .submitLabel(.go)
                    .onSubmit { startSession() }
                    .padding(.horizontal, .sm)
                    .padding(.vertical, .xs)
                    .glass(.raised, in: Capsule())
                    .clipShape(Capsule())

                HStack(spacing: 8) {
                    ForEach(durationOptions, id: \.seconds) { option in
                        durationChip(option.label, value: option.seconds)
                    }
                }

                GlassButton("Start \(selectedDuration / 60) min", systemImage: "play.fill") {
                    startSession()
                }
                .disabled(draftIntent.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(draftIntent.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    private func durationChip(_ label: String, value: Int) -> some View {
        Button {
            Haptics.tap()
            selectedDuration = value
        } label: {
            Text("\(label) min")
                .font(Type.label)
                .foregroundStyle(selectedDuration == value ? Palette.textPrimary : Palette.textSecondary)
                .padding(.horizontal, Spacing.sm.value)
                .padding(.vertical, Spacing.xs.value)
                .background {
                    Capsule().fill(selectedDuration == value
                                   ? Palette.accent.opacity(0.25)
                                   : Color.clear)
                }
                .overlay(Capsule().strokeBorder(
                    selectedDuration == value ? Palette.accent : Palette.separator,
                    lineWidth: 1
                ))
        }
        .buttonStyle(.plain)
    }

    private var timerCard: some View {
        GlassCard(tier: .floating, radius: .lg, padding: .lg) {
            VStack(spacing: Spacing.md.value) {
                Text(viewModel.intentText)
                    .font(Type.titleSection)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)

                ZStack {
                    ProgressRing(
                        progress: viewModel.progress,
                        size: 220,
                        lineWidth: 12,
                        tint: Palette.accent
                    )
                    VStack {
                        Text(formatTime(viewModel.remainingSeconds))
                            .font(Type.numeral)
                            .foregroundStyle(Palette.textPrimary)
                        Text(viewModel.isPaused ? "Paused" : "Focus")
                            .font(Type.captionTight)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                .padding(.vertical, Spacing.sm.value)

                HStack(spacing: Spacing.md.value) {
                    GlassButton(
                        viewModel.isPaused ? "Resume" : "Pause",
                        systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                        tone: .secondary
                    ) {
                        if viewModel.isPaused { viewModel.resume() } else { viewModel.pause() }
                    }

                    GlassButton("Stop", systemImage: "stop.fill", tone: .danger) {
                        viewModel.stop(saving: ctx, completed: false)
                    }
                }
            }
        }
    }

    private struct WeekBucket: Identifiable {
        var id: Date { date }
        let date: Date
        let minutes: Int
    }

    private var weeklyBuckets: [WeekBucket] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now)!)
        let start = cal.date(byAdding: .day, value: -7, to: end)!
        let recent = sessions.filter { $0.startedAt >= start && $0.startedAt < end }
        let grouped = Dictionary(grouping: recent) {
            cal.startOfDay(for: $0.startedAt)
        }
        return stride(from: 0, to: 7, by: 1).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let mins = grouped[day]?.map(\.actualMinutes).reduce(0, +) ?? 0
            return WeekBucket(date: day, minutes: mins)
        }
    }

    private var weeklyChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Last 7 days",
                              subtitle: "Deep work minutes")
                if weeklyBuckets.allSatisfy({ $0.minutes == 0 }) {
                    Text("Start a session — your weekly cadence will appear here.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                        .frame(height: 140, alignment: .center)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(weeklyBuckets) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Minutes", day.minutes)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Palette.accentSecondary, Palette.accent.opacity(0.5)],
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

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("History",
                              subtitle: "\(todayMinutes) min today")
                if sessions.isEmpty {
                    Text("Your completed sessions will appear here.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(sessions.prefix(5)) { session in
                        sessionRow(session)
                    }
                }
            }
        }
    }

    private func sessionRow(_ s: FocusSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.intent.isEmpty ? "(no intent)" : s.intent)
                    .font(Type.body)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(s.startedAt, format: .dateTime.month().day().hour().minute())
                    .font(Type.captionTight)
                    .foregroundStyle(Palette.textTertiary)
            }
            Spacer()
            Text("\(s.actualMinutes)m")
                .font(Type.monoCaption)
                .foregroundStyle(s.wasCancelled ? Palette.warn : Palette.textSecondary)
                .monospacedDigit()
            if s.wasCancelled {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.warn)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var todayMinutes: Int {
        sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .map(\.actualMinutes)
            .reduce(0, +)
    }

    private func startSession() {
        let intent = draftIntent.trimmingCharacters(in: .whitespaces)
        guard !intent.isEmpty else { return }
        Haptics.commit()
        viewModel.start(intent: intent, plannedSeconds: selectedDuration)
        draftIntent = ""
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
