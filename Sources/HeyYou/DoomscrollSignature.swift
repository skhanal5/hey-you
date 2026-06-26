import Foundation

struct DoomscrollSignature {
    let name: String
    let patterns: [String]
    let threshold: TimeInterval
    let repeatThreshold: TimeInterval
    private let compiledPatterns: [NSRegularExpression]

    init(name: String, patterns: [String], threshold: TimeInterval, repeatThreshold: TimeInterval) {
        self.name = name
        self.patterns = patterns
        self.threshold = threshold
        self.repeatThreshold = repeatThreshold
        self.compiledPatterns = patterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
    }

    func matches(appName: String, windowTitle: String?) -> Bool {
        let haystack = "\(appName) \(windowTitle ?? "")"
        let range = NSRange(haystack.startIndex..., in: haystack)
        for regex in compiledPatterns {
            if regex.firstMatch(in: haystack, range: range) != nil {
                return true
            }
        }
        return false
    }
}

extension DoomscrollSignature: Equatable {
    static func == (lhs: DoomscrollSignature, rhs: DoomscrollSignature) -> Bool {
        lhs.name == rhs.name
            && lhs.patterns == rhs.patterns
            && lhs.threshold == rhs.threshold
            && lhs.repeatThreshold == rhs.repeatThreshold
    }
}
