@preconcurrency import Speech
@preconcurrency import AVFoundation

final class DictationService {
  enum Error: Swift.Error, Equatable {
    case microphonePermissionDenied
    case recognitionUnavailable
    case recognitionFailed(Swift.Error)
    case notRecording
    case cancelled

    static func == (lhs: Error, rhs: Error) -> Bool {
      switch (lhs, rhs) {
      case (.microphonePermissionDenied, .microphonePermissionDenied),
        (.recognitionUnavailable, .recognitionUnavailable),
        (.notRecording, .notRecording),
        (.cancelled, .cancelled):
        return true
      case (.recognitionFailed(let l), .recognitionFailed(let r)):
        return (l as NSError).domain == (r as NSError).domain
          && (l as NSError).code == (r as NSError).code
      default:
        return false
      }
    }
  }

  private let recognizer: SFSpeechRecognizer?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine: AVAudioEngine?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var transcriptionContinuation: CheckedContinuation<String, Swift.Error>?
  private var bestTranscription = ""

  // Streaming state
  private var isStreaming = false
  private var streamingContinuation: CheckedContinuation<String, Swift.Error>?
  private var partialResultCallback: ((String) -> Void)?

  init(locale: Locale = .current) {
    recognizer = SFSpeechRecognizer(locale: locale)
  }

  // MARK: - Authorization

  func requestAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }

  // MARK: - Original API (Set Goal flow)

  func startRecording() async throws {
    guard await requestAuthorization() else { throw Error.microphonePermissionDenied }
    guard let recognizer, recognizer.isAvailable else { throw Error.recognitionUnavailable }

    bestTranscription = ""

    let engine = AVAudioEngine()
    let inputNode = engine.inputNode
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true

    recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
      if let result {
        self?.bestTranscription = result.bestTranscription.formattedString
        if result.isFinal {
          self?.transcriptionContinuation?.resume(returning: result.bestTranscription.formattedString)
          self?.transcriptionContinuation = nil
          self?.cleanup()
        }
      }
      if let error {
        self?.transcriptionContinuation?.resume(throwing: Error.recognitionFailed(error))
        self?.transcriptionContinuation = nil
        self?.cleanup()
      }
    }

    let format = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }

    engine.prepare()
    try engine.start()

    audioEngine = engine
    recognitionRequest = request
  }

  func stopRecording() async throws -> String {
    guard let engine = audioEngine, let request = recognitionRequest else {
      throw Error.notRecording
    }

    if let state = recognitionTask?.state,
      state == .completed || state == .canceling || state == .finishing
    {
      cleanup()
      return bestTranscription
    }

    return try await withCheckedThrowingContinuation { continuation in
      transcriptionContinuation = continuation
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
      request.endAudio()
    }
  }

  // MARK: - Streaming API (Idle mic flow)

  func startListening(
    onPartialResult: @escaping (String) -> Void
  ) async throws -> String {
    cleanup()

    let authorized = await requestAuthorization()
    guard authorized else { throw Error.microphonePermissionDenied }
    guard let recognizer, recognizer.isAvailable else { throw Error.recognitionUnavailable }

    bestTranscription = ""
    partialResultCallback = onPartialResult
    isStreaming = true

    let engine = AVAudioEngine()
    let inputNode = engine.inputNode
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true

    audioEngine = engine
    recognitionRequest = request

    return try await withCheckedThrowingContinuation { continuation in
      streamingContinuation = continuation

      recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
        guard let self else { return }

        if let error {
          if recognitionTask?.state == .canceling || recognitionTask?.state == .finishing {
            return
          }
          streamingContinuation?.resume(throwing: Error.recognitionFailed(error))
          streamingContinuation = nil
          isStreaming = false
          cleanup()
          return
        }

        if let result {
          let text = result.bestTranscription.formattedString
          bestTranscription = text
          partialResultCallback?(text)

          if result.isFinal {
            streamingContinuation?.resume(returning: text)
            streamingContinuation = nil
            isStreaming = false
            cleanup()
          }
        }
      }

      let format = inputNode.outputFormat(forBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
        request.append(buffer)
      }

      do {
        engine.prepare()
        try engine.start()
      } catch {
        streamingContinuation?.resume(throwing: Error.recognitionFailed(error))
        streamingContinuation = nil
        isStreaming = false
        cleanup()
      }
    }
  }

  func stopListening() -> String? {
    guard isStreaming, let engine = audioEngine else { return nil }

    isStreaming = false

    let result = bestTranscription.isEmpty ? nil : bestTranscription

    engine.stop()
    engine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()

    let sc = streamingContinuation
    streamingContinuation = nil
    sc?.resume(returning: bestTranscription)

    cleanup()

    return result
  }

  // MARK: - Cancel / Cleanup

  func cancel() {
    if isStreaming {
      isStreaming = false
    }
    recognitionTask?.cancel()
    let tc = transcriptionContinuation
    transcriptionContinuation = nil
    tc?.resume(throwing: Error.notRecording)
    let sc = streamingContinuation
    streamingContinuation = nil
    sc?.resume(throwing: Error.cancelled)
    cleanup()
  }

  // MARK: - Private

  private func cleanup() {
    recognitionTask?.cancel()
    audioEngine = nil
    recognitionRequest = nil
    recognitionTask = nil
    partialResultCallback = nil
  }
}
