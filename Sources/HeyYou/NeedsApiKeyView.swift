import SwiftUI

struct NeedsApiKeyView: View {
  let onOpenPreferences: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      HStack(spacing: 8) {
        SonarPingView(stateColor: StateColor.idleTranslucent())
        Text("IDLE · NOT WATCHING")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(.white.opacity(0.25))
      }

      VStack(spacing: 8) {
        Text("No API Key")
          .font(.system(size: 19, weight: .semibold))
          .kerning(-0.19)
          .foregroundColor(.white)

        Text("Set up an OpenRouter API key in Preferences\nto start tracking your focus.")
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(.white.opacity(0.5))
          .multilineTextAlignment(.center)
          .lineSpacing(4)
      }

      Button("Open Preferences") {
        onOpenPreferences()
      }
      .buttonStyle(PrimaryButtonStyle(isEnabled: true))
      .padding(.top, 4)
    }
    .padding(20)
  }
}
