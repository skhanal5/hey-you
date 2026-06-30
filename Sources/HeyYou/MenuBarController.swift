import AppKit
import SwiftUI

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
    popover.behavior = .transient

    let contentView = PopoverContentView(
      viewModel: popoverViewModel,
      onStartListening: { [weak self] in self?.startListeningFromPopover() },
      onStopListening: { [weak self] in self?.dictationService.stopListening() },
      onConfirmGoal: { [weak self] goal in self?.confirmSession(goal: goal) },
      onDismissIdle: {},
      onTypeGoal: { [weak self] goal in self?.confirmSession(goal: goal) },
      onOpenSettings: { [weak self] in self?.openMicrophoneSettings() },
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
    syncPopoverState()
  }

  // MARK: - Popover State Sync

  private func syncPopoverState() {
    switch state {
    case .idle, .listening:
      popoverViewModel.state = .idle
    case .active(let goals, let triggers):
      popoverViewModel.state = .active(
        goal: goals,
        startTime: sessionManager.currentSession?.startTime ?? Date(),
        distractions: triggers
      )
    case .detecting, .speaking:
      // Don't auto-transition popover to detection on tracking start.
      // The popover only flips to detection when the trigger actually
      // fires, via showDetectionPopover(). This prevents flip-flopping
      // when the user briefly switches to a doomscroll app and back.
      return
    }
    popoverViewModel.sessionsToday = sessionManager.sessionsToday
    popoverViewModel.totalFocusTime = sessionManager.totalFocusTimeToday
  }

  private func computeElapsedMinutes() -> Int {
    guard let start = lastTrackingStart else { return 0 }
    return Int(Date().timeIntervalSince(start) / 60)
  }

  // MARK: - Popover Actions

  private func startListeningFromPopover() {
    popoverViewModel.startListening()
    Task {
      do {
        let goal = try await dictationService.startListening { [weak self] text in
          Task { @MainActor in
            self?.popoverViewModel.liveTranscription = text
          }
        }
        await MainActor.run {
          self.confirmSession(goal: goal)
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
    sessionManager.startSession(goals: goal)
    state = .active(goals: goal, triggers: 0)
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

  /// Show the detection state in the popover when a trigger fires
  func showDetectionPopover() {
    let goals = sessionManager.currentSession?.goals ?? ""
    let site = lastDetectedSite ?? "Unknown"
    let elapsed = computeElapsedMinutes()
    popoverViewModel.state = .detection(
      goal: goals,
      site: site,
      elapsedMinutes: elapsed
    )
    popoverViewModel.sessionsToday = sessionManager.sessionsToday
    popoverViewModel.totalFocusTime = sessionManager.totalFocusTimeToday

    guard let button = statusItem.button, !popover.isShown else { return }
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
    print("[HeyYou] Session ended")
  }

  // MARK: - Preferences

  private var preferencesController: PreferencesWindowController?

  @objc private func showPreferences() {
    if preferencesController == nil {
      preferencesController = PreferencesWindowController(keychain: keychain)
    }
    preferencesController?.show()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }
}
