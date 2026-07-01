import SwiftUI

struct PopoverContentView: View {
  @ObservedObject var viewModel: PopoverViewModel

  // Idle callbacks
  var onStartListening: () -> Void = {}
  var onStopListening: () -> String? = { nil }
  var onConfirmGoal: (String) -> Void = { _ in }
  var onDismissIdle: () -> Void = {}
  var onOpenSettings: () -> Void = {}

  // Active callbacks
  var onEndSession: () -> Void = {}

  // Detection callbacks
  var onDismissDetection: () -> Void = {}
  var onBackToWork: () -> Void = {}
  var onSnooze: () -> Void = {}

  var body: some View {
    Group {
      switch viewModel.state {
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

      case .detection(let goal, let site, let fireCount, let elapsedMinutes):
        DetectionStateView(
          goal: goal,
          site: site,
          fireCount: fireCount,
          elapsedMinutes: elapsedMinutes,
          onDismiss: onDismissDetection,
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
