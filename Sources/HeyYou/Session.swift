import Foundation

struct Session: Equatable {
    let goals: String
    let startTime: Date
    var triggerCount: Int = 0
    var lastTriggerTime: Date? = nil
}
