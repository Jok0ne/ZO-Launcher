<p align="center">
  <img src="ZO-Launcher/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="128" alt="ZO-Launcher Icon">
</p>

<h1 align="center">ZO-Launcher</h1>
<p align="center"><strong>The Launchpad Apple removed — rebuilt properly.</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-26_Tahoe-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

<p align="center">
  <img src="screenshots/grid.png" width="800" alt="ZO-Launcher Grid View">
</p>

## Why?

macOS 26 Tahoe removed the Launchpad entirely. The replacement (Spotlight-based "Apps" panel) is unreliable and doesn't show all installed apps. ZO-Launcher brings back a proper fullscreen grid launcher with search, keyboard shortcuts, and customizable layout.

## Features

### Grid View
- Fullscreen overlay showing all apps from `/Applications` and `/System/Applications`
- Paged grid with smooth swipe/scroll navigation
- Configurable columns (4-10), rows (3-8), and icon size
- Page selector with numbered buttons (1, 2, 3...)
- Arrow keys, drag, or scroll wheel to switch pages

### Search

<p align="center">
  <img src="screenshots/search.png" width="800" alt="ZO-Launcher Search">
</p>

- Auto-focused search bar — just start typing
- Results displayed in same grid layout with numbered badges (1-9)
- **Enter** launches first result
- **Cmd+1-9** launches Nth result
- ESC clears search, second ESC hides launcher

### Global Hotkey
- **Ctrl+Space** toggles the launcher from anywhere
- App stays running in background, instant show/hide
- Auto-hides when clicking another app (focus loss)

### Settings (Cmd+,)

<p align="center">
  <img src="screenshots/settings.png" width="400" alt="ZO-Launcher Settings">
</p>

- Grid Columns slider (4-10)
- Grid Rows slider (3-8)
- Icon Size slider (Small/Medium/Large)
- Start at Login toggle

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Space` | Show/hide launcher (global) |
| `Esc` | Clear search / hide launcher |
| `Enter` | Launch first search result |
| `Cmd+1-9` | Launch Nth search result |
| `Arrow Left/Right` | Switch pages |
| `Cmd+,` | Open settings |

## Tech Stack

- **SwiftUI** with AppKit integration (NSViewRepresentable)
- **CGEventTap API** for global hotkey registration
- **SMAppService** for Start at Login (macOS 13+)
- **@AppStorage** for persistent user settings
- No external dependencies

## Build

Requires Xcode and an Apple Developer certificate for signing.

```bash
xcodebuild -project ZO-Launcher.xcodeproj -scheme ZO-Launcher -configuration Release
codesign --deep --force --sign "Apple Development: your@email.com (TEAM_ID)" build/Release/ZO-Launcher.app
```

## Architecture

```
ZO-Launcher/
├── ZOLauncherApp.swift          # App entry, loads apps, chunks into pages
├── AppDelegate.swift            # Global hotkey (Ctrl+Space), hide/show/toggle
├── PagedGridView.swift          # Main UI: search, paged grid, event monitors
├── ContentView.swift            # Grid layout for single page, number badges
├── SettingsView.swift           # Settings UI with sliders + login toggle
├── WindowAccessor.swift         # Fullscreen frameless floating window
└── Assets.xcassets/             # Custom rocket app icon
```

## Install

**Mac App Store** — [ZO-Launcher on the App Store](https://apps.apple.com/app/zo-launcher/id6760612327) ($2.99)

**Manual** — Download from [Releases](https://github.com/Jok0ne/ZO-Launcher/releases), move to `/Applications`, and grant Accessibility permission when prompted.

## Version History

### v1.1
- Dock icon click to show/hide launcher
- Localized app names (shows "Fotos" instead of "Photos" on German macOS)
- Auto-reload app list when launcher opens (picks up newly installed apps)
- Fixed trackpad scrolling glitch (momentum event filtering)
- Fixed click stability (stable view IDs)
- Fixed grid centering on all displays
- Migrated global hotkey from deprecated Carbon API to CGEventTap
- App Sandbox enabled

### v1.0
- Fullscreen grid launcher with paged navigation
- Live search with auto-focus
- Configurable grid (columns, rows, icon size)
- Global hotkey (Ctrl+Space)
- Cmd+1-9 quick launch from search results
- Auto-hide on focus loss
- Start at Login
- Custom app icon

---

*Built by Zerone — because Apple broke the Launchpad.*
