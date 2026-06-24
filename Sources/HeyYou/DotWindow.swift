import AppKit

final class DotWindow: NSWindow {
    init() {
        let size: CGFloat = 16
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.maxX - size - 16,
            y: screenFrame.maxY - size - 16
        )
        let frame = NSRect(origin: origin, size: NSSize(width: size, height: size))

        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        contentView = NSView()
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        hasShadow = false
    }

    func replaceContent(with view: NSView) {
        let size = frame.size
        view.frame = NSRect(origin: .zero, size: size)
        contentView = view
    }
}
