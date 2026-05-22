import SwiftUI
import DesignSystem
import Dashboard
import Tasks
import Notes
import Focus
import Assistant
import Finance
import Health
import Settings

/// Top-level navigation host. With more than 5 tabs, iOS 26's `TabView`
/// auto-overflows the extras into a "More" tab on iPhone — that's the
/// pattern Mail and Music use, and it's familiar.
struct RootView: View {
    let container: AppContainer

    @State private var selection: RootTab = .today
    @State private var isAssistantPresented = false

    enum RootTab: Hashable {
        case today, tasks, notes, focus, health, finance, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max.fill", value: RootTab.today) {
                DashboardFeature.rootView(onOpenAssistant: { isAssistantPresented = true })
            }
            Tab("Tasks", systemImage: "checklist", value: RootTab.tasks) {
                TasksFeature.rootView()
            }
            Tab("Notes", systemImage: "note.text", value: RootTab.notes) {
                NotesFeature.rootView()
            }
            Tab("Focus", systemImage: "timer", value: RootTab.focus) {
                FocusFeature.rootView()
            }
            Tab("Health", systemImage: "heart.fill", value: RootTab.health) {
                HealthFeature.rootView()
            }
            Tab("Finance", systemImage: "dollarsign.circle.fill", value: RootTab.finance) {
                FinanceFeature.rootView()
            }
            Tab("Settings", systemImage: "gear", value: RootTab.settings) {
                SettingsFeature.rootView(keychain: container.keychain)
            }
        }
        .sensoryFeedback(.lifeOS(.tap), trigger: selection)
        .sheet(isPresented: $isAssistantPresented) {
            AssistantFeature.rootView(router: container.aiRouter)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
