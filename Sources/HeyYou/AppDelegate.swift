import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)
    private lazy var dotWindow = DotWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        dotWindow.orderFront(nil)

        monitor.onAppChange = { [weak self] app in
            guard let self else { return }
            let classification = self.detector.classify(app)
            switch classification {
            case .productive:
                self.dotWindow.setColor(.systemGreen)
            case .doomscroll:
                self.dotWindow.setColor(.systemRed)
            }
        }
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
