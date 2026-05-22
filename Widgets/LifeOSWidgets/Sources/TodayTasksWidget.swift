import WidgetKit
import SwiftUI
import SwiftData
import PersistenceKit
import DesignSystem

/// Home Screen / Lock Screen widget showing pending tasks. Reads from the
/// shared SwiftData store via App Group.
///
/// IMPORTANT: For SwiftData sharing to actually work between app and widget,
/// the App Groups capability must be enabled in BOTH targets' entitlements,
/// AND `PersistenceFactory.liveContainer()` must be configured to use the
/// shared container URL. Until that's wired (it'll need a paid Developer
/// Program enrolment for the App Group identifier to register), the widget
/// shows snapshot/preview data.
struct TodayTasksWidget: Widget {
    let kind: String = "TodayTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayTasksView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Pending tasks and what's due today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let pendingCount: Int
    let dueTodayCount: Int
    let firstTaskTitle: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: .now, pendingCount: 3, dueTodayCount: 1, firstTaskTitle: "Prepare presentation")
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = load()
        // Refresh hourly. The app forces a reload on task changes via
        // WidgetCenter.shared.reloadTimelines.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func load() -> TaskEntry {
        do {
            let container = try PersistenceFactory.liveContainer()
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate { $0.isCompletedRaw == 0 },
                sortBy: [SortDescriptor(\.priorityRaw, order: .reverse),
                         SortDescriptor(\.createdAt, order: .reverse)]
            )
            let tasks = (try? context.fetch(descriptor)) ?? []
            let dueToday = tasks.filter {
                guard let due = $0.dueDate else { return false }
                return Calendar.current.isDateInToday(due) || due < .now
            }.count
            return TaskEntry(
                date: .now,
                pendingCount: tasks.count,
                dueTodayCount: dueToday,
                firstTaskTitle: tasks.first?.title ?? ""
            )
        } catch {
            return TaskEntry(date: .now, pendingCount: 0, dueTodayCount: 0, firstTaskTitle: "")
        }
    }
}

struct TodayTasksView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            HStack {
                Image(systemName: "checklist")
                VStack(alignment: .leading) {
                    Text("\(entry.pendingCount) pending").font(.headline)
                    Text("\(entry.dueTodayCount) due today").font(.caption)
                }
            }
        case .systemSmall, .systemMedium:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.tint)
                    Text("LifeOS").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                Text("\(entry.pendingCount)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("\(entry.dueTodayCount) due today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.firstTaskTitle.isEmpty {
                    Spacer(minLength: 0)
                    Text(entry.firstTaskTitle)
                        .font(.footnote)
                        .lineLimit(family == .systemSmall ? 1 : 2)
                }
            }
        default:
            Text("\(entry.pendingCount) tasks")
        }
    }
}
