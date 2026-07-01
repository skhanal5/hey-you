import SwiftUI

struct DetectionStateView: View {
  let goal: String
  let site: String
  let fireCount: Int
  let elapsedMinutes: Int
  let spokenMessage: String
  let onDismiss: () -> Void
  let onBackToWork: () -> Void
  let onSnooze: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Sonar + status header + close button
      HStack(spacing: 8) {
        SonarPingView(stateColor: StateColor.detectionRed())

        Text("CAUGHT SOMETHING")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(StateColor.detectionRed().opacity(0.8))

        Spacer()

        Button(action: onDismiss) {
          Circle()
            .fill(.white.opacity(0.06))
            .overlay(
              Circle()
                .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .overlay(
              Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.2))
            )
            .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
      }

      // Spoken message (LLM-generated or fallback)
      Text(spokenMessage)
        .font(.system(size: 19, weight: .semibold))
        .kerning(-0.19)
        .foregroundColor(.white)
        .fixedSize(horizontal: false, vertical: true)

      // Goal chip (red-tinted)
      HStack(spacing: 6) {
        Circle()
          .fill(Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.7))
          .frame(width: 5, height: 5)
        Text("Goal: ")
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.4))
          + Text(goal)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.6))
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

      // Action buttons
      VStack(spacing: 8) {
        Button("Back to it") {
          onBackToWork()
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(StateColor.detectionRed())
        .clipShape(Capsule())

        Button("5 more min") {
          onSnooze()
        }
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.45))
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(.white.opacity(0.08), lineWidth: 1)
        )
      }
      .frame(maxWidth: .infinity)
    }
    .padding(20)
  }
}
