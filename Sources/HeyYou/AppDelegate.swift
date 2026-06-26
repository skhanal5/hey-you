import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
    private let sessionManager = SessionManager()
    private let dictationService = DictationService()
    private lazy var triggerEngine = TriggerEngine(sessionManager: sessionManager)
    private let interventionService = InterventionService()
    private lazy var openRouter = OpenRouterClient(keyProvider: { KeychainService.read() })
    private var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()

        menuBarController = MenuBarController(
            sessionManager: sessionManager,
            dictationService: dictationService,
            triggerEngine: triggerEngine,
            interventionService: interventionService,
            openRouter: openRouter
        )

        setupTriggerEngine()

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

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupTriggerEngine() {
        triggerEngine.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .focused:
                self.interventionService.stop()
                self.menuBarController.setDetecting(false)
            case .tracking:
                self.menuBarController.setDetecting(true)
            case .pending:
                self.menuBarController.setDetecting(true)
            case .triggered:
                self.menuBarController.setDetecting(true)
            }
        }
        triggerEngine.onTrigger = { [weak self] sig in
            guard let self else { return }
            let count = sessionManager.currentSession?.triggerCount ?? 0
            let goals = sessionManager.currentSession?.goals
            let prompt = PromptBuilder.buildPrompt(for: sig, triggerCount: count, goals: goals)
            Task {
                let message: String
                if KeychainService.read() != nil, let llm = try? await self.openRouter.generate(prompt: prompt) {
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
