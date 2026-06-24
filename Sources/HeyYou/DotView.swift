import AppKit

final class DotView: NSView {
    var color: NSColor = .systemGreen {
        didSet { updateColor() }
    }

    var isListening = false {
        didSet { updateListeningState() }
    }

    var isSessionActive = false {
        didSet { needsDisplay = true }
    }

    var onStartSession: (() -> Void)?
    var onEndSession: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = frame.width / 2
        updateColor()
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let origin = window.frame.origin
        window.setFrameOrigin(
            NSPoint(x: origin.x + event.deltaX, y: origin.y - event.deltaY)
        )
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        if isSessionActive {
            menu.addItem(NSMenuItem(title: "End Session", action: #selector(endSessionAction), keyEquivalent: ""))
            menu.addItem(.separator())
        } else {
            menu.addItem(NSMenuItem(title: "Start Session", action: #selector(startSessionAction), keyEquivalent: "s"))
            menu.addItem(.separator())
        }
        menu.addItem(NSMenuItem(title: "Quit HeyYou", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        return menu
    }

    @objc private func startSessionAction() {
        onStartSession?()
    }

    @objc private func endSessionAction() {
        onEndSession?()
    }

    private func updateColor() {
        if isListening {
            layer?.backgroundColor = NSColor.systemBlue.cgColor
        } else {
            layer?.backgroundColor = color.cgColor
        }
    }

    private func updateListeningState() {
        if isListening {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.3
            pulse.duration = 0.6
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            layer?.add(pulse, forKey: "pulse")
            updateColor()
        } else {
            layer?.removeAnimation(forKey: "pulse")
            layer?.opacity = 1.0
            updateColor()
        }
    }
}
