import Testing
@testable import HeyYou

@Test("Idle with detecting=true stays idle")
func idleDetectTrue() {
  let s = MenuBarState.idle.settingDetecting(true)
  #expect(s == .idle)
}

@Test("Idle with detecting=false stays idle")
func idleDetectFalse() {
  let s = MenuBarState.idle.settingDetecting(false)
  #expect(s == .idle)
}

@Test("Listening with detecting=true stays listening")
func listeningDetectTrue() {
  let s = MenuBarState.listening.settingDetecting(true)
  #expect(s == .listening)
}

@Test("Active with detecting=true transitions to detecting")
func activeDetectTrue() {
  let s = MenuBarState.active(goals: "focus", triggers: 3).settingDetecting(true)
  #expect(s == .detecting(goals: "focus", triggers: 3))
}

@Test("Detecting with detecting=false transitions to active")
func detectingDetectFalse() {
  let s = MenuBarState.detecting(goals: "focus", triggers: 3).settingDetecting(false)
  #expect(s == .active(goals: "focus", triggers: 3))
}

@Test("Speaking with detecting=false transitions to active")
func speakingDetectFalse() {
  let s = MenuBarState.speaking(goals: "focus", triggers: 3).settingDetecting(false)
  #expect(s == .active(goals: "focus", triggers: 3))
}

@Test("Detecting with detecting=true stays detecting")
func detectingDetectTrue() {
  let s = MenuBarState.detecting(goals: "x", triggers: 1).settingDetecting(true)
  #expect(s == .detecting(goals: "x", triggers: 1))
}

@Test("Active with speaking=true transitions to speaking")
func activeSpeakTrue() {
  let s = MenuBarState.active(goals: "focus", triggers: 3).settingSpeaking(true)
  #expect(s == .speaking(goals: "focus", triggers: 3))
}

@Test("Detecting with speaking=true transitions to speaking")
func detectingSpeakTrue() {
  let s = MenuBarState.detecting(goals: "focus", triggers: 3).settingSpeaking(true)
  #expect(s == .speaking(goals: "focus", triggers: 3))
}

@Test("Speaking with speaking=false transitions to detecting")
func speakingSpeakFalse() {
  let s = MenuBarState.speaking(goals: "focus", triggers: 3).settingSpeaking(false)
  #expect(s == .detecting(goals: "focus", triggers: 3))
}

@Test("Idle with speaking=true stays idle")
func idleSpeakTrue() {
  let s = MenuBarState.idle.settingSpeaking(true)
  #expect(s == .idle)
}
