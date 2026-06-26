@preconcurrency import Speech
@preconcurrency import AVFoundation

final class DictationService {
    enum Error: Swift.Error {
        case unauthorized
        case noRecognizer
        case recognitionFailed(Swift.Error)
        case notRecording
    }

    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var transcriptionContinuation: CheckedContinuation<String, Swift.Error>?
    private var bestTranscription = ""

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startRecording() async throws {
        guard await requestAuthorization() else { throw Error.unauthorized }
        guard let recognizer, recognizer.isAvailable else { throw Error.noRecognizer }

        bestTranscription = ""

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

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

        if let state = recognitionTask?.state, state == .completed || state == .canceling || state == .finishing {
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

    private func cleanup() {
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }

    func cancel() {
        recognitionTask?.cancel()
        cleanup()
        transcriptionContinuation?.resume(throwing: Error.notRecording)
        transcriptionContinuation = nil
    }
}
