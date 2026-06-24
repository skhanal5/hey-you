import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = AppMonitor()
    private let detector = DoomscrollDetector(signatures: defaultDoomscrollSignatures)

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.onAppChange = { [weak self] app in
            guard let self else { return }
            let classification = self.detector.classify(app)
            switch classification {
            case .productive:
                print("[HeyYou] 🟢 \(app.name) — productive")
            case .doomscroll(let sig):
                print("[HeyYou] 🔴 \(app.name) — \(sig.name) \(app.windowTitle.map { "(" + $0 + ")" } ?? "")")
            }
        }
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
