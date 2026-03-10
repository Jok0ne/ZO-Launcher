import SwiftUI
import AppKit

func getDesktopWallpaper() -> NSImage? {
    guard let screen = NSScreen.main else { return nil }
    if let url = NSWorkspace.shared.desktopImageURL(for: screen),
       let image = NSImage(contentsOf: url) {
        return image
    }
    return nil
}

struct ContentView: View {
    let apps: [AppInfo]
    let columns: Int
    let iconScale: CGFloat

    @State private var isVisible = false

    var body: some View {
        GeometryReader { geo in
            let aspect = geo.size.width / geo.size.height
            let hPadding = geo.size.width * 0.06
            let vPadding: CGFloat = {
                if aspect > 2.0 {
                    return geo.size.height * 0
                } else if geo.size.height < 800 {
                    return geo.size.height * 0.05
                } else {
                    return geo.size.height * 0.08
                }
            }()
            let spacing: CGFloat = {
                if aspect > 2.0 {
                    return geo.size.height * 0.02
                } else if geo.size.height < 800 {
                    return geo.size.height * 0.04
                } else {
                    return geo.size.height * 0.03
                }
            }()
            let totalSpacing = CGFloat(columns - 1) * spacing
            let cellWidth = (geo.size.width - (hPadding * 2) - totalSpacing) / CGFloat(columns)
            let iconSize = cellWidth * iconScale
            let fontSize = max(10, cellWidth * 0.04)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: spacing), count: columns),
                alignment: .leading,
                spacing: spacing
            ) {
                ForEach(apps) { app in
                    VStack(spacing: 10) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text(app.name)
                            .font(.system(size: fontSize))
                            .multilineTextAlignment(.center)
                            .frame(width: cellWidth)
                    }
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
                        NSApp.terminate(nil)
                    }
                }
            }
            .frame(width: geo.size.width)
            .padding(.vertical, vPadding)
        }
        .scaleEffect(isVisible ? 1 : 0.85)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
