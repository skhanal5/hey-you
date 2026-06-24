import AppKit

final class DotView: NSView {
    var color: NSColor = .systemGreen {
        didSet { layer?.backgroundColor = color.cgColor }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = frame.width / 2
        layer?.backgroundColor = color.cgColor
        menu = makeMenu()
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let origin = window.frame.origin
        window.setFrameOrigin(
            NSPoint(x: origin.x + event.deltaX, y: origin.y - event.deltaY)
        )
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit HeyYou", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        return menu
    }
}
