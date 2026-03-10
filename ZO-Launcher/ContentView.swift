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
    var showNumbers: Bool = false

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

            VStack(spacing: 16) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: spacing), count: columns),
                    alignment: .leading,
                    spacing: spacing
                ) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        VStack(spacing: 10) {
                            ZStack(alignment: .topLeading) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                if showNumbers && index < 9 {
                                    Text("\(index + 1)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.25))
                                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                                        )
                                        .offset(x: -4, y: -4)
                                }
                            }

                            Text(app.name)
                                .font(.system(size: fontSize))
                                .multilineTextAlignment(.center)
                                .frame(width: cellWidth)
                        }
                        .onTapGesture {
                            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
                            AppDelegate.hideApp()
                        }
                    }
                }
                .frame(width: geo.size.width)

                if showNumbers && !apps.isEmpty {
                    HStack(spacing: 4) {
                        Spacer()
                        Text("⌘")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                            )
                        Text("+")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                        Text("1–\(min(apps.count, 9))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .frame(height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                            )
                        Text("to launch")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                        Spacer()
                    }
                }
            }
            .padding(.vertical, vPadding)
        }
        .scaleEffect(isVisible ? 1 : 0.85)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
