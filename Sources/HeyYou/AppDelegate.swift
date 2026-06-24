import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
    private lazy var dotWindow = DotWindow()
    private let sessionManager = SessionManager()
    private let dictationService = DictationService()
    private lazy var triggerEngine = TriggerEngine(sessionManager: sessionManager)
    private let interventionService = InterventionService()
    private let dotView: DotView = {
        let size: CGFloat = 16
        return DotView(frame: NSRect(origin: .zero, size: NSSize(width: size, height: size)))
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDotView()
        setupTriggerEngine()
        dotWindow.orderFront(nil)

        monitor.onAppChange = { [weak self] app in
            guard let self else { return }
            let classification = self.detector.classify(app)
            self.triggerEngine.classificationDidChange(classification)
        }
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func setupDotView() {
        dotView.onStartSession = { [weak self] in
            self?.startSession()
        }
        dotView.onEndSession = { [weak self] in
            self?.endSession()
        }
        dotView.isSessionActive = false
        dotWindow.replaceContent(with: dotView)
    }

    private func setupTriggerEngine() {
        triggerEngine.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .focused:
                self.dotView.color = .systemGreen
                self.dotView.isCancelling = false
                self.interventionService.stop()
            case .tracking:
                self.dotView.color = .systemRed
                self.dotView.isCancelling = false
            case .pending:
                self.dotView.isCancelling = true
            case .triggered:
                self.dotView.color = .systemRed
                self.dotView.isCancelling = false
            }
        }
        triggerEngine.onTrigger = { [weak self] sig in
            guard let self else { return }
            let message = self.buildMessage(for: sig)
            self.interventionService.speak(message)
        }
    }

    private func buildMessage(for sig: DoomscrollSignature) -> String {
        let count = sessionManager.currentSession?.triggerCount ?? 0
        let goals = sessionManager.currentSession?.goals

        if count <= 1, let goals {
            return "Hey you. You said you wanted to \(goals), but you're on \(sig.name)."
        } else if count <= 1 {
            return "Hey you. You're on \(sig.name). Should you be doing something else?"
        } else if let goals {
            return "Hey you. That's the \(ordinal(count)) time. Remember: \(goals)."
        } else {
            return "Hey you. That's the \(ordinal(count)) time on \(sig.name) today."
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
        let mod100 = n % 100
        let suffix: String
        if 11 <= mod100 && mod100 <= 13 {
            suffix = "th"
        } else {
            suffix = suffixes[n % 10]
        }
        return "\(n)\(suffix)"
    }

    private func startSession() {
        dotView.isListening = true
        Task {
            let goals: String
            do {
                goals = try await dictationService.transcribe(duration: 8)
            } catch {
                goals = "Unspecified"
            }
            await MainActor.run {
                sessionManager.startSession(goals: goals)
                dotView.isListening = false
                dotView.isSessionActive = true
                print("[HeyYou] Session started: \(goals)")
            }
        }
    }

    private func endSession() {
        dictationService.cancel()
        sessionManager.endSession()
        triggerEngine.reset()
        dotView.isListening = false
        dotView.isSessionActive = false
        dotView.color = .systemGreen
        print("[HeyYou] Session ended")
    }
}
