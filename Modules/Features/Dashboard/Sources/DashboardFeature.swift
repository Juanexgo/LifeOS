import SwiftUI
import SwiftData
import DesignSystem
import SharedUI
import PersistenceKit

public enum DashboardFeature {
    public enum Route: Hashable, Sendable {
        case detail(String)
    }

    @MainActor
    public static func rootView(onOpenAssistant: @escaping () -> Void) -> some View {
        DashboardScreen(onOpenAssistant: onOpenAssistant)
    }
}

@MainActor
struct DashboardScreen: View {
    let onOpenAssistant: () -> Void

    @Query private var allTasks: [TaskItem]
    @Query(sort: [SortDescriptor(\FocusSession.startedAt, order: .reverse)])
    private var sessions: [FocusSession]

    @State private var greeting = greetingForCurrentTime()
    @State private var bridge = EventKitBridge()
    @State private var events: [EventKitBridge.Event] = []

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg.value) {
                        header
                        assistantCard
                        todayCard
                        if !events.isEmpty || bridge.currentStatus() == .notDetermined {
                            calendarCard
                        }
                        focusCard
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .md)
                    .padding(.bottom, .xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .task { events = await bridge.loadTodayEvents() }
        }
    }

    // MARK: - Derived state

    private var pendingTasks: [TaskItem] { allTasks.filter { !$0.isCompleted } }
    private var dueTodayCount: Int { allTasks.filter { $0.isDueToday }.count }
    private var completedToday: Int {
        allTasks.filter { task in
            guard let done = task.completedAt else { return false }
            return Calendar.current.isDateInToday(done)
        }.count
    }
    private var progressToday: Double {
        let total = completedToday + dueTodayCount
        guard total > 0 else { return 0 }
        return Double(completedToday) / Double(total)
    }
    private var focusMinutesToday: Int {
        sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .map(\.actualMinutes)
            .reduce(0, +)
    }

    // MARK: - Cards

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(Type.titleHero)
                .foregroundStyle(Palette.textPrimary)
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(Type.bodySoft)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    private var assistantCard: some View {
        GlassCard(tier: .floating, radius: .lg) {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                Label("Assistant", systemImage: "sparkles")
                    .font(Type.labelStrong)
                    .foregroundStyle(Palette.accentSecondary)
                Text("Ask anything")
                    .font(Type.titleCard)
                    .foregroundStyle(Palette.textPrimary)
                Text("Your on-device AI can summarise today, draft a note, or organise tasks. Nothing leaves your device.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
                GlassButton("Open Assistant", systemImage: "sparkles") {
                    onOpenAssistant()
                }
                .padding(.top, Spacing.xs.value)
            }
        }
    }

    private var todayCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: Spacing.md.value) {
                ProgressRing(progress: progressToday, size: 64, lineWidth: 8, tint: Palette.accent)
                    .overlay {
                        VStack(spacing: 0) {
                            Text("\(completedToday)")
                                .font(Type.bodyEmph)
                                .foregroundStyle(Palette.textPrimary)
                                .monospacedDigit()
                            Text("done").font(Type.captionTight).foregroundStyle(Palette.textSecondary)
                        }
                    }
                VStack(alignment: .leading, spacing: Spacing.xs.value) {
                    SectionHeader("Tasks",
                                  subtitle: "\(pendingTasks.count) pending · \(dueTodayCount) due today")
                    if pendingTasks.isEmpty {
                        Text("All clear. Take a breath.")
                            .font(Type.bodySoft)
                            .foregroundStyle(Palette.textSecondary)
                    } else {
                        ForEach(pendingTasks.prefix(3)) { t in
                            HStack(spacing: 6) {
                                Image(systemName: "circle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Palette.textTertiary)
                                Text(t.title.isEmpty ? "Untitled" : t.title)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var calendarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Calendar",
                              subtitle: events.isEmpty ? "Tap to grant access" : "\(events.count) events today")
                if events.isEmpty {
                    Text("LifeOS shows your day at a glance. Grant calendar access in Settings to see your events here.")
                        .font(Type.bodySoft)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(events.prefix(4)) { e in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color(cgColor: e.calendarColor ?? Palette.accent.cgColor!))
                                .frame(width: 3)
                                .frame(maxHeight: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.textPrimary)
                                    .lineLimit(1)
                                Text(e.timeRangeString)
                                    .font(Type.captionTight)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var focusCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                SectionHeader("Focus",
                              subtitle: "\(focusMinutesToday) m today")
                Text(focusMinutesToday > 0
                     ? "Nice work. Keep momentum in the Focus tab."
                     : "Start a deep work session in the Focus tab.")
                    .font(Type.bodySoft)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}

private func greetingForCurrentTime() -> String {
    let h = Calendar.current.component(.hour, from: .now)
    switch h {
    case 5..<12:  return "Good morning"
    case 12..<17: return "Good afternoon"
    case 17..<22: return "Good evening"
    default:      return "Hello"
    }
}
