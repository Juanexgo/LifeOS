import WidgetKit
import SwiftUI

/// The widget extension's entry point. SwiftUI's @main attribute decides
/// which widget bundle this extension contributes.
@main
struct LifeOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayTasksWidget()
        FocusLiveActivity()
    }
}
