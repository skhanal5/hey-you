import Testing
import Foundation
@testable import HeyYou

@Test("Starts in focused state")
func startsFocused() {
  let engine = TriggerEngine(sessionManager: SessionManager())
  #expect(engine.state == .focused)
}

@Test("Doomscroll classification transitions to tracking")
func doomscrollBeginsTracking() {
  let engine = TriggerEngine(sessionManager: SessionManager())
  let sig = defaultDoomscrollSignatures[0]
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  if case .tracking(let s, _) = engine.state {
    #expect(s == sig)
  } else {
    Issue.record("Expected tracking state, got \(engine.state)")
  }
}

@Test("Productive classification returns to focused")
func productiveReturnsToFocused() {
  let engine = TriggerEngine(sessionManager: SessionManager())
  let sig = defaultDoomscrollSignatures[0]
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  engine.classificationDidChange(.productive)
  #expect(engine.state == .focused)
}

@Test("Multiple doomscroll events keep tracking once started")
func repeatedDoomscrollKeepsTracking() {
  let engine = TriggerEngine(sessionManager: SessionManager())
  let sig = defaultDoomscrollSignatures[0]
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  if case .tracking = engine.state {
    // expected
  } else {
    Issue.record("Expected tracking state")
  }
}

@Test("Tracking transitions to triggered after threshold expires")
func trackingToTriggered() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  if case .triggered(let s, _) = engine.state {
    #expect(s == sig)
  } else {
    Issue.record("Expected triggered state, got \(engine.state)")
  }
}

@Test("Trigger increments session trigger count")
func triggerIncrementsCount() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  #expect(sm.currentSession?.triggerCount == 1)
}

@Test("Triggered state suppresses new doomscroll during cooldown")
func triggeredSuppressesDuringCooldown() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  guard case .triggered = engine.state else {
    Issue.record("Expected triggered state")
    return
  }

  let before = engine.state
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  #expect(engine.state == before)
}

@Test("Productive classification during tracking resets to focused")
func productiveResetsTracking() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 30, repeatThreshold: 15)
  let engine = TriggerEngine(sessionManager: SessionManager())
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  if case .tracking = engine.state {
    // expected
  } else {
    Issue.record("Expected tracking state, got \(engine.state)")
  }

  engine.classificationDidChange(.productive)
  #expect(engine.state == .focused)
}

@Test("Trigger fires onTrigger callback")
func triggerFiresCallback() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  var triggeredSig: DoomscrollSignature?
  engine.onTrigger = { triggeredSig = $0 }

  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  #expect(triggeredSig == sig)
}

@Test("Productive during cooldown does not reset triggered state")
func productiveDuringCooldown() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  guard case .triggered = engine.state else {
    Issue.record("Expected triggered state")
    return
  }

  // Productive classification should be ignored during cooldown
  engine.classificationDidChange(.productive)
  guard case .triggered = engine.state else {
    Issue.record("Expected engine to stay triggered during cooldown")
    return
  }
}

@Test("Acknowledge clears triggered state for next doomscroll")
func acknowledgeClearsTriggered() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  guard case .triggered = engine.state else {
    Issue.record("Expected triggered state")
    return
  }

  engine.acknowledgeTrigger()

  #expect(engine.state == .focused)

  // Next doomscroll should start tracking immediately (no cooldown block)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  if case .tracking(let s, _) = engine.state {
    #expect(s == sig)
  } else {
    Issue.record("Expected tracking state after acknowledge, got \(engine.state)")
  }
}

@Test("Snooze suppresses trigger and resets to focused")
func snoozeSuppressesTrigger() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  sm.snoozeUntil = Date().addingTimeInterval(300)
  let engine = TriggerEngine(sessionManager: sm, scheduler: scheduler)
  var triggerFired = false
  engine.onTrigger = { _ in triggerFired = true }

  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)

  #expect(!triggerFired)
  #expect(engine.state == .focused)
}


