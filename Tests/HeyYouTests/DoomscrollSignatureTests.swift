import Testing
@testable import HeyYou

@Test("Matches by app name")
func matchesAppName() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["\\bReddit\\b"], threshold: 30, repeatThreshold: 15)
  #expect(sig.matches(appName: "Reddit", windowTitle: nil))
}

@Test("Matches by window title")
func matchesWindowTitle() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["\\bReddit\\b"], threshold: 30, repeatThreshold: 15)
  #expect(sig.matches(appName: "Safari", windowTitle: "home - Reddit"))
}

@Test("Does not match unrelated app")
func noMatch() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["\\bReddit\\b"], threshold: 30, repeatThreshold: 15)
  #expect(!sig.matches(appName: "Xcode", windowTitle: "Project"))
}

@Test("Matches case insensitively")
func caseInsensitive() {
  let sig = DoomscrollSignature(name: "Reddit", patterns: ["\\breddit\\b"], threshold: 30, repeatThreshold: 15)
  #expect(sig.matches(appName: "REDDIT", windowTitle: nil))
}

@Test("Matches X as standalone word")
func matchesStandaloneX() {
  let sig = DoomscrollSignature(name: "X", patterns: ["\\bX\\b"], threshold: 30, repeatThreshold: 15)
  #expect(sig.matches(appName: "X", windowTitle: nil))
  #expect(!sig.matches(appName: "Xcode", windowTitle: nil))
}

@Test("Matches X in browser title")
func matchesXInBrowser() {
  let sig = DoomscrollSignature(name: "X/Twitter", patterns: ["\\bX\\b"], threshold: 30, repeatThreshold: 15)
  #expect(sig.matches(appName: "Firefox", windowTitle: "Home / X"))
}

@Test("Nil window title is handled")
func nilWindowTitle() {
  let sig = DoomscrollSignature(name: "Instagram", patterns: ["Instagram"], threshold: 20, repeatThreshold: 10)
  #expect(sig.matches(appName: "Instagram", windowTitle: nil))
  #expect(!sig.matches(appName: "Safari", windowTitle: nil))
}

@Test("Equatable ignores compiled patterns")
func equatable() {
  let a = DoomscrollSignature(name: "Reddit", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  let b = DoomscrollSignature(name: "Reddit", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  #expect(a == b)
}

@Test("Equatable differs on name")
func equatableDiffersName() {
  let a = DoomscrollSignature(name: "Reddit", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  let b = DoomscrollSignature(name: "X", patterns: ["Reddit"], threshold: 30, repeatThreshold: 15)
  #expect(a != b)
}
