import AppKit
import SwiftUI

final class PreferencesPanel: NSWindow {
  private var isOrderingFront = false

  override func becomeKey() {
    super.becomeKey()
    guard !isOrderingFront else { return }
    isOrderingFront = true
    orderFrontRegardless()
    isOrderingFront = false
  }

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
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

    panel.title = "Preferences"
    panel.isReleasedWhenClosed = false

    panel.contentView = NSHostingView(
      rootView: PreferencesView(
        keyProvider: { KeychainService.read() },
        onSave: { key in KeychainService.save(key: key) },
        onRemove: { KeychainService.delete() },
        onClose: { [weak panel] in panel?.close() },
        onDidReadKey: { [weak panel] in
          panel?.orderFrontRegardless()
          panel?.makeKey()
        }
      )
    )
    panel.center()

    super.init(window: panel)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func show() {
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
  }
}
