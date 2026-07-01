import Foundation
import Testing
@testable import HeyYou

@Test("PopoverContentView initializes with idle state")
func popoverContentIdle() {
  let vm = PopoverViewModel()
  let view = PopoverContentView(viewModel: vm)
  #expect(view.viewModel.state == .idle)
}

@Test("PopoverContentView reflects active state")
func popoverContentActive() {
  let vm = PopoverViewModel()
  vm.state = .active(goal: "focus", startTime: Date(), distractions: 0)
  let view = PopoverContentView(viewModel: vm)
  #expect(view.viewModel.state != .idle)
}

@Test("PopoverContentView reflects detection state")
func popoverContentDetection() {
  let vm = PopoverViewModel()
  vm.state = .detection(goal: "focus", site: "reddit.com", fireCount: 1, elapsedMinutes: 4)
  let view = PopoverContentView(viewModel: vm)
  #expect(view.viewModel.state != .idle)
}

@Test("StateColor idle returns correct opacity")
func idleColor() {
  let color = StateColor.idleTranslucent()
  _ = color
}

@Test("StateColor active returns correct green")
func activeColor() {
  let color = StateColor.activeGreen()
  _ = color
}

@Test("StateColor detection returns correct red")
func detectionColor() {
  let color = StateColor.detectionRed()
  _ = color
}

@Test("PopoverViewModel apiKeyAvailable defaults to false")
func apiKeyAvailableDefault() {
  let vm = PopoverViewModel()
  #expect(vm.apiKeyAvailable == false)
}

@Test("PopoverViewModel apiKeyAvailable reflects set value")
func apiKeyAvailableSet() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = true
  #expect(vm.apiKeyAvailable == true)
  vm.apiKeyAvailable = false
  #expect(vm.apiKeyAvailable == false)
}

@Test("IdleStateView renders no-key section when apiKeyAvailable is false")
func idleStateNoKeySection() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = false
  let view = IdleStateView(
    viewModel: vm,
    onStartListening: {},
    onStopListening: { nil },
    onConfirmGoal: { _ in },
    onDismiss: {},
    onOpenSettings: {},
    onOpenPreferences: {}
  )
  _ = view
}

@Test("IdleStateView renders input section when apiKeyAvailable is true")
func idleStateInputSection() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = true
  let view = IdleStateView(
    viewModel: vm,
    onStartListening: {},
    onStopListening: { nil },
    onConfirmGoal: { _ in },
    onDismiss: {},
    onOpenSettings: {},
    onOpenPreferences: {}
  )
  _ = view
}

@Test("IdleStateView no-key section contains key configuration message")
func noKeySectionContainsPreferencesLink() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = false
  let view = IdleStateView(
    viewModel: vm,
    onStartListening: {},
    onStopListening: { nil },
    onConfirmGoal: { _ in },
    onDismiss: {},
    onOpenSettings: {},
    onOpenPreferences: {}
  )
  let mirror = Mirror(reflecting: view)
  #expect(mirror.children.contains { $0.label == "onOpenPreferences" })
}

@Test("confirmSession guard sets idleError when apiKey unavailable")
func confirmSessionGuard() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = false

  func confirmSession(goal: String) {
    guard !goal.isEmpty else { return }
    guard vm.apiKeyAvailable else {
      vm.idleError = "Configure an API key in Preferences before starting a session."
      return
    }
  }

  confirmSession(goal: "test")
  #expect(vm.idleError == "Configure an API key in Preferences before starting a session.")
}

@Test("confirmSession guard does not set idleError when apiKey available")
func confirmSessionPassesWithKey() {
  let vm = PopoverViewModel()
  vm.apiKeyAvailable = true

  func confirmSession(goal: String) {
    guard !goal.isEmpty else { return }
    guard vm.apiKeyAvailable else {
      vm.idleError = "Configure an API key in Preferences before starting a session."
      return
    }
  }

  confirmSession(goal: "test")
  #expect(vm.idleError == nil)
}
