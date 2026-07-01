import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let monitor = AppMonitor()
  private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
  private let sessionManager = SessionManager()
  private let dictationService = DictationService()
  private let keychain = KeychainService()
  private lazy var triggerEngine = TriggerEngine(sessionManager: sessionManager)
  private let interventionService = InterventionService()
  private lazy var openRouter = OpenRouterClient(keychain: keychain)
  private var menuBarController: MenuBarController!

  private var trackingSignature: DoomscrollSignature?
  private var trackingStart: Date?

  func applicationDidFinishLaunching(_ notification: Notification) {
    menuBarController = MenuBarController(
      sessionManager: sessionManager,
      dictationService: dictationService,
      triggerEngine: triggerEngine,
      interventionService: interventionService,
      openRouter: openRouter,
      keychain: keychain
    )

    setupTriggerEngine()

    monitor.onAppChange = { [weak self] app in
      guard let self else { return }
      let classification = self.detector.classify(app)
      self.triggerEngine.classificationDidChange(classification)
    }
    monitor.start()

    // Eager keychain read at startup to avoid system prompt during trigger
    keychain.read()
  }

  func applicationWillTerminate(_ notification: Notification) {
    monitor.stop()
  }

  private func setupTriggerEngine() {
    triggerEngine.onStateChange = { [weak self] state in
      guard let self else { return }
      switch state {
      case .focused:
        self.interventionService.stop()
        self.menuBarController.setDetecting(false)
        self.menuBarController.resetDetectionCycle()
      case .tracking(let sig, let start):
        self.trackingSignature = sig
        self.trackingStart = start
        self.menuBarController.updateDetectionContext(site: sig.name, trackingStart: start)
        self.menuBarController.ensureFirstDetectedAt()
      case .triggered:
        self.menuBarController.setDetecting(true)
        self.menuBarController.incrementFireCount()
      }
    }

    triggerEngine.onTrigger = { [weak self] sig in
      guard let self else { return }
      let count = sessionManager.currentSession?.triggerCount ?? 0
      let goals = sessionManager.currentSession?.goals
      let prompt = PromptBuilder.buildPrompt(for: sig, triggerCount: count, goals: goals)

      self.menuBarController.showDetectionPopover()

      Task {
        let message: String
        if self.keychain.read() != nil,
          let llm = try? await self.openRouter.generate(prompt: prompt)
        {
          message = llm
        } else {
          message = PromptBuilder.fallbackMessage(for: sig, triggerCount: count, goals: goals)
        }
        await MainActor.run {
          self.interventionService.speak(message)
        }
      }
    }

    interventionService.onSpeakingChange = { [weak self] speaking in
      Task { @MainActor in
        self?.menuBarController.setSpeaking(speaking)
      }
    }
  }
}
