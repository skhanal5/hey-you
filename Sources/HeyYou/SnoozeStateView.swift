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
        HStack(spacing: 6) {
          Circle()
            .fill(Color.white.opacity(0.3))
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
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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
