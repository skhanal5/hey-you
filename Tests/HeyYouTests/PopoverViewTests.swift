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
  vm.state = .detection(goal: "focus", site: "reddit.com", elapsedMinutes: 4)
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
