import SwiftUI
import Combine

struct ActiveStateView: View {
  let goal: String
  let startTime: Date
  let distractions: Int
  let sessionsToday: Int
  let totalFocusTime: TimeInterval
  let onEndSession: () -> Void

  @State private var now: Date = Date()
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  private var elapsed: TimeInterval {
    now.timeIntervalSince(startTime)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Sonar + status header
      HStack(spacing: 8) {
        AnimatedSonarPingView(stateColor: StateColor.activeGreen())
        Text("WATCHING · SESSION ACTIVE")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(StateColor.activeGreen())
      }

      // Goal chip
      HStack(spacing: 6) {
        Circle()
          .fill(StateColor.activeGreen())
          .frame(width: 5, height: 5)
        Text(goal)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.8))
          .lineLimit(1...3)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.white.opacity(0.05))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(.white.opacity(0.08), lineWidth: 1)
      )

      // Timer display
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(formattedElapsed)
          .font(.system(size: 36, weight: .light))
          .kerning(-0.36)
          .foregroundColor(.white)
          .monospacedDigit()

        Text("elapsed")
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.3))
      }

      // Stat chips
      HStack(spacing: 8) {
        statChip(
          value: "\(distractions)",
          key: "distractions",
          tint: distractions == 0 ? StateColor.activeGreen() : StateColor.detectionRed()
        )
        statChip(value: "\(sessionsToday)", key: "sessions today")
        statChip(value: formattedTotalTime, key: "total focus")
      }

      // End session button
      Button("End session") {
        onEndSession()
      }
      .buttonStyle(DangerButtonStyle())
    }
    .padding(20)
    .onReceive(timer) { date in
      now = date
    }
  }

  private var formattedElapsed: String {
    let hours = Int(elapsed) / 3600
    let minutes = (Int(elapsed) % 3600) / 60
    let seconds = Int(elapsed) % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private var formattedTotalTime: String {
    let total = totalFocusTime + elapsed
    let hours = Int(total) / 3600
    let minutes = (Int(total) % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  private func statChip(value: String, key: String, tint: Color = .white) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(tint.opacity(0.8))
      Text(key)
        .font(.system(size: 10))
        .foregroundColor(.white.opacity(0.28))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(.white.opacity(0.04))
    .cornerRadius(10)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(.white.opacity(0.07), lineWidth: 1)
    )
  }
}
