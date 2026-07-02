import AppKit

enum AppIconState {
  case idle
  case listening
  case active
  case detecting

  init(from sessionState: SessionState, isListening: Bool = false) {
    if isListening {
      self = .listening
      return
    }
    switch sessionState {
    case .needsKey, .idle:
      self = .idle
    case .active, .snoozed:
      self = .active
    case .detecting, .detection:
      self = .detecting
    }
  }
}

enum MenuBarIcon {
  static func make(iconState: AppIconState, animPhase: CGFloat) -> NSImage {
    let size: CGFloat = 18
    let center = CGPoint(x: size / 2, y: size / 2)
    let innerRadius: CGFloat = 4.5
    let innerStroke: CGFloat = 1.5
    let outerStroke: CGFloat = 1.0
    let outerRadiusMax: CGFloat = innerRadius * 2.5

    let image = NSImage(size: NSSize(width: size, height: size))
    image.isTemplate = true
    image.lockFocus()

    // Base ring (all states)
    let innerRect = NSRect(x: center.x - innerRadius, y: center.y - innerRadius,
                           width: innerRadius * 2, height: innerRadius * 2)
    let innerPath = NSBezierPath(ovalIn: innerRect)
    innerPath.lineWidth = innerStroke
    NSColor.black.setStroke()
    innerPath.stroke()

    switch iconState {
    case .idle:
      break

    case .listening:
      let pulse = 1.0 + 0.15 * sin(CGFloat(animPhase * 4.2))
      let r = innerRadius * pulse
      let rect = NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
      let path = NSBezierPath(ovalIn: rect)
      path.lineWidth = innerStroke
      NSColor.black.setStroke()
      path.stroke()

    case .active:
      let t = (animPhase.truncatingRemainder(dividingBy: 2)) / 2
      let r = innerRadius + (outerRadiusMax - innerRadius) * t
      let alpha = 0.8 * (1 - t)

      let outerRect = NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
      let outerPath = NSBezierPath(ovalIn: outerRect)
      outerPath.lineWidth = outerStroke
      NSColor.black.withAlphaComponent(alpha).setStroke()
      outerPath.stroke()

    case .detecting:
      // Fill inner ring center
      let fillRadius = innerRadius - innerStroke / 2
      let fillRect = NSRect(x: center.x - fillRadius, y: center.y - fillRadius,
                            width: fillRadius * 2, height: fillRadius * 2)
      let fillPath = NSBezierPath(ovalIn: fillRect)
      NSColor.black.setFill()
      fillPath.fill()

      // Static outer ring
      let outerRect = NSRect(x: center.x - outerRadiusMax, y: center.y - outerRadiusMax,
                             width: outerRadiusMax * 2, height: outerRadiusMax * 2)
      let outerPath = NSBezierPath(ovalIn: outerRect)
      outerPath.lineWidth = outerStroke
      NSColor.black.withAlphaComponent(0.6).setStroke()
      outerPath.stroke()
    }

    image.unlockFocus()
    return image
  }
}
