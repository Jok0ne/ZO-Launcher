import AppKit
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
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
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, _, event, _ -> Unmanaged<CGEvent>? in
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                // Ctrl+Space: keyCode 49 = Space, check Ctrl is pressed (no other modifiers)
                if keyCode == 49 && flags.contains(.maskControl)
                    && !flags.contains(.maskShift)
                    && !flags.contains(.maskAlternate)
                    && !flags.contains(.maskCommand) {
                    DispatchQueue.main.async {
                        AppDelegate.toggleApp()
                    }
                    return nil // consume the event
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            print("Failed to create event tap. Grant Accessibility permissions in System Settings.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    static func toggleApp() {
        if isVisible {
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
