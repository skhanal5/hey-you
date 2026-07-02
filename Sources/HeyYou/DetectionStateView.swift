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

      // Goal chip (red-tinted, only when there's an active goal)
      if !goal.isEmpty {
        HStack(spacing: 6) {
          Circle()
            .fill(Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.7))
            .frame(width: 5, height: 5)
          (Text("Goal: ")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.4))
            + Text(goal)
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.6))
          )
          .lineLimit(1...3)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.06))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.2), lineWidth: 1)
        )
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
