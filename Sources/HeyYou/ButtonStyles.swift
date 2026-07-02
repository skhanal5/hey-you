import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  let isEnabled: Bool
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(isEnabled ? .white.opacity(0.95) : .white.opacity(0.4))
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .background(
        Capsule()
          .fill(
            isEnabled
              ? (isHovering ? StateColor.activeGreen().opacity(0.85) : StateColor.activeGreen())
              : StateColor.activeGreen().opacity(0.25)
          )
      )
      .animation(.easeInOut(duration: 0.2), value: isEnabled)
      .animation(.easeInOut(duration: 0.15), value: isHovering)
      .onHover { hovering in
        guard isEnabled else { return }
        isHovering = hovering
      }
  }
}

struct GhostButtonStyle: ButtonStyle {
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .medium))
      .foregroundColor(isHovering ? Color.white.opacity(0.6) : Color.white.opacity(0.45))
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .background(
        Capsule()
          .fill(isHovering ? Color.white.opacity(0.10) : Color.white.opacity(0.06))
          .overlay(
            Capsule()
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
      )
      .animation(.easeInOut(duration: 0.15), value: isHovering)
      .onHover { hovering in isHovering = hovering }
  }
}

struct DangerButtonStyle: ButtonStyle {
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(.white.opacity(0.95))
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .background(
        Capsule()
          .fill(
            isHovering
              ? StateColor.detectionRed().opacity(0.85)
              : StateColor.detectionRed()
          )
      )
      .animation(.easeInOut(duration: 0.15), value: isHovering)
      .onHover { hovering in isHovering = hovering }
  }
}
