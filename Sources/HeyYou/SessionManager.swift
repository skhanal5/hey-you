import Foundation

final class SessionManager {
    private(set) var currentSession: Session?

    var isSessionActive: Bool { currentSession != nil }

    func startSession(goals: String) {
        currentSession = Session(goals: goals, startTime: Date())
    }

    func endSession() {
        currentSession = nil
    }

    func recordTrigger() {
        currentSession?.triggerCount += 1
        currentSession?.lastTriggerTime = Date()
    }
}
