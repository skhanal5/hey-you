import AppKit

enum AppIconState {
  case idle
  case active
  case detecting

  init(from state: MenuBarState) {
    switch state {
    case .idle, .listening:
      self = .idle
    case .active:
      self = .active
    case .detecting, .speaking:
      self = .detecting
    }
  }

  var color: NSColor {
    switch self {
    case .idle: return .systemGreen
    case .active: return .systemYellow
    case .detecting: return .systemRed
    }
  }
}

enum MenuBarIcon {
  static func make(iconState: AppIconState, animPhase: CGFloat) -> NSImage {
    let size: CGFloat = 16
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let color: NSColor
    switch iconState {
    case .idle:
      color = .systemGreen
    case .active:
      color = .systemYellow
    case .detecting:
      if sin(animPhase * 8) > 0 {
        color = .systemRed
      } else {
        color = NSColor.systemRed.withAlphaComponent(0.4)
      }
    }

    let rect = NSRect(x: 2, y: 2, width: size - 4, height: size - 4)
    let path = NSBezierPath(ovalIn: rect)
    color.setFill()
    path.fill()

    image.unlockFocus()
    return image
  }
}
