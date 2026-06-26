import Foundation

enum MenuBarState: Equatable {
  case idle
  case listening
  case active(goals: String, triggers: Int)
  case detecting(goals: String, triggers: Int)
  case speaking(goals: String, triggers: Int)
}
