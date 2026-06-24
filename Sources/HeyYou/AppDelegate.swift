import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
    private lazy var dotWindow = DotWindow()
    private let sessionManager = SessionManager()
    private let dictationService = DictationService()
    private lazy var triggerEngine = TriggerEngine(sessionManager: sessionManager)
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
