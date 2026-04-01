# ZO-Launcher — Known Issues & Planned Features

> Aus Full Review Session 2026-04-01. Code ist zurück auf v1.1 stable (a705f32).
> Alle Features aus der gescheiterten v1.2 Session müssen sauber neu implementiert werden.

---

## CRITICAL — Muss vor jeder neuen Arbeit gelöst werden

### C1: Konfigurierbarer Hotkey — AppDelegate liest UserDefaults nicht
- **Was:** HotkeyRecorderView speichert `hotkeyCode`/`hotkeyModifiers` in UserDefaults, aber `registerHotKey()` ist hardcoded auf Ctrl+Space (keyCode 49, maskControl)
- **Warum kaputt:** Callback ist C-Funktionspointer, kann keinen Kontext capturen. Muss statische Properties nutzen.
- **Fix:** Statische computed properties `hotkeyCode`/`hotkeyModifiers` auf AppDelegate, die aus UserDefaults lesen. Defaults: 49 / .maskControl.

### C2: Event Tap Leak bei registerHotKey() Re-Calls
- **Was:** Jeder Aufruf von `registerHotKey()` erstellt neuen CGEventTap ohne den alten zu entfernen
- **Warum kaputt:** `eventTap` und `runLoopSource` werden überschrieben ohne Cleanup
- **Fix:** Am Anfang von `registerHotKey()`: alten Tap disablen, RunLoopSource entfernen, CFMachPortInvalidate, nil setzen

### C3: Hidden Apps Type Mismatch
- **Was:** ZOLauncherApp decoded `Set<String>`, SettingsView decoded `[String]` aus dem gleichen `hiddenAppsJSON` Key
- **Warum kaputt:** Set-Serialisierung hat undefinierte Reihenfolge, kann zu Inkonsistenzen führen
- **Fix:** Einheitlich `[String]` überall verwenden, `Set` nur transient für Lookups

---

## HIGH — Muss vor Release gefixt werden

### H1: Empty Pages → currentPage = -1
- **Was:** Wenn alle Apps versteckt sind, `pages.count = 0`, `pages.count - 1 = -1`, currentPage kann negativ werden
- **Fix:** Guard `pages.count > 0` in Drag-Gesture, Scroll-Monitor und Key-Monitor

### H2: Grid overflow — keine Safezone für Page-Selector
- **Was:** Bei hohen Rows/Columns-Werten überlappt das Grid den Page-Selector und Close-Button am unteren Rand
- **Fix:** Bottom-Padding im Grid oder max Rows/Columns basierend auf Bildschirmgröße begrenzen

### H3: Cross-Page Drag & Drop geht nicht
- **Was:** `draggedApp` ist `@State` pro ContentView-Instanz (pro Seite). Drag von Seite 1 auf Seite 2 schlägt fehl.
- **Fix:** `draggedApp` State nach PagedGridView hochziehen und als @Binding durchreichen

### H4: NSWorkspace.recycle schlägt in Sandbox fehl
- **Was:** "Move to Trash" für Apps in /Applications erfordert Schreibrechte die Sandbox nicht gewährt
- **Fix:** Feature entfernen oder Error-Alert zeigen. Alternativ: "Show in Finder" als Ersatz (User kann selbst löschen)

### H5: Drag + Tap Gesture Konflikt
- **Was:** `.onDrag` + `.onTapGesture` auf gleicher View — SwiftUI kann ungenauen Tap als Drag interpretieren
- **Fix:** Evaluieren ob Drag & Drop das Usability-Risiko wert ist. Evtl. Long-Press als Drag-Trigger statt direktes onDrag.

---

## MEDIUM

### M1: Dead Code — SettingsWindowController.swift
- Ganze Datei wird nirgends instantiiert. Löschen.

### M2: Dead Code — AppIconView in PagedGridView.swift
- Struct wird nirgends verwendet. Entfernen.

### M3: Dead Code — getDesktopWallpaper() in ContentView.swift
- Funktion definiert aber nie aufgerufen. Entfernen.

### M4: JSON Encode/Decode Copy-Paste (6x DRY Violation)
- Gleicher Decode/Encode-Pattern in ZOLauncherApp + SettingsView
- Fix: Helper-Extension extrahieren

### M5: Window-Filter per String "Settings"
- `for window in NSApp.windows where !window.title.contains("Settings")` ist fragil
- Fix: Main Window mit Identifier taggen

### M6: loadApps() synchron beim Start
- Blockiert Main Thread bei vielen Apps / langsamer Disk
- Fix: Async laden, Loading-State zeigen

### M7: Font Size immer minimum 10pt
- `max(10, cellWidth * 0.04)` — Multiplikator 0.04 zu klein, fontSize fällt fast immer auf 10
- Fix: Multiplikator auf 0.08 oder feste Größe

---

## SECURITY

### S1: CGEventTap + App Sandbox Inkompatibilität
- CGEventTap (active tap) benötigt Accessibility Permission
- In Sandbox-App gibt es kein Entitlement dafür
- App Store Version funktioniert nur wenn User manuell Accessibility erteilt
- **Prüfen:** Funktioniert der Hotkey im App Store Build überhaupt?

### S2: Trash Error wird verschluckt
- `trashApp()` zeigt keinen Fehler wenn `NSWorkspace.recycle` fehlschlägt
- Fix: Alert anzeigen bei Fehler

### S3: Drag exposes File Paths via Pasteboard
- `NSItemProvider(object: app.path as NSString)` — andere Apps können den Pfad lesen
- Minimal-Risk, aber private UTType wäre sauberer

---

## Geplante Features (v1.2 — sauber neu implementieren)

- [ ] Rechtsklick-Kontextmenü (Open, Show in Finder, Hide)
- [ ] Konfigurierbarer Hotkey mit Recorder
- [ ] Apps verstecken + Unhide in Settings
- [ ] Rekursiver App-Scan (/Applications/Utilities/ etc.)
- [ ] Drag & Drop Reihenfolge (wenn H3/H5 gelöst)
- [ ] Move to Trash nur wenn außerhalb Sandbox (oder entfernen)

---

*Erstellt 2026-04-01 nach Full Review mit 3 parallelen Review-Agents.*
