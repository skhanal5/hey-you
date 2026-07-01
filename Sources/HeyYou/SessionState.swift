import Foundation

enum SessionState: Equatable {
  case needsKey
  case idle
  case active(goal: String, startTime: Date, distractions: Int)
  case detection(goal: String, site: String, fireCount: Int, elapsedMinutes: Int, spokenMessage: String)
}
