import SwiftUI
import AppKit

// MARK: - AutoFocusSearchField
struct AutoFocusSearchField: NSViewRepresentable {
    @Binding var text: String
    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: AutoFocusSearchField
        init(_ parent: AutoFocusSearchField) {
            self.parent = parent
        }
        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSSearchField {
                parent.text = field.stringValue
            }
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(string: "")
        searchField.delegate = context.coordinator
        searchField.focusRingType = .none
        DispatchQueue.main.async {
            searchField.becomeFirstResponder()
        }
        return searchField
    }
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
}

// MARK: - Main View
struct PagedGridView: View {
    let pages: [[AppInfo]]

    @AppStorage("gridColumns") private var columns: Int = 7
    @AppStorage("iconScale") private var iconScale: Double = 0.5

    @AppStorage("gridRows") private var rows: Int = 5
    @State private var currentPage = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var lastScrollTime = Date.distantPast
    let scrollDebounceInterval: TimeInterval = 0.4
    @State private var searchText = ""
    @State private var scrollMonitor: Any?
    @State private var keyMonitor: Any?

    var body: some View {
        ZStack {
            Color.clear
                .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    AppDelegate.hideApp()
                }

            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Spacer()
                    AutoFocusSearchField(text: $searchText)
                        .background()
                        .frame(width: 250, height: 30)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
                    Spacer()
                }
                .padding(.top, 70)
                .padding(.bottom, 80)

                if searchText.isEmpty {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            ForEach(0..<pages.count, id: \.self) { pageIndex in
                                ContentView(apps: pages[pageIndex], columns: columns, iconScale: CGFloat(iconScale))
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .contentShape(Rectangle())
                                    .onTapGesture {} // Block dismiss between icons
                            }
                        }
                        .offset(x: -CGFloat(currentPage) * geo.size.width)
                        .offset(x: dragOffset)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 100), value: currentPage)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold = geo.size.width / 8
                                    let velocity = value.predictedEndTranslation.width - value.translation.width
                                    var newPage = currentPage

                                    if -value.translation.width > threshold || velocity < -100 {
                                        newPage = min(currentPage + 1, pages.count - 1)
                                    } else if value.translation.width > threshold || velocity > 100 {
                                        newPage = max(currentPage - 1, 0)
                                    }

                                    currentPage = newPage
                                }
                        )
                    }

                    // Page selector + close button
                    HStack(spacing: 20) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 100)) {
                                    currentPage = index
                                }
                            }) {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: index == currentPage ? .bold : .regular))
                                    .foregroundColor(index == currentPage ? .white : .gray)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                                    .background(
                                        Circle()
                                            .fill(index == currentPage ? Color.white.opacity(0.25) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        // Separator
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 24)

                        // Close button
                        Button(action: {
                            AppDelegate.hideApp()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .contentShape(Rectangle())
                    .onTapGesture {} // Block background dismiss tap
                    .padding(.bottom, 100)

                } else {
                    // Search results - same layout as grid pages
                    Spacer().frame(height: 60)
                    ContentView(apps: filteredApps(), columns: columns, iconScale: CGFloat(iconScale), showNumbers: true)
                        .contentShape(Rectangle())
                        .onTapGesture {}
                }
            }
        }
        .onAppear { installMonitors() }
        .onDisappear { removeMonitors() }
    }

    // MARK: - Event Monitors

    private func installMonitors() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard searchText.isEmpty else { return event }

            // Ignore trackpad momentum/inertia events
            if event.momentumPhase != [] { return event }

            let now = Date()
            if now.timeIntervalSince(lastScrollTime) < scrollDebounceInterval {
                return event
            }

            let scrollThreshold: CGFloat = 10
            let x = event.scrollingDeltaX
            let y = event.scrollingDeltaY

            // Horizontal swipe (trackpad) or vertical scroll (mouse wheel)
            if abs(x) > scrollThreshold {
                if x < -scrollThreshold {
                    currentPage = min(currentPage + 1, pages.count - 1)
                } else {
                    currentPage = max(currentPage - 1, 0)
                }
                lastScrollTime = now
                return nil
            } else if abs(y) > scrollThreshold && abs(y) > abs(x) {
                if y < -scrollThreshold {
                    currentPage = min(currentPage + 1, pages.count - 1)
                } else {
                    currentPage = max(currentPage - 1, 0)
                }
                lastScrollTime = now
                return nil
            }

            return event
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Read search field content directly (avoids stale @State capture)
            let fieldText = (NSApp.keyWindow?.firstResponder as? NSText)?.string ?? ""
            let isSearching = !fieldText.isEmpty

            // ESC: clear search first, then hide
            if event.keyCode == 53 {
                if isSearching {
                    searchText = ""
                } else {
                    AppDelegate.hideApp()
                }
                return nil
            }

            // When search is active
            if isSearching {
                let results = filteredApps()

                // Enter: launch first result
                if event.keyCode == 36 {
                    if let first = results.first {
                        launchApp(first)
                    }
                    return nil
                }

                // Cmd+1-9: launch Nth result
                if event.modifierFlags.contains(.command),
                   let chars = event.charactersIgnoringModifiers,
                   let digit = Int(chars), digit >= 1 && digit <= 9 {
                    let index = digit - 1
                    if index < results.count {
                        launchApp(results[index])
                    }
                    return nil
                }

                // Pass everything else to search field
                return event
            }

            // Grid mode: arrow keys for page navigation
            if event.keyCode == 123 { // Left
                if currentPage > 0 { currentPage -= 1 }
                return nil
            } else if event.keyCode == 124 { // Right
                if currentPage < pages.count - 1 { currentPage += 1 }
                return nil
            }

            return event
        }
    }

    private func removeMonitors() {
        if let m = scrollMonitor { NSEvent.removeMonitor(m); scrollMonitor = nil }
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    // MARK: - Helpers

    private func launchApp(_ app: AppInfo) {
        NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        searchText = ""
        AppDelegate.hideApp()
    }

    func filteredApps() -> [AppInfo] {
        let query = searchText.lowercased()
        return pages.flatMap { $0 }.filter {
            $0.name.lowercased().contains(query) || $0.bundleName.lowercased().contains(query)
        }
    }
}

// MARK: - VisualEffectView
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - AppIconView
struct AppIconView: View {
    let app: AppInfo
    @AppStorage("iconScale") private var iconScale: Double = 0.5

    var body: some View {
        let size = 60.0 * iconScale / 0.5
        VStack(spacing: 8) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(app.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: size + 30)
        .onTapGesture {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
            AppDelegate.hideApp()
        }
    }
}
