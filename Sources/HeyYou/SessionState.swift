import Foundation

enum SessionState: Equatable {
  case idle
  case active(goal: String, startTime: Date, distractions: Int)
  case detection(goal: String, site: String, elapsedMinutes: Int)
}
