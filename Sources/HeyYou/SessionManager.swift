import Foundation

final class SessionManager {
  private(set) var currentSession: Session?
  private var lastStatsDate: Date = Date()

  var isSessionActive: Bool { currentSession != nil }

  var sessionsToday: Int = 0
  var totalFocusTimeToday: TimeInterval = 0
  var snoozeUntil: Date?

  func startSession(goals: String) {
    currentSession = Session(goals: goals, startTime: Date())
  }

  func endSession() {
    guard let session = currentSession else { return }
    let elapsed = Date().timeIntervalSince(session.startTime)
    checkDayBoundary()
    sessionsToday += 1
    totalFocusTimeToday += elapsed
    currentSession = nil
  }

  func recordTrigger() {
    currentSession?.triggerCount += 1
    currentSession?.lastTriggerTime = Date()
  }

  func shouldTrigger() -> Bool {
    guard let snoozeUntil else { return true }
    return Date() >= snoozeUntil
  }

  func clearSnooze() {
    snoozeUntil = nil
  }

  func reset() {
    currentSession = nil
    clearSnooze()
  }

  private func checkDayBoundary() {
    guard !Calendar.current.isDate(lastStatsDate, inSameDayAs: Date()) else { return }
    sessionsToday = 0
    totalFocusTimeToday = 0
    lastStatsDate = Date()
  }
}
