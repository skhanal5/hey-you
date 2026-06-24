import Foundation

struct DoomscrollSignature: Equatable {
    let name: String
    let patterns: [String]
    let threshold: TimeInterval
    let repeatThreshold: TimeInterval

    func matches(appName: String, windowTitle: String?) -> Bool {
        let haystack = "\(appName) \(windowTitle ?? "")"
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(haystack.startIndex..., in: haystack)
            if regex.firstMatch(in: haystack, range: range) != nil {
                return true
            }
        }
        return false
    }
}
