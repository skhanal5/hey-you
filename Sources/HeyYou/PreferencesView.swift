import SwiftUI
import Speech
import AppKit

struct PreferencesView: View {
  @State private var apiKey: String = ""
  @State private var micStatus = "Checking..."
  @State private var errorMessage: String? = nil
  @State private var hasLoadedKey = false
  let keyProvider: () -> String?
  let onSave: (String) -> Bool
  let onRemove: () -> Void
  let onClose: () -> Void
  let onDidReadKey: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Connection")
        .font(.headline)

      HStack {
        Text("API Key:")
          .frame(width: 80, alignment: .trailing)
        SecureField("sk-or-...", text: $apiKey)
          .textFieldStyle(.roundedBorder)
      }

      if let error = errorMessage {
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }

      HStack {
        Button("Remove Key", role: .destructive) {
          onRemove()
          apiKey = ""
          errorMessage = nil
        }
        .disabled(apiKey.isEmpty)

        Spacer()

        Button("Save") {
          let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !key.isEmpty else {
            errorMessage = "API key cannot be empty"
            return
          }
          if onSave(key) {
            errorMessage = nil
            onClose()
          } else {
            errorMessage = "Failed to save API key to Keychain"
          }
        }
        .keyboardShortcut(.defaultAction)
      }

      Divider()
        .padding(.vertical, 4)

      Text("Microphone")
        .font(.headline)

      HStack {
        Text("Status:")
          .frame(width: 80, alignment: .trailing)
        Text(micStatus)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button("Grant Permission") {
          grantMicPermission()
        }
      }

      Spacer()

      HStack {
        Spacer()
        Button("Cancel") { onClose() }
          .keyboardShortcut(.cancelAction)
      }
    }
    .padding(20)
    .frame(width: 400, height: 280)
    .onAppear {
      guard !hasLoadedKey else { return }
      hasLoadedKey = true
      micStatus = micPermissionStatus()
      let key = keyProvider()
      if apiKey.isEmpty {
        apiKey = key ?? ""
      }
      onDidReadKey?()
    }
  }

  private func grantMicPermission() {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        micStatus = micPermissionStatus(for: status)
      }
    }
  }

  private func micPermissionStatus(for status: SFSpeechRecognizerAuthorizationStatus? = nil) -> String {
    let actual = status ?? SFSpeechRecognizer.authorizationStatus()
    switch actual {
    case .authorized: return "Authorized"
    case .denied: return "Denied"
    case .restricted: return "Restricted"
    case .notDetermined: return "Not determined"
    @unknown default: return "Unknown"
    }
  }
}
