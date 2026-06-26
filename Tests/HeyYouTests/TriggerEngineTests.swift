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

// MARK: - Async timer transitions

/// Processes the run loop repeatedly until `condition` passes or `timeout` seconds elapse.
private func poll(timeout: TimeInterval = 2, _ condition: () -> Bool) {
  let deadline = Date().addingTimeInterval(timeout)
  while !condition(), Date() < deadline {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
  }
}

@Test("Tracking transitions to pending after threshold")
func trackingToPending() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.03, repeatThreshold: 0.03)
  let engine = TriggerEngine(sessionManager: SessionManager(), pendingDelay: 0.5)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))
  #expect(engine.state != .focused)

  poll { if case .pending = engine.state { true } else { false } }

  if case .pending = engine.state {
    // expected
  } else {
    Issue.record("Expected pending state, got \(engine.state)")
  }
}

@Test("Pending transitions to triggered after cancel window")
func pendingToTriggered() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  poll { if case .triggered = engine.state { true } else { false } }

  if case .triggered(let s, _) = engine.state {
    #expect(s == sig)
  } else {
    Issue.record("Expected triggered state, got \(engine.state)")
  }
}

@Test("Trigger increments session trigger count")
func triggerIncrementsCount() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  poll { sm.currentSession?.triggerCount == 1 }

  #expect(sm.currentSession?.triggerCount == 1)
}

@Test("Triggered state suppresses new doomscroll during cooldown")
func triggeredSuppressesDuringCooldown() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  poll { if case .triggered = engine.state { true } else { false } }

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
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let engine = TriggerEngine(sessionManager: SessionManager(), pendingDelay: 0.02)
  var triggeredSig: DoomscrollSignature?
  engine.onTrigger = { triggeredSig = $0 }

  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  poll { triggeredSig != nil }

  #expect(triggeredSig == sig)
}

@Test("Cooldown expires and allows productive reset")
func cooldownAllowsReset() {
  let sig = DoomscrollSignature(name: "Test", patterns: ["test"], threshold: 0.01, repeatThreshold: 0.01)
  let sm = SessionManager()
  sm.startSession(goals: "test")
  let engine = TriggerEngine(sessionManager: sm, pendingDelay: 0.02)
  engine.classificationDidChange(.doomscroll(matchedBy: sig))

  poll { if case .triggered = engine.state { true } else { false } }

  if case .triggered = engine.state {
    // expected
  } else {
    Issue.record("Expected triggered state")
    return
  }

  engine.classificationDidChange(.productive)
  #expect(engine.state == .focused)
}
