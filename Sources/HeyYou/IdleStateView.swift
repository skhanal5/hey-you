import SwiftUI

struct IdleStateView: View {
  @ObservedObject var viewModel: PopoverViewModel
  let onStartListening: () -> Void
  let onStopListening: () -> String?
  let onConfirmGoal: (String) -> Void
  let onDismiss: () -> Void
  let onOpenSettings: () -> Void

  private static let maxGoalLength = 55
  private static let overLimitError = "Goal too long (max \(Self.maxGoalLength) characters)"
  private static let noSpeechError = "No speech detected — try again"

  @State private var goalText = ""
  @State private var recordingError: String?

  private var isOverLimit: Bool {
    PopoverViewModel.isOverLimit(goalText, maxLength: Self.maxGoalLength)
  }

  private var canConfirm: Bool {
    PopoverViewModel.canConfirm(goalText: goalText, hasError: recordingError != nil, maxLength: Self.maxGoalLength)
  }

  private var isRecording: Bool { viewModel.isListening }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      headerSection

      if let error = viewModel.idleError {
        errorContent(error)
      } else {
        if let error = recordingError {
          errorText(error)
            .padding(.bottom, 4)
        } else if isOverLimit {
          errorText(Self.overLimitError)
            .padding(.bottom, 4)
        }
        inputSection
      }

      bottomBar
        .padding(.top, 12)
    }
    .padding(20)
  }

  // MARK: - Header

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        SonarPingView(stateColor: StateColor.idleTranslucent())
        Text("IDLE · NOT WATCHING")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(.white.opacity(0.25))
      }

      Text("What are you here to do?")
        .font(.system(size: 19, weight: .semibold))
        .kerning(-0.19)
        .foregroundColor(.white)

      Text("Give me something to hold you to.")
        .font(.system(size: 13, weight: .regular).italic())
        .foregroundColor(.white.opacity(0.38))
    }
    .padding(.bottom, 8)
  }

  // MARK: - Input

  private var inputSection: some View {
    HStack(spacing: 8) {
      TextField("Finish the project proposal…", text: $goalText)
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
        .disabled(isRecording)
        .onChange(of: goalText) { _ in
          guard !isRecording else { return }
          recordingError = nil
          viewModel.idleError = nil
        }
        .onReceive(viewModel.$liveTranscription) { text in
          guard isRecording else { return }
          if text.count > Self.maxGoalLength {
            goalText = String(text.prefix(Self.maxGoalLength))
            recordingError = Self.overLimitError
          } else {
            goalText = text
            recordingError = nil
          }
        }

      micButton
    }
  }

  private var micButton: some View {
    Button(action: toggleRecording) {
      Circle()
        .fill(isRecording ? Color.red.opacity(0.15) : .white.opacity(0.06))
        .overlay(
          Circle()
            .stroke(isRecording ? Color.red.opacity(0.3) : .white.opacity(0.08), lineWidth: 1)
        )
        .overlay(
          Image(systemName: isRecording ? "stop.fill" : "mic.fill")
            .font(.system(size: 16))
            .foregroundColor(isRecording ? .red : .white.opacity(0.7))
        )
        .frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Error

  private func errorContent(_ message: String) -> some View {
    VStack(spacing: 12) {
      Text(message)
        .font(.system(size: 12))
        .foregroundColor(.white.opacity(0.6))
        .multilineTextAlignment(.center)

      if message == viewModel.micPermissionDeniedMessage {
        Button("Open System Settings") {
          onOpenSettings()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(StateColor.activeGreen())
      }

      Button("Try again") {
        withAnimation { viewModel.idleError = nil }
      }
      .font(.system(size: 12))
      .foregroundColor(.white.opacity(0.4))
    }
    .frame(maxWidth: .infinity)
  }

  private func errorText(_ message: String) -> some View {
    Text(message)
      .font(.system(size: 12))
      .foregroundColor(.red.opacity(0.8))
      .transition(.opacity)
  }

  // MARK: - Bottom Bar

  private var bottomBar: some View {
    HStack(spacing: 8) {
      Button("Not now") {
        if isRecording {
          _ = onStopListening()
        }
        goalText = ""
        viewModel.liveTranscription = ""
        viewModel.isListening = false
        viewModel.idleError = nil
        onDismiss()
      }
      .buttonStyle(GhostButtonStyle())

      Button("Confirm") {
        onConfirmGoal(goalText)
      }
      .buttonStyle(PrimaryButtonStyle(isEnabled: canConfirm))
      .disabled(!canConfirm)
    }
  }

  // MARK: - Actions

  private func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }

  private func startRecording() {
    recordingError = nil
    viewModel.liveTranscription = ""
    viewModel.idleError = nil
    goalText = ""
    onStartListening()
  }

  private func stopRecording() {
    let result = onStopListening()
    viewModel.isListening = false
    if let text = result, !text.isEmpty {
      goalText = text
    } else if !viewModel.liveTranscription.isEmpty {
      goalText = viewModel.liveTranscription
    } else {
      recordingError = Self.noSpeechError
    }
  }
}
