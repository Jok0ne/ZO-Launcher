//
//  WindowAccessor.swift
//  ZO-Launcher
//
//  ZO-Launcher by Zerone
//


import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.styleMask.remove(.resizable)
                window.styleMask.remove(.titled)
                window.styleMask.insert(.fullSizeContentView)
                window.collectionBehavior.insert(.fullScreenPrimary)
                window.level = .floating
                window.setFrame(NSScreen.main?.frame ?? .zero, display: true)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
