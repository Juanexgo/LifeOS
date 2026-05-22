import AppIntents
import SwiftData
import PersistenceKit

/// "Hey Siri, add task to LifeOS." Also appears in Spotlight and Shortcuts.app.
///
/// We don't use `@Dependency` — that would require registering an
/// `AppDependencyManager`. For a free-Apple-ID dev flow that's overkill;
/// loading the SwiftData container at intent-time is acceptable.
struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Task"
    static let description = IntentDescription(
        "Add a task to LifeOS",
        categoryName: "Tasks",
        searchKeywords: ["task", "todo", "reminder", "add"]
    )
    static let openAppWhenRun = false
    static let isDiscoverable = true

    @Parameter(title: "Task")
    var taskTitle: String

    @Parameter(title: "Priority", default: TaskPriorityAppEnum.none)
    var priority: TaskPriorityAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$taskTitle) to LifeOS")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try PersistenceFactory.liveContainer()
        let context = ModelContext(container)
        let task = TaskItem(title: taskTitle, priority: priority.toDomain())
        context.insert(task)
        try context.save()
        return .result(dialog: IntentDialog("Added \"\(taskTitle)\""))
    }
}

/// AppIntents needs its own enum bridged via `AppEnum`.
enum TaskPriorityAppEnum: String, AppEnum {
    case none, low, medium, high

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Priority"
    static let caseDisplayRepresentations: [TaskPriorityAppEnum: DisplayRepresentation] = [
        .none:   "None",
        .low:    "Low",
        .medium: "Medium",
        .high:   "High"
    ]

    func toDomain() -> TaskPriority {
        switch self {
        case .none: return .none
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}
