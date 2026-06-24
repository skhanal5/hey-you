import Testing
@testable import HeyYou

let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)

@Test("Classifies Twitter native app as doomscroll")
func twitterApp() {
    let app = AppInfo(name: "Twitter", bundleId: "com.twitter.twitter", windowTitle: nil)
    let result = detector.classify(app)
    if case .doomscroll(let sig) = result {
        #expect(sig.name == "X/Twitter")
    } else {
        Issue.record("Expected doomscroll, got productive")
    }
}

@Test("Classifies X in browser window title as doomscroll")
func twitterInBrowser() {
    let app = AppInfo(name: "Firefox", bundleId: "org.mozilla.firefox", windowTitle: "Home / X")
    let result = detector.classify(app)
    if case .doomscroll(let sig) = result {
        #expect(sig.name == "X/Twitter")
    } else {
        Issue.record("Expected doomscroll, got productive")
    }
}

@Test("Classifies Reddit as doomscroll")
func reddit() {
    let app = AppInfo(name: "Safari", bundleId: "com.apple.safari", windowTitle: "home - Reddit")
    let result = detector.classify(app)
    if case .doomscroll(let sig) = result {
        #expect(sig.name == "Reddit")
    } else {
        Issue.record("Expected doomscroll, got productive")
    }
}

@Test("Classifies Xcode as productive")
func xcode() {
    let app = AppInfo(name: "Xcode", bundleId: "com.apple.dt.Xcode", windowTitle: "HeyYou")
    #expect(detector.classify(app) == .productive)
}

@Test("Classifies Terminal as productive")
func terminal() {
    let app = AppInfo(name: "Terminal", bundleId: "com.apple.Terminal", windowTitle: "zsh")
    #expect(detector.classify(app) == .productive)
}

@Test("Window title with Reddit and productive app name")
func redditInBrowserName() {
    let app = AppInfo(name: "Safari", bundleId: "com.apple.safari", windowTitle: "r/programming - Reddit")
    let result = detector.classify(app)
    if case .doomscroll(let sig) = result {
        #expect(sig.name == "Reddit")
    } else {
        Issue.record("Expected doomscroll, got productive")
    }
}

@Test("Signature matches by app name only")
func instagramApp() {
    let app = AppInfo(name: "Instagram", bundleId: "com.instagram.Instagram", windowTitle: nil)
    let result = detector.classify(app)
    if case .doomscroll(let sig) = result {
        #expect(sig.name == "Instagram")
    } else {
        Issue.record("Expected doomscroll, got productive")
    }
}
