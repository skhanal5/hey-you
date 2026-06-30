import SwiftUI

struct IdleStateView: View {
  @ObservedObject var viewModel: PopoverViewModel
  let onStartListening: () -> Void
  let onStopListening: () -> String?
  let onConfirmGoal: (String) -> Void
  let onDismiss: () -> Void
  let onTypeGoal: (String) -> Void
  let onOpenSettings: () -> Void

  @State private var typedGoal = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Sonar + status header
      HStack(spacing: 8) {
        if viewModel.isListening {
          AnimatedSonarPingView(stateColor: StateColor.idleTranslucent())
        } else {
          SonarPingView(stateColor: StateColor.idleTranslucent())
        }
        Text("IDLE · NOT WATCHING")
          .font(.system(size: 11, weight: .regular))
          .kerning(1)
          .foregroundColor(.white.opacity(0.25))
      }

      // Hero
      Text("What are you here to do?")
        .font(.system(size: 19, weight: .semibold))
        .kerning(-0.19)
        .foregroundColor(.white)

      Text("Give me something to hold you to.")
        .font(.system(size: 13, weight: .regular).italic())
        .foregroundColor(.white.opacity(0.38))

      // Voice input or text field
      if viewModel.showTextField {
        textFieldSection
      } else if viewModel.isListening {
        listeningSection
      } else if let error = viewModel.idleError {
        errorSection(error)
      } else {
        micButtonSection
      }

      // Action buttons
      if !viewModel.liveTranscription.isEmpty && !viewModel.isListening {
        actionButtons
      }
      if !typedGoal.isEmpty && viewModel.showTextField {
        actionButtonsTyped
      }
    }
    .padding(20)
  }

  // MARK: - Mic button (default state)

  private var micButtonSection: some View {
    VStack(spacing: 12) {
      Button(action: { viewModel.startListening(); onStartListening() }) {
        Circle()
          .fill(.white.opacity(0.06))
          .overlay(
            Circle()
              .stroke(.white.opacity(0.08), lineWidth: 1)
          )
          .overlay(
            Image(systemName: "mic.fill")
              .font(.system(size: 16))
              .foregroundColor(.white.opacity(0.7))
          )
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)

      Button("type instead") {
        withAnimation { viewModel.showTextField = true }
      }
      .font(.system(size: 12))
      .foregroundColor(.white.opacity(0.25))
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Listening state

  private var listeningSection: some View {
    VStack(spacing: 12) {
      Text(viewModel.liveTranscription.isEmpty ? "Listening..." : viewModel.liveTranscription)
        .font(.system(size: 13))
        .foregroundColor(viewModel.liveTranscription.isEmpty ? .white.opacity(0.3) : .white.opacity(0.7))
        .frame(maxWidth: .infinity, alignment: .center)
        .lineLimit(3)
        .multilineTextAlignment(.center)

      if !viewModel.liveTranscription.isEmpty {
        Button(action: { viewModel.confirmTranscription(); _ = onStopListening() }) {
          Text("Tap to confirm")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - Error state

  private func errorSection(_ message: String) -> some View {
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

  // MARK: - Text field (typed fallback)

  private var textFieldSection: some View {
    VStack(spacing: 12) {
      TextField("Finish the project proposal…", text: $typedGoal)
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
    }
  }

  // MARK: - Action buttons

  private var actionButtons: some View {
    VStack(spacing: 8) {
      Button("Start session") {
        onConfirmGoal(viewModel.liveTranscription)
      }
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
      .padding(.horizontal, 24)
      .padding(.vertical, 10)
      .background(.white)
      .clipShape(Capsule())

      Button("Not yet") {
        withAnimation { viewModel.isListening = false }
      }
      .font(.system(size: 12))
      .foregroundColor(.white.opacity(0.45))
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background(.white.opacity(0.06))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(.white.opacity(0.08), lineWidth: 1)
      )
    }
    .frame(maxWidth: .infinity)
  }

  private var actionButtonsTyped: some View {
    VStack(spacing: 8) {
      Button("Start session") {
        onTypeGoal(typedGoal)
      }
      .font(.system(size: 13, weight: .semibold))
      .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
      .padding(.horizontal, 24)
      .padding(.vertical, 10)
      .background(.white)
      .clipShape(Capsule())

      Button("Not yet") {
        onDismiss()
      }
      .font(.system(size: 12))
      .foregroundColor(.white.opacity(0.45))
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background(.white.opacity(0.06))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(.white.opacity(0.08), lineWidth: 1)
      )
    }
    .frame(maxWidth: .infinity)
  }
}
