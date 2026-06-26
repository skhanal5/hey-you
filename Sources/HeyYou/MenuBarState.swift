import Foundation

enum MenuBarState: Equatable {
  case idle
  case listening
  case active(goals: String, triggers: Int)
  case detecting(goals: String, triggers: Int)
  case speaking(goals: String, triggers: Int)

  func settingDetecting(_ detecting: Bool) -> MenuBarState {
    switch (self, detecting) {
    case (.active(let g, let t), true):
      return .detecting(goals: g, triggers: t)
    case (.detecting(let g, let t), false):
      return .active(goals: g, triggers: t)
    case (.speaking(let g, let t), false):
      return .active(goals: g, triggers: t)
    default:
      return self
    }
  }

  func settingSpeaking(_ speaking: Bool) -> MenuBarState {
    switch (self, speaking) {
    case (.active(let g, let t), true):
      return .speaking(goals: g, triggers: t)
    case (.detecting(let g, let t), true):
      return .speaking(goals: g, triggers: t)
    case (.speaking(let g, let t), false):
      return .detecting(goals: g, triggers: t)
    default:
      return self
    }
  }
}
