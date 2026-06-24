import Testing
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
