import SwiftUI

struct SonarPingView: View {
  let stateColor: Color

  var body: some View {
    ZStack {
      Circle()
        .stroke(stateColor.opacity(0.12), lineWidth: 1.5)
        .frame(width: 26, height: 26)

      Circle()
        .stroke(stateColor.opacity(0.35), lineWidth: 1.5)
        .frame(width: 18, height: 18)

      Circle()
        .stroke(stateColor.opacity(0.9), lineWidth: 1.5)
        .frame(width: 10, height: 10)
    }
    .frame(width: 28, height: 28)
  }
}

struct AnimatedSonarPingView: View {
  let stateColor: Color
  @State private var animScale: CGFloat = 1.0
  @State private var animOpacity: Double = 0.35

  var body: some View {
    ZStack {
      Circle()
        .stroke(stateColor.opacity(0.12), lineWidth: 1.5)
        .frame(width: 26, height: 26)

      Circle()
        .stroke(stateColor.opacity(animOpacity), lineWidth: 1.5)
        .frame(width: 18 * animScale, height: 18 * animScale)

      Circle()
        .stroke(stateColor.opacity(0.9), lineWidth: 1.5)
        .frame(width: 10, height: 10)
    }
    .frame(width: 28, height: 28)
    .onAppear {
      withAnimation(
        .easeOut(duration: 2).repeatForever(autoreverses: false)
      ) {
        animScale = 1.6
        animOpacity = 0
      }
    }
  }
}

enum StateColor {
  static func idleTranslucent() -> Color {
    .white.opacity(0.25)
  }

  static func activeGreen() -> Color {
    Color(red: 0.29, green: 0.87, blue: 0.50) // #4ade80
  }

  static func detectionRed() -> Color {
    Color(red: 0.98, green: 0.44, blue: 0.52) // #fb7185
  }
}
