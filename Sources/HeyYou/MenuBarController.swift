import AppKit

final class MenuBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var menu = NSMenu()

  private let sessionManager: SessionManager
  private let dictationService: DictationService
  private let triggerEngine: TriggerEngine
  private let interventionService: InterventionService
  private let openRouter: OpenRouterClient

  private var state: MenuBarState = .idle {
    didSet { stateDidChange() }
  }

  private var animPhase: CGFloat = 0
  private var animTimer: Timer?
  private var lastFrameTime: Date?

  init(
    sessionManager: SessionManager,
    dictationService: DictationService,
    triggerEngine: TriggerEngine,
    interventionService: InterventionService,
    openRouter: OpenRouterClient
  ) {
    self.sessionManager = sessionManager
    self.dictationService = dictationService
    self.triggerEngine = triggerEngine
    self.interventionService = interventionService
    self.openRouter = openRouter

    super.init()

    setupStatusItem()
    rebuildMenu()
    updateIcon()
  }

  // MARK: - Status Item

  private func setupStatusItem() {
    if let button = statusItem.button {
      button.image = MenuBarIcon.make(iconState: AppIconState(from: state), animPhase: animPhase)
      button.imagePosition = .imageLeft
    }
  }

  private func rebuildMenu() {
    menu = NSMenu()

    let stateItem = NSMenuItem(title: stateLabel(), action: nil, keyEquivalent: "")
    stateItem.isEnabled = false
    menu.addItem(stateItem)

    menu.addItem(.separator())

    switch state {
    case .listening:
      let stopItem = NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "")
      stopItem.target = self
      menu.addItem(stopItem)
    case .active, .detecting, .speaking:
      let goalItem = NSMenuItem(title: "Set Goal", action: #selector(setGoal), keyEquivalent: "g")
      goalItem.target = self
      menu.addItem(goalItem)

      let endItem = NSMenuItem(title: "End Session", action: #selector(endSession), keyEquivalent: "e")
      endItem.target = self
      menu.addItem(endItem)
    case .idle:
      let startItem = NSMenuItem(title: "Start Session", action: #selector(startSession), keyEquivalent: "s")
      startItem.target = self
      menu.addItem(startItem)
    }

    menu.addItem(.separator())

    let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
    prefsItem.target = self
    menu.addItem(prefsItem)

    menu.addItem(.separator())

    let quitItem = NSMenuItem(title: "Quit HeyYou", action: #selector(quit), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
  }

  // MARK: - Icon

  private func updateIcon() {
    statusItem.button?.image = MenuBarIcon.make(iconState: AppIconState(from: state), animPhase: animPhase)
  }

  // MARK: - Animation

  private func updateAnimationTimer() {
    animTimer?.invalidate()
    animTimer = nil
    animPhase = 0
    lastFrameTime = Date()

    switch AppIconState(from: state) {
    case .idle, .detecting:
      updateIcon()
    case .listening, .active:
      let interval: TimeInterval = 1.0 / 30
      lastFrameTime = Date()
      animTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
        guard let self else { return }
        let now = Date()
        let elapsed = now.timeIntervalSince(self.lastFrameTime ?? now)
        self.lastFrameTime = now
        self.animPhase += elapsed
        self.updateIcon()
      }
      RunLoop.main.add(animTimer!, forMode: .common)
    }
  }

  private func stateDidChange() {
    updateAnimationTimer()
    rebuildMenu()
  }

  // MARK: - State

  private func stateLabel() -> String {
    switch state {
    case .idle:
      return "Idle — no active session"
    case .listening:
      return "Listening to your goal..."
    case .active(let goals, let triggers):
      return "Session active — \(triggers) triggers\nGoal: \(goals)"
    case .detecting:
      return "Hey! Focus."
    case .speaking:
      return "Speaking..."
    }
  }

  func setDetecting(_ detecting: Bool) {
    state = state.settingDetecting(detecting)
  }

  func setSpeaking(_ speaking: Bool) {
    state = state.settingSpeaking(speaking)
  }

  // MARK: - Actions

  @objc private func startSession() {
    guard KeychainService.read() != nil else {
      showPreferences()
      return
    }
    state = .listening
    Task {
      do {
        try await dictationService.startRecording()
      } catch {
        await MainActor.run {
          self.state = .idle
        }
      }
    }
  }

  @objc private func stopRecording() {
    Task {
      let goals: String
      do {
        goals = try await dictationService.stopRecording()
      } catch {
        goals = "Unspecified"
      }
      await MainActor.run {
        self.sessionManager.startSession(goals: goals)
        self.state = .active(goals: goals, triggers: 0)
        print("[HeyYou] Session started: \(goals)")
      }
    }
  }

  @objc private func setGoal() {
    state = .listening
    Task {
      do {
        try await dictationService.startRecording()
      } catch {
        await MainActor.run {
          let goals = self.sessionManager.currentSession?.goals ?? ""
          let triggers = self.sessionManager.currentSession?.triggerCount ?? 0
          self.state = .active(goals: goals, triggers: triggers)
        }
      }
    }
  }

  @objc private func endSession() {
    dictationService.cancel()
    sessionManager.endSession()
    triggerEngine.reset()
    state = .idle
    print("[HeyYou] Session ended")
  }

  // MARK: - Preferences

  private var preferencesController: PreferencesWindowController?

  @objc private func showPreferences() {
    if preferencesController == nil {
      preferencesController = PreferencesWindowController()
    }
    preferencesController?.show()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }
}
