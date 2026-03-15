import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

@main
struct ZOLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var apps: [AppInfo] = Self.loadApps()
    @State private var showSettings = false

    @AppStorage("gridColumns") private var gridColumns: Int = 7
    @AppStorage("iconScale") private var iconScale: Double = 0.5

    @AppStorage("gridRows") private var gridRows: Int = 5

    var pageSize: Int { gridColumns * gridRows }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .topTrailing) {
                WindowAccessor()
                PagedGridView(pages: apps.chunked(into: pageSize))
                    .frame(minWidth: 800, minHeight: 600)
                    .ignoresSafeArea()
                    .sheet(isPresented: $showSettings) {
                        SettingsView {
                            showSettings = false
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: AppDelegate.reloadAppsNotification)) { _ in
                        apps = Self.loadApps()
                    }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }

    static func loadApps() -> [AppInfo] {
        let appPaths = ["/Applications", "/System/Applications"]
        var foundApps: [AppInfo] = []

        for basePath in appPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let fullPath = basePath + "/" + item
                let bundleName = item.replacingOccurrences(of: ".app", with: "")
                let url = URL(fileURLWithPath: fullPath)
                let localizedName = (try? url.resourceValues(forKeys: [.localizedNameKey]))?.localizedName?.replacingOccurrences(of: ".app", with: "") ?? bundleName
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                icon.size = NSSize(width: 64, height: 64)
                foundApps.append(AppInfo(name: localizedName, bundleName: bundleName, icon: icon, path: fullPath))
            }
        }

        return foundApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}

struct AppInfo: Identifiable {
    var id: String { path }
    let name: String
    let bundleName: String
    let icon: NSImage
    let path: String
}
