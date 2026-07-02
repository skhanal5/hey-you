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

  // Snooze countdown (live)
  @Published var snoozeRemaining: String = ""
  var onSnoozeEnd: (() -> Void)?

  let micPermissionDeniedMessage = "Microphone access is off. Enable it in System Settings → Privacy → Microphone."
  let recognitionErrorMessage = "Didn't catch that — try again"

  private var cancellables = Set<AnyCancellable>()

  init() {
    $state
      .dropFirst()
      .sink { [weak self] newState in
        self?.stateDidChange(to: newState)
      }
      .store(in: &cancellables)
  }

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

  func cancelSnooze() {
    onSnoozeEnd?()
  }

  // MARK: - Snooze Timer

  private var snoozeTimer: AnyCancellable?

  private func stateDidChange(to newState: SessionState) {
    if case .snoozed(let until, _) = newState {
      startSnoozeTimer(until: until)
    } else {
      stopSnoozeTimer()
    }
  }

  private func startSnoozeTimer(until: Date) {
    stopSnoozeTimer()
    snoozeTimer = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        guard let self else { return }
        let remaining = until.timeIntervalSince(now)
        if remaining <= 0 {
          self.snoozeRemaining = ""
          self.snoozeTimer?.cancel()
          self.onSnoozeEnd?()
          return
        }
        let m = Int(remaining) / 60
        let s = Int(remaining) % 60
        self.snoozeRemaining = String(format: "%d:%02d", m, s)
      }
  }

  private func stopSnoozeTimer() {
    snoozeTimer?.cancel()
    snoozeTimer = nil
    snoozeRemaining = ""
  }
}
