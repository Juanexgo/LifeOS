import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity for the running Focus session. Appears on Lock Screen and
/// in the Dynamic Island. Updated by the main app via `Activity.update(_:)`.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen / banner presentation.
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.tint)
                        .imageScale(.large)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.intent)
                            .font(.headline)
                            .lineLimit(1)
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
            } compactTrailing: {
                Text(timeString(context.state.remainingSeconds))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
            .keylineTint(.accentColor)
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lock screen view

private struct LockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.intent)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.isPaused ? "Paused" : "Focusing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(timeString(context.state.remainingSeconds))
                .font(.system(.title, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .padding()
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
