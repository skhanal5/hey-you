import Foundation
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

// MARK: - Sessions today

@Test("Sessions today starts at zero")
func sessionsTodayInitial() {
  let sm = SessionManager()
  #expect(sm.sessionsToday == 0)
}

@Test("Sessions today increments on end session")
func sessionsTodayIncrements() {
  let sm = SessionManager()
  sm.startSession(goals: "a")
  sm.endSession()
  #expect(sm.sessionsToday == 1)
}

@Test("Sessions today increments multiple times")
func sessionsTodayMultiple() {
  let sm = SessionManager()
  sm.startSession(goals: "a"); sm.endSession()
  sm.startSession(goals: "b"); sm.endSession()
  sm.startSession(goals: "c"); sm.endSession()
  #expect(sm.sessionsToday == 3)
}

// MARK: - Total focus time

@Test("Total focus time starts at zero")
func totalTimeInitial() {
  let sm = SessionManager()
  #expect(sm.totalFocusTimeToday == 0)
}

@Test("Total focus time is non-negative after session")
func totalTimeNonNegative() {
  let sm = SessionManager()
  sm.startSession(goals: "a"); sm.endSession()
  #expect(sm.totalFocusTimeToday >= 0)
}

// MARK: - Snooze

@Test("Snooze starts nil")
func snoozeInitial() {
  let sm = SessionManager()
  #expect(sm.snoozeUntil == nil)
}

@Test("Should trigger when no snooze")
func shouldTriggerNoSnooze() {
  let sm = SessionManager()
  #expect(sm.shouldTrigger())
}

@Test("Should trigger returns false while snoozed")
func shouldTriggerWhileSnoozed() {
  let sm = SessionManager()
  sm.snoozeUntil = Date().addingTimeInterval(60)
  #expect(!sm.shouldTrigger())
}

@Test("Should trigger returns true after snooze expires")
func shouldTriggerAfterSnoozeExpires() {
  let sm = SessionManager()
  sm.snoozeUntil = Date().addingTimeInterval(-1)
  #expect(sm.shouldTrigger())
}

@Test("Clear snooze sets snooze to nil")
func clearSnooze() {
  let sm = SessionManager()
  sm.snoozeUntil = Date().addingTimeInterval(60)
  sm.clearSnooze()
  #expect(sm.snoozeUntil == nil)
  #expect(sm.shouldTrigger())
}

@Test("Reset clears session and snooze")
func resetClearsAll() {
  let sm = SessionManager()
  sm.startSession(goals: "focus")
  sm.snoozeUntil = Date().addingTimeInterval(60)
  sm.reset()
  #expect(sm.currentSession == nil)
  #expect(sm.snoozeUntil == nil)
}
