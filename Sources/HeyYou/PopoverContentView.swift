import SwiftUI

struct PopoverContentView: View {
  @ObservedObject var viewModel: PopoverViewModel

  // Idle callbacks
  var onStartListening: () -> Void = {}
  var onStopListening: () -> String? = { nil }
  var onConfirmGoal: (String) -> Void = { _ in }
  var onDismissIdle: () -> Void = {}
  var onOpenSettings: () -> Void = {}

  // Needs key callback
  var onSaveApiKey: (String) -> Void = { _ in }

  // Active callbacks
  var onEndSession: () -> Void = {}

  // Detection callbacks
  var onBackToWork: () -> Void = {}
  var onSnooze: () -> Void = {}

  var body: some View {
    Group {
      switch viewModel.state {
      case .needsKey:
        NeedsApiKeyView(onSave: onSaveApiKey)

      case .idle:
        IdleStateView(
          viewModel: viewModel,
          onStartListening: onStartListening,
          onStopListening: onStopListening,
          onConfirmGoal: onConfirmGoal,
          onDismiss: onDismissIdle,
          onOpenSettings: onOpenSettings
        )

      case .active(let goal, let startTime, let distractions):
        ActiveStateView(
          goal: goal,
          startTime: startTime,
          distractions: distractions,
          sessionsToday: viewModel.sessionsToday,
          totalFocusTime: viewModel.totalFocusTime,
          onEndSession: onEndSession
        )

      case .detecting:
        // Popover not yet shown during detecting — render nothing meaningful
        EmptyView()

      case .detection(let goal, let site, let fireCount, let elapsedMinutes, let spokenMessage):
        DetectionStateView(
          goal: goal,
          site: site,
          fireCount: fireCount,
          elapsedMinutes: elapsedMinutes,
          spokenMessage: spokenMessage,
          onBackToWork: onBackToWork,
          onSnooze: onSnooze
        )
      }
    }
    .cardShell()
    .transition(.opacity.combined(with: .scale(scale: 0.97)))
    .animation(.easeInOut(duration: 0.25), value: viewModel.state)
  }
}
