enum Classification: Equatable {
    case productive
    case doomscroll(matchedBy: DoomscrollSignature)
}

final class DoomscrollDetector {
    let signatures: [DoomscrollSignature]

    init(signatures: [DoomscrollSignature]) {
        self.signatures = signatures
    }

    func classify(_ app: AppInfo) -> Classification {
        for sig in signatures {
            if sig.matches(appName: app.name, windowTitle: app.windowTitle) {
                return .doomscroll(matchedBy: sig)
            }
        }
        return .productive
    }
}
