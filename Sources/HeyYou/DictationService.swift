@preconcurrency import Speech
@preconcurrency import AVFoundation

final class DictationService {
    enum Error: Swift.Error {
        case unauthorized
        case noRecognizer
        case recognitionFailed(Swift.Error)
    }

    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?

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

    func transcribe(duration: TimeInterval) async throws -> String {
        guard await requestAuthorization() else { throw Error.unauthorized }
        guard let recognizer, recognizer.isAvailable else { throw Error.noRecognizer }

        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result {
                    self?.recognitionTask = nil
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if let error {
                    self?.recognitionTask = nil
                    continuation.resume(throwing: Error.recognitionFailed(error))
                }
            }

            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try? audioEngine.start()

            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                recognitionRequest.endAudio()
            }
        }
    }

    func cancel() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
