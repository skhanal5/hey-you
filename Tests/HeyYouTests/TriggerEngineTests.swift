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

@Test("Tracking transitions to pending after threshold")
func trackingToPending() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.03, repeatThreshold: 0.03)
  let engine = TriggerEngine(sessionManager: SessionManager(), pendingDelay: 0.5, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.03)

  if case .pending = engine.state {
    // expected
  } else {
    Issue.record("Expected pending state, got \(engine.state)")
  }
}

@Test("Pending transitions to triggered after cancel window")
func pendingToTriggered() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)
  scheduler.advance(by: 0.02)

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
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)
  scheduler.advance(by: 0.02)

  #expect(sm.currentSession?.triggerCount == 1)
}

@Test("Triggered state suppresses new doomscroll during cooldown")
func triggeredSuppressesDuringCooldown() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)
  scheduler.advance(by: 0.02)

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
  let engine = TriggerEngine(sessionManager: SessionManager(), pendingDelay: 2.5)
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
  let engine = TriggerEngine(sessionManager: SessionManager(), pendingDelay: 0.02, scheduler: scheduler)
  var triggeredSig: DoomscrollSignature?
  engine.onTrigger = { triggeredSig = $0 }

  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)
  scheduler.advance(by: 0.02)

  #expect(triggeredSig == sig)
}

@Test("Cooldown allows productive reset")
func cooldownAllowsProductiveReset() {
  let scheduler = TestScheduler()
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02, scheduler: scheduler)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  scheduler.advance(by: 0.01)
  scheduler.advance(by: 0.02)

  guard case .triggered = engine.state else {
    Issue.record("Expected triggered state")
    return
  }

  engine.classificationDidChange(.productive)
  #expect(engine.state == .focused)
}


