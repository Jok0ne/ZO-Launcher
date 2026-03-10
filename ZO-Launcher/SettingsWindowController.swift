//
//  SettingsWindowController.swift
//  ZO-Launcher
//
//  ZO-Launcher by Zerone
//


import SwiftUI
import AppKit

class SettingsWindowController: ObservableObject {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let settingsView = SettingsView{
                self.window?.close()
            }

            let hostingController = NSHostingController(rootView: settingsView)
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window?.isReleasedWhenClosed = false
            window?.contentViewController = hostingController
            window?.title = "ZO-Launcher Settings"
            window?.level = .floating
            window?.center()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
