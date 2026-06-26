import Testing
@testable import HeyYou

@Test("Starts with no active session")
func noSessionInitially() {
  let sm = SessionManager()
  #expect(sm.currentSession == nil)
  #expect(!sm.isSessionActive)
}

@Test("Start session creates session with goals")
func startSession() {
  let sm = SessionManager()
  sm.startSession(goals: "focus")
  #expect(sm.currentSession?.goals == "focus")
  #expect(sm.isSessionActive)
}

@Test("End session clears current session")
func endSession() {
  let sm = SessionManager()
  sm.startSession(goals: "focus")
  sm.endSession()
  #expect(sm.currentSession == nil)
}

@Test("Record trigger increments count")
func recordTrigger() {
  let sm = SessionManager()
  sm.startSession(goals: "focus")
  sm.recordTrigger()
  #expect(sm.currentSession?.triggerCount == 1)
  sm.recordTrigger()
  #expect(sm.currentSession?.triggerCount == 2)
}

@Test("Record trigger sets lastTriggerTime")
func recordTriggerSetsTime() {
  let sm = SessionManager()
  sm.startSession(goals: "focus")
  sm.recordTrigger()
  #expect(sm.currentSession?.lastTriggerTime != nil)
}

@Test("Record trigger without session is no-op")
func recordTriggerNoSession() {
  let sm = SessionManager()
  sm.recordTrigger()
  #expect(sm.currentSession == nil)
}
