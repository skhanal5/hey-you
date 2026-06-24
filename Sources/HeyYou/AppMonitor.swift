import AppKit
import ApplicationServices

final class AppMonitor {
    var onAppChange: ((AppInfo) -> Void)?
    private var previousInfo: AppInfo?

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        reportCurrentApp()
    }

    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func activeAppChanged() {
        reportCurrentApp()
    }

    private func reportCurrentApp() {
        guard let info = readFrontmostApp() else { return }
        if info != previousInfo {
            previousInfo = info
            onAppChange?(info)
        }
    }

    func readFrontmostApp() -> AppInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let name = app.localizedName,
              let bundleId = app.bundleIdentifier
        else { return nil }

        let title = readWindowTitle(pid: app.processIdentifier)
        return AppInfo(name: name, bundleId: bundleId, windowTitle: title)
    }

    private func readWindowTitle(pid: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        guard result == .success else { return nil }

        var title: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(
            focusedWindow as! AXUIElement,
            kAXTitleAttribute as CFString,
            &title
        )
        return titleResult == .success ? title as? String : nil
    }
}
