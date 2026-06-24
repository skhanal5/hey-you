import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
    private lazy var dotWindow = DotWindow()
    private let sessionManager = SessionManager()
    private let dictationService = DictationService()
    private let dotView: DotView = {
        let size: CGFloat = 16
        return DotView(frame: NSRect(origin: .zero, size: NSSize(width: size, height: size)))
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDotView()
        dotWindow.orderFront(nil)

        monitor.onAppChange = { [weak self] app in
            guard let self else { return }
            let classification = self.detector.classify(app)
            switch classification {
            case .productive:
                self.dotView.color = .systemGreen
            case .doomscroll:
                self.dotView.color = .systemRed
            }
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
        dotView.isListening = false
        dotView.isSessionActive = false
        dotView.color = .systemGreen
        print("[HeyYou] Session ended")
    }
}
