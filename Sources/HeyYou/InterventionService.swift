import AppKit
import AVFoundation

final class InterventionService {
    private let synthesizer = AVSpeechSynthesizer()

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func speak(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
