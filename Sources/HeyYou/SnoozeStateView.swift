import SwiftUI

struct SnoozeStateView: View {
  let goal: String
  let remainingFormatted: String
  let onResume: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        SonarPingView(stateColor: StateColor.idleTranslucent())

        Text("DETECTION PAUSED")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(.white.opacity(0.4))
      }

      Text("Alright, you've got \(remainingFormatted) before I check again.")
        .font(.system(size: 19, weight: .semibold))
        .kerning(-0.19)
        .foregroundColor(.white)

      if !goal.isEmpty {
        GoalChipView(goal: goal, tint: .white.opacity(0.3))
      }

      VStack(spacing: 8) {
        Button("Resume session") {
          onResume()
        }
        .buttonStyle(PrimaryButtonStyle(isEnabled: true))
      }
      .frame(maxWidth: .infinity)
    }
    .padding(20)
  }
}
