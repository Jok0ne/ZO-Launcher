import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private static var isVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerHotKey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidResignActive(_ notification: Notification) {
        AppDelegate.hideApp()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if AppDelegate.isVisible {
            AppDelegate.hideApp()
        } else {
            AppDelegate.showApp()
        }
        return false
    }

    // MARK: - Global Hotkey (Ctrl+Space)

    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5A4F4C43) // "ZOLC"
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            AppDelegate.toggleApp()
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)

        // Ctrl+Space: controlKey = 0x1000, Space = 49
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }

    static func toggleApp() {
        if let window = NSApp.windows.first(where: { $0.isVisible && !$0.title.contains("Settings") }) {
            hideApp()
        } else {
            showApp()
        }
    }

    static let reloadAppsNotification = Notification.Name("ZOLauncherReloadApps")

    static func showApp() {
        isVisible = true
        NotificationCenter.default.post(name: reloadAppsNotification, object: nil)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where !window.title.contains("Settings") {
            window.setFrame(NSScreen.main?.frame ?? .zero, display: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    static func hideApp() {
        isVisible = false
        NSApp.hide(nil)
    }
}
