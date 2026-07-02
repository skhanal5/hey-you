import SwiftUI

struct DetectionStateView: View {
  let goal: String
  let site: String
  let fireCount: Int
  let elapsedMinutes: Int
  let spokenMessage: String
  let onBackToWork: () -> Void
  let onSnooze: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Sonar + status header
      HStack(spacing: 8) {
        SonarPingView(stateColor: StateColor.detectionRed())

        Text("CAUGHT SOMETHING")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(StateColor.detectionRed().opacity(0.8))
      }

      // Spoken message (LLM-generated or fallback)
      Text(spokenMessage)
        .font(.system(size: 19, weight: .semibold))
        .kerning(-0.19)
        .foregroundColor(.white)
        .fixedSize(horizontal: false, vertical: true)

      if !goal.isEmpty {
        GoalChipView(goal: goal, tint: StateColor.detectionRed())
      }

      // Action buttons
      VStack(spacing: 8) {
        Button("Back to it") {
          onBackToWork()
        }
        .buttonStyle(DangerButtonStyle())

        Button("5 more min") {
          onSnooze()
        }
        .buttonStyle(GhostButtonStyle())
      }
      .frame(maxWidth: .infinity)
    }
    .padding(20)
  }
}
