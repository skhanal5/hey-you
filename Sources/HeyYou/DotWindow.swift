import AppKit

final class DotWindow: NSWindow {
    private let dotView: DotView

    init() {
        let size: CGFloat = 16
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.maxX - size - 16,
            y: screenFrame.maxY - size - 16
        )
        let frame = NSRect(origin: origin, size: NSSize(width: size, height: size))

        dotView = DotView(frame: NSRect(origin: .zero, size: frame.size))

        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        contentView = dotView
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        hasShadow = false
    }

    func setColor(_ color: NSColor) {
        dotView.color = color
    }
}
