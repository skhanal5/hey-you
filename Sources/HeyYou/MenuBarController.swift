import AppKit
import Combine
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

    setupObservers()
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
    button.image = MenuBarIcon.make(iconState: AppIconState(from: popoverViewModel.state), animPhase: animPhase)
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

  private var keyMonitor: Any?

  private func setupPopover() {
    popover = NSPopover()
    popover.contentSize = NSSize(width: 300, height: 0)
    popover.behavior = .transient

    let contentView = PopoverContentView(
      viewModel: popoverViewModel,
      onStartListening: { [weak self] in self?.startListeningFromPopover() },
      onStopListening: { [weak self] in self?.dictationService.stopListening() },
      onConfirmGoal: { [weak self] goal in self?.confirmSession(goal: goal) },
      onDismissIdle: { [weak self] in self?.popover.performClose(nil) },
      onOpenSettings: { [weak self] in self?.openMicrophoneSettings() },
      onSaveApiKey: { [weak self] key in self?.saveApiKey(key) },
      onEndSession: { [weak self] in self?.endSession() },
      onBackToWork: { [weak self] in self?.dismissDetection() },
      onSnooze: { [weak self] in self?.snoozeDetection() }
    )

    popoverViewModel.onSnoozeEnd = { [weak self] in
      guard let self else { return }
      sessionManager.clearSnooze()
      transitionToActive()
    }

    popover.contentViewController = NSHostingController(rootView: contentView)
  }

  private func togglePopover(_ sender: NSView) {
    if case .snoozed(let until, _) = popoverViewModel.state, Date() >= until {
      sessionManager.clearSnooze()
      transitionToActive()
    }

    if popover.isShown {
      removeKeyMonitor()
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
      installKeyMonitor()
    }
  }

  private func installKeyMonitor() {
    removeKeyMonitor()
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self,
            self.popover.isShown,
            let window = self.popover.contentViewController?.view.window,
            window.isKeyWindow,
            event.modifierFlags.contains(.command),
            let chars = event.charactersIgnoringModifiers else {
        return event
      }
      switch chars {
      case "a": NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil); return nil
      case "c": NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil); return nil
      case "v": NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil); return nil
      case "x": NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil); return nil
      default: return event
      }
    }
  }

  private func removeKeyMonitor() {
    if let monitor = keyMonitor {
      NSEvent.removeMonitor(monitor)
      keyMonitor = nil
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

  // MARK: - Observers

  private func setupObservers() {
    popoverViewModel.$state
      .combineLatest(popoverViewModel.$isListening)
      .sink { [weak self] _, _ in
        self?.updateIcon()
      }
      .store(in: &cancellables)
  }

  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Icon

  private func updateIcon() {
    let iconState = AppIconState(
      from: popoverViewModel.state,
      isListening: popoverViewModel.isListening
    )
    statusItem.button?.image = MenuBarIcon.make(iconState: iconState, animPhase: animPhase)
  }

  // MARK: - Animation

  private func updateAnimationTimer() {
    animTimer?.invalidate()
    animTimer = nil
    animPhase = 0
    lastFrameTime = Date()

    let iconState = AppIconState(
      from: popoverViewModel.state,
      isListening: popoverViewModel.isListening
    )
    switch iconState {
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

  private func syncSessionStats() {
    popoverViewModel.sessionsToday = sessionManager.sessionsToday
    popoverViewModel.totalFocusTime = sessionManager.totalFocusTimeToday
  }

  private func transitionToActive() {
    let goal = sessionManager.currentSession?.goals ?? ""
    let startTime = sessionManager.currentSession?.startTime ?? Date()
    let triggers = sessionManager.currentSession?.triggerCount ?? 0
    popoverViewModel.state = .active(goal: goal, startTime: startTime, distractions: triggers)
    syncSessionStats()
  }

  private func computeElapsedMinutes() -> Int {
    guard let start = lastTrackingStart else { return 0 }
    return Int(Date().timeIntervalSince(start) / 60)
  }

  // MARK: - Detection Context (called from AppDelegate)

  func ensureFirstDetectedAt() {
    detectionCycle.ensureFirstDetectedAt()
  }

  func resetDetectionCycle() {
    detectionCycle.reset()
  }

  func updateDetectionContext(site: String, trackingStart: Date?) {
    lastDetectedSite = site
    lastTrackingStart = trackingStart
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
    guard goal.count <= 55 else {
      popoverViewModel.idleError = "Goal too long (max 55 characters)"
      return
    }
    guard keychain.read() != nil else {
      popoverViewModel.idleError = "Configure an API key in Preferences before starting a session."
      return
    }
    sessionManager.startSession(goals: goal)
    popoverViewModel.state = .active(
      goal: goal,
      startTime: sessionManager.currentSession?.startTime ?? Date(),
      distractions: 0
    )
    syncSessionStats()
    print("[HeyYou] Session started: \(goal)")
  }

  private func openMicrophoneSettings() {
    NSWorkspace.shared.open(
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
    )
  }

  private func dismissDetection() {
    interventionService.stop()
    triggerEngine.acknowledgeTrigger()
    transitionToActive()
    popover.performClose(nil)
  }

  private func snoozeDetection() {
    interventionService.stop()
    triggerEngine.acknowledgeTrigger()
    let until = Date().addingTimeInterval(300)
    sessionManager.snoozeUntil = until
    let goal = sessionManager.currentSession?.goals ?? ""
    popoverViewModel.state = .snoozed(until: until, goal: goal)
    syncSessionStats()
    popover.performClose(nil)
  }

  // MARK: - State (called from AppDelegate)

  func setDetecting() {
    let goals = sessionManager.currentSession?.goals ?? ""
    let site = lastDetectedSite ?? "Unknown"
    detectionCycle.incrementFireCount()
    popoverViewModel.state = .detecting(
      goal: goals,
      site: site,
      fireCount: detectionCycle.fireCount
    )
    syncSessionStats()
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
  func showDetectionPopover(message: String) {
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
      elapsedMinutes: elapsed,
      spokenMessage: message
    )
    syncSessionStats()

    guard let button = statusItem.button else { return }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.orderFrontRegardless()
    popover.contentViewController?.view.window?.makeKey()
  }

  func endSession() {
    dictationService.cancel()
    sessionManager.clearSnooze()
    sessionManager.endSession()
    triggerEngine.reset()
    popoverViewModel.state = .idle
    syncSessionStats()
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
