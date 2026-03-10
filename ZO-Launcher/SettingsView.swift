import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var onClose: () -> Void

    @AppStorage("gridColumns") private var gridColumns: Int = 7
    @AppStorage("gridRows") private var gridRows: Int = 5
    @AppStorage("iconScale") private var iconScale: Double = 0.5
    @State private var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 24) {
                // Grid Columns
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grid Columns: \(gridColumns)")
                        .font(.headline)
                    Slider(
                        value: Binding(
                            get: { Double(gridColumns) },
                            set: { gridColumns = Int($0) }
                        ),
                        in: 4...10,
                        step: 1
                    )
                    HStack {
                        Text("4")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Grid Rows
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grid Rows: \(gridRows)")
                        .font(.headline)
                    Slider(
                        value: Binding(
                            get: { Double(gridRows) },
                            set: { gridRows = Int($0) }
                        ),
                        in: 3...8,
                        step: 1
                    )
                    HStack {
                        Text("3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Icon Size
                VStack(alignment: .leading, spacing: 8) {
                    let sizeLabel: String = {
                        if iconScale < 0.4 { return "Small" }
                        else if iconScale < 0.6 { return "Medium" }
                        else { return "Large" }
                    }()
                    Text("Icon Size: \(sizeLabel)")
                        .font(.headline)
                    Slider(value: $iconScale, in: 0.3...0.7, step: 0.05)
                    HStack {
                        Text("Small")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Large")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Start at Login
                if #available(macOS 13.0, *) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Start at Login", isOn: $launchAtLogin)
                            .font(.headline)
                            .onChange(of: launchAtLogin) { newValue in
                                do {
                                    if newValue {
                                        try SMAppService.mainApp.register()
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                    }
                                } catch {
                                    print("Login item error: \(error)")
                                    launchAtLogin = !newValue
                                }
                            }

                        Text("Hotkey: Ctrl + Space")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()

            Spacer()
        }
        .frame(minWidth: 350, minHeight: 300)
    }
}
