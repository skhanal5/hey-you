import Foundation
import Combine

final class PopoverViewModel: ObservableObject {
  @Published var state: SessionState = .idle
  @Published var liveTranscription: String = ""
  @Published var isListening: Bool = false
  @Published var idleError: String?
  @Published var showTextField: Bool = false

  // Session stats (set by MenuBarController)
  @Published var sessionsToday: Int = 0
  @Published var totalFocusTime: TimeInterval = 0

  let micPermissionDeniedMessage = "Microphone access is off. Enable it in System Settings → Privacy → Microphone."
  let recognitionErrorMessage = "Didn't catch that — try again"

  static func isOverLimit(_ text: String, maxLength: Int = 55) -> Bool {
    text.count > maxLength
  }

  static func canConfirm(goalText: String, hasError: Bool, maxLength: Int = 55) -> Bool {
    !goalText.isEmpty && !isOverLimit(goalText, maxLength: maxLength) && !hasError
  }

  func startListening() {
    idleError = nil
    isListening = true
    liveTranscription = ""
  }

  func confirmTranscription() {
    isListening = false
  }

  func handleListeningError(_ error: Error) {
    isListening = false
    if let dictationError = error as? DictationService.Error {
      switch dictationError {
      case .microphonePermissionDenied:
        idleError = micPermissionDeniedMessage
      case .recognitionUnavailable:
        showTextField = true
      case .recognitionFailed:
        idleError = recognitionErrorMessage
      case .notRecording, .cancelled:
        break
      }
    } else {
      idleError = recognitionErrorMessage
    }
  }
}
