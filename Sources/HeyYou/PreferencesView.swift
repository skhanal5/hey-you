import SwiftUI
import Speech

struct PreferencesView: View {
  @State private var apiKey = ""
  @State private var micStatus = "Checking..."
  let onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("API Key:")
          .frame(width: 90, alignment: .trailing)
        TextField("sk-or-...", text: $apiKey)
          .textFieldStyle(.roundedBorder)
      }

      HStack {
        Text("Microphone:")
          .frame(width: 90, alignment: .trailing)
        Text(micStatus)
          .frame(width: 120, alignment: .leading)
        Button("Grant Permission...") {
          grantMicPermission()
        }
      }

      Spacer()

      HStack {
        Spacer()
        Button("Cancel") { onClose() }
        Button("Save") { save() }
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(20)
    .frame(width: 360, height: 200)
    .onAppear {
      apiKey = KeychainService.read() ?? ""
      micStatus = micPermissionStatus()
    }
  }

  private func save() {
    let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    if !key.isEmpty { KeychainService.save(key: key) }
    onClose()
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
