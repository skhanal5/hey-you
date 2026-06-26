import AppKit
import SwiftUI

final class PreferencesPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.modifierFlags.contains(.command),
       let chars = event.charactersIgnoringModifiers,
       let editor = firstResponder as? NSTextView {
      switch chars {
      case "a": editor.selectAll(nil); return true
      case "c": editor.copy(nil); return true
      case "v": editor.paste(nil); return true
      case "x": editor.cut(nil); return true
      default: break
      }
    }
    return super.performKeyEquivalent(with: event)
  }
}

final class PreferencesWindowController: NSWindowController {
  init() {
    let panel = PreferencesPanel(
      contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
      styleMask: [.titled, .closable, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    panel.title = "Preferences"
    panel.isReleasedWhenClosed = false
    panel.becomesKeyOnlyIfNeeded = false
    panel.level = .modalPanel
    panel.contentView = NSHostingView(
      rootView: PreferencesView(onClose: { [weak panel] in
        panel?.close()
      })
    )
    panel.center()

    super.init(window: panel)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func show() {
    guard let panel = window else { return }
    panel.makeKeyAndOrderFront(nil)
  }
}
