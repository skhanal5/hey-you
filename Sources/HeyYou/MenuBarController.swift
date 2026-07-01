import AppKit
import SwiftUI

struct DetectionCycle {
  var firstDetectedAt: Date?
  var fireCount: Int = 0

  mutating func ensureFirstDetectedAt() {
    guard firstDetectedAt == nil else { return }
    firstDetectedAt = Date()
  }

  mutating func incrementFireCount() {
    fireCount += 1
  }

  mutating func reset() {
    firstDetectedAt = nil
    fireCount = 0
  }
}

final class MenuBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var popover: NSPopover!
  private let popoverViewModel = PopoverViewModel()

  private let sessionManager: SessionManager
  private let dictationService: DictationService
  private let triggerEngine: TriggerEngine
  private let interventionService: InterventionService
  private let openRouter: OpenRouterClient
  private let keychain: KeychainServiceProtocol

  private var state: MenuBarState = .idle {
    didSet { stateDidChange() }
  }

  private var animPhase: CGFloat = 0
  private var animTimer: Timer?
  private var lastFrameTime: Date?

  private var lastDetectedSite: String?
  private var lastTrackingStart: Date?
  private var detectionCycle = DetectionCycle()

  init(
    sessionManager: SessionManager,
    dictationService: DictationService,
    triggerEngine: TriggerEngine,
    interventionService: InterventionService,
    openRouter: OpenRouterClient,
    keychain: KeychainServiceProtocol
  ) {
    self.sessionManager = sessionManager
    self.dictationService = dictationService
    self.triggerEngine = triggerEngine
    self.interventionService = interventionService
    self.openRouter = openRouter
    self.keychain = keychain

    super.init()

    setupStatusItem()
    setupPopover()
    if keychain.read() == nil {
      popoverViewModel.state = .needsKey
    }
    updateIcon()
    observeActivation()
  }

  // MARK: - Status Item

  private func setupStatusItem() {
    guard let button = statusItem.button else { return }
    button.image = MenuBarIcon.make(iconState: AppIconState(from: state), animPhase: animPhase)
    button.imagePosition = .imageLeft
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    button.target = self
    button.action = #selector(handleStatusItemClick)
  }

  @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }
    if event.type == .rightMouseUp {
      showContextMenu(sender)
    } else {
      togglePopover(sender)
    }
  }

  // MARK: - Context Menu (right-click)

  private func showContextMenu(_ sender: NSView) {
    let menu = NSMenu()
    let prefsItem = NSMenuItem(
      title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
    prefsItem.target = self
    menu.addItem(prefsItem)
    menu.addItem(.separator())
    let quitItem = NSMenuItem(
      title: "Quit HeyYou", action: #selector(quit), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
    menu.popUp(positioning: nil, at: .zero, in: sender)
  }

  // MARK: - Popover

  private func setupPopover() {
    popover = NSPopover()
    popover.contentSize = NSSize(width: 300, height: 0)
    popover.behavior = .semitransient

    let contentView = PopoverContentView(
      viewModel: popoverViewModel,
      onStartListening: { [weak self] in self?.startListeningFromPopover() },
      onStopListening: { [weak self] in self?.dictationService.stopListening() },
      onConfirmGoal: { [weak self] goal in self?.confirmSession(goal: goal) },
      onDismissIdle: { [weak self] in self?.popover.performClose(nil) },
      onOpenSettings: { [weak self] in self?.openMicrophoneSettings() },
      onSaveApiKey: { [weak self] key in self?.saveApiKey(key) },
      onEndSession: { [weak self] in self?.endSession() },
      onDismissDetection: { [weak self] in self?.dismissDetection() },
      onBackToWork: { [weak self] in self?.dismissDetection() },
      onSnooze: { [weak self] in self?.snoozeDetection() }
    )

    popover.contentViewController = NSHostingController(rootView: contentView)
  }

  private func togglePopover(_ sender: NSView) {
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
      // Force the popover to become key immediately
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  private func observeActivation() {
    NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self, self.popover.isShown else { return }
      self.popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }
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
  }

  private func computeElapsedMinutes() -> Int {
    guard let start = lastTrackingStart else { return 0 }
    return Int(Date().timeIntervalSince(start) / 60)
  }

  // MARK: - Popover State (explicit, not synced from MenuBarState)

  private func setPopoverActive() {
    let goals = sessionManager.currentSession?.goals ?? ""
    let triggers = sessionManager.currentSession?.triggerCount ?? 0
    popoverViewModel.state = .active(
      goal: goals,
      startTime: sessionManager.currentSession?.startTime ?? Date(),
      distractions: triggers
    )
    popoverViewModel.sessionsToday = sessionManager.sessionsToday
    popoverViewModel.totalFocusTime = sessionManager.totalFocusTimeToday
  }

  private func setPopoverIdle() {
    popoverViewModel.state = .idle
  }

  func ensureFirstDetectedAt() {
    detectionCycle.ensureFirstDetectedAt()
  }

  func incrementFireCount() {
    detectionCycle.incrementFireCount()
  }

  func resetDetectionCycle() {
    detectionCycle.reset()
  }

  private func setPopoverDetection() {
    let goals = sessionManager.currentSession?.goals ?? ""
    let site = lastDetectedSite ?? "Unknown"
    let elapsed: Int
    if let first = detectionCycle.firstDetectedAt {
      elapsed = Int(Date().timeIntervalSince(first) / 60)
    } else {
      elapsed = 0
    }
    popoverViewModel.state = .detection(
      goal: goals,
      site: site,
      fireCount: detectionCycle.fireCount,
      elapsedMinutes: elapsed
    )
    popoverViewModel.sessionsToday = sessionManager.sessionsToday
    popoverViewModel.totalFocusTime = sessionManager.totalFocusTimeToday
  }

  // MARK: - Popover Actions

  private func startListeningFromPopover() {
    popoverViewModel.startListening()
    Task {
      do {
        _ = try await dictationService.startListening { [weak self] text in
          Task { @MainActor in
            self?.popoverViewModel.liveTranscription = text
          }
        }
      } catch {
        await MainActor.run {
          self.popoverViewModel.handleListeningError(error)
        }
      }
    }
  }

  private func confirmSession(goal: String) {
    guard !goal.isEmpty else {
      popoverViewModel.idleError = "No goal detected — try again"
      return
    }
    guard keychain.read() != nil else {
      popoverViewModel.idleError = "Configure an API key in Preferences before starting a session."
      return
    }
    sessionManager.startSession(goals: goal)
    state = .active(goals: goal, triggers: 0)
    setPopoverActive()
    print("[HeyYou] Session started: \(goal)")
  }

  private func openMicrophoneSettings() {
    NSWorkspace.shared.open(
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
    )
  }

  private func dismissDetection() {
    interventionService.stop()
    let goals = sessionManager.currentSession?.goals ?? ""
    let triggers = sessionManager.currentSession?.triggerCount ?? 0
    state = .active(goals: goals, triggers: triggers)
    setPopoverActive()
    popover.performClose(nil)
  }

  private func snoozeDetection() {
    sessionManager.snoozeUntil = Date().addingTimeInterval(300)
    dismissDetection()
  }

  // MARK: - State (called from AppDelegate)

  func setDetecting(_ detecting: Bool) {
    state = state.settingDetecting(detecting)
  }

  func setSpeaking(_ speaking: Bool) {
    state = state.settingSpeaking(speaking)
  }

  /// Store detection context when a trigger fires
  func updateDetectionContext(site: String, trackingStart: Date?) {
    lastDetectedSite = site
    lastTrackingStart = trackingStart
  }

  private func saveApiKey(_ key: String) {
    guard keychain.save(key: key) else {
      popoverViewModel.idleError = "Failed to save API key"
      return
    }
    popoverViewModel.state = .idle
  }

  func refreshApiKeyState() {
    if keychain.read() != nil, case .needsKey = popoverViewModel.state {
      popoverViewModel.state = .idle
    } else if keychain.read() == nil, case .idle = popoverViewModel.state {
      popoverViewModel.state = .needsKey
    }
  }

  /// Show the detection state in the popover when a trigger fires
  func showDetectionPopover() {
    setPopoverDetection()

    guard let button = statusItem.button else { return }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.orderFrontRegardless()
    popover.contentViewController?.view.window?.makeKey()
  }

  // MARK: - Actions (called from popover or programmatically)

  @objc private func startSession() {
    guard keychain.read() != nil else {
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

  func endSession() {
    dictationService.cancel()
    sessionManager.endSession()
    triggerEngine.reset()
    state = .idle
    setPopoverIdle()
    print("[HeyYou] Session ended")
  }

  // MARK: - Preferences

  private var preferencesController: PreferencesWindowController?

  @objc private func showPreferences() {
    if preferencesController == nil {
      preferencesController = PreferencesWindowController(
        keychain: keychain,
        onKeyChanged: { [weak self] in self?.refreshApiKeyState() }
      )
    }
    preferencesController?.show()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }
}
