import Foundation
import Testing
@testable import HeyYou

@Test("Idle equals idle")
func idleEquality() {
  #expect(SessionState.idle == SessionState.idle)
}

@Test("Active with different startTime are not equal")
func activeDifferentTimes() {
  let a = SessionState.active(goal: "focus", startTime: Date.distantPast, distractions: 0)
  let b = SessionState.active(goal: "focus", startTime: Date.distantFuture, distractions: 0)
  #expect(a != b)
}

@Test("Active with same goal and startTime are equal")
func activeExactEquality() {
  let now = Date()
  let a = SessionState.active(goal: "focus", startTime: now, distractions: 2)
  let b = SessionState.active(goal: "focus", startTime: now, distractions: 2)
  #expect(a == b)
}

@Test("Active with different goal are not equal")
func activeDifferentGoal() {
  let now = Date()
  let a = SessionState.active(goal: "focus", startTime: now, distractions: 0)
  let b = SessionState.active(goal: "other", startTime: now, distractions: 0)
  #expect(a != b)
}

@Test("Active with different distractions are not equal")
func activeDifferentDistractions() {
  let now = Date()
  let a = SessionState.active(goal: "focus", startTime: now, distractions: 0)
  let b = SessionState.active(goal: "focus", startTime: now, distractions: 1)
  #expect(a != b)
}

@Test("Detection with same values are equal")
func detectionEquality() {
  let a = SessionState.detection(goal: "focus", site: "reddit.com", fireCount: 1, elapsedMinutes: 4, spokenMessage: "Hey — you're on reddit.")
  let b = SessionState.detection(goal: "focus", site: "reddit.com", fireCount: 1, elapsedMinutes: 4, spokenMessage: "Hey — you're on reddit.")
  #expect(a == b)
}

@Test("Detecting with same values are equal")
func detectingEquality() {
  let a = SessionState.detecting(goal: "focus", site: "reddit.com", fireCount: 1)
  let b = SessionState.detecting(goal: "focus", site: "reddit.com", fireCount: 1)
  #expect(a == b)
}

@Test("Different states are not equal")
func differentStatesNotEqual() {
  #expect(SessionState.idle != SessionState.active(goal: "x", startTime: Date(), distractions: 0))
  #expect(SessionState.idle != SessionState.detecting(goal: "x", site: "y", fireCount: 1))
  #expect(SessionState.idle != SessionState.detection(goal: "x", site: "x", fireCount: 1, elapsedMinutes: 0, spokenMessage: ""))
}

// MARK: - PopoverViewModel

@Test("ViewModel starts in idle state")
func viewModelInitialState() {
  let vm = PopoverViewModel()
  #expect(vm.state == .idle)
  #expect(!vm.isListening)
  #expect(vm.liveTranscription.isEmpty)
  #expect(vm.idleError == nil)
  #expect(!vm.showTextField)
}

@Test("ViewModel startListening sets listening state")
func viewModelStartListening() {
  let vm = PopoverViewModel()
  vm.startListening()
  #expect(vm.isListening)
  #expect(vm.liveTranscription.isEmpty)
  #expect(vm.idleError == nil)
}

@Test("ViewModel confirmTranscription stops listening")
func viewModelConfirm() {
  let vm = PopoverViewModel()
  vm.startListening()
  vm.liveTranscription = "hello"
  vm.confirmTranscription()
  #expect(!vm.isListening)
}

@Test("ViewModel handleListeningError sets idle error")
func viewModelListeningError() {
  let vm = PopoverViewModel()
  vm.startListening()
  let error = DictationService.Error.microphonePermissionDenied
  vm.handleListeningError(error)
  #expect(!vm.isListening)
  #expect(vm.idleError != nil)
  #expect(vm.idleError?.contains("Microphone") == true)
}

@Test("ViewModel handleListeningUnavailable falls back to text field")
func viewModelUnavailable() {
  let vm = PopoverViewModel()
  vm.startListening()
  vm.handleListeningError(DictationService.Error.recognitionUnavailable)
  #expect(!vm.isListening)
  #expect(vm.showTextField)
}

@Test("ViewModel handleListeningRecognitionError shows retry message")
func viewModelRecognitionError() {
  let vm = PopoverViewModel()
  vm.startListening()
  let underlying = NSError(domain: "test", code: 0, userInfo: nil)
  vm.handleListeningError(DictationService.Error.recognitionFailed(underlying))
  #expect(!vm.isListening)
  #expect(vm.idleError == vm.recognitionErrorMessage)
}
