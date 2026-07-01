import SwiftUI

struct NeedsApiKeyView: View {
  let onSave: (String) -> Void

  @State private var apiKey = ""
  @State private var errorMessage: String?

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

        Text("Set up an OpenRouter API key to\nstart tracking your focus.")
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(.white.opacity(0.5))
          .multilineTextAlignment(.center)
          .lineSpacing(4)
      }

      SecureField("sk-or-...", text: $apiKey)
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .foregroundColor(.white)
        .padding(12)
        .background(.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: apiKey) { _ in errorMessage = nil }

      if let error = errorMessage {
        Text(error)
          .font(.system(size: 11))
          .foregroundColor(.red.opacity(0.8))
      }

      Button("Save") {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
          errorMessage = "API key cannot be empty"
          return
        }
        onSave(key)
      }
      .buttonStyle(PrimaryButtonStyle(isEnabled: !apiKey.isEmpty))
      .disabled(apiKey.isEmpty)
    }
    .padding(20)
  }
}
