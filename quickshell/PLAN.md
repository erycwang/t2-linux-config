# Quickshell Status Bar — Plan

## Goal

Build a Hyprland status bar with quickshell using an architecture that scales to OSD, notifications, launcher, etc. later. Includes an interactive theme switcher with named palettes.

---

## Architecture

Three-tier layout: **services** (data singletons) → **components** (shared UI primitives) → **modules** (features).

The three tiers pay off once you have multiple widgets sharing data (e.g. Volume widget and OSD both reading `Audio.volume`) and multiple future modules (OSD, notifications, launcher) all reusing the same service layer without duplication.

```
quickshell/
  shell.qml                          # Root: ShellRoot, loads bar + theme switcher modules
  config/
    qmldir
    Config.qml                       # Singleton — bar height, spacing, font sizes
  services/
    qmldir                           # Registers all singletons
    Time.qml                         # Singleton — clock
    Audio.qml                        # Singleton — PipeWire wrapper
    Network.qml                      # Singleton — nmcli via Process
    Hypr.qml                         # Singleton — Hyprland IPC helpers
  theme/
    qmldir
    Theme.qml                        # Singleton — current palette, reactive color properties
    ThemeSwitcher.qml                # Interactive switcher UI panel (toggled via IPC)
    DefaultTheme.qml                 # Fallback palette (used if Theme singleton unavailable)
    themes.json                      # Array of named palettes (~14 color fields each)
  components/                        # Shared UI building blocks
    qmldir
    PillContainer.qml                # Rounded-rect group wrapper
  modules/
    bar/
      qmldir
      BarWrapper.qml                 # Variants (multi-monitor) + PanelWindow + popup windows
      Bar.qml                        # Pure layout: left / center / right sections
      widgets/
        Clock.qml
        Workspaces.qml
        Battery.qml
        Volume.qml
        Network.qml
        SystemTray.qml
```

### Key patterns

- **Singletons for data**: `Config`, `Theme`, and all services are `pragma Singleton` + registered in `qmldir`. Accessible anywhere without prop drilling.
- **Multi-monitor**: `BarWrapper.qml` uses `Variants { model: Quickshell.screens }` to stamp one bar per monitor.
- **Popup windows**: Instantiated once in `BarWrapper`, not inside the `Variants` loop — prevents N copies on N monitors.
- **Layout separation**: `BarWrapper` owns PanelWindow lifecycle; `Bar.qml` is pure layout.
- **Extensibility**: New widget = one file in `widgets/` + one line in `Bar.qml`. New module (OSD, notifications) = new folder under `modules/`.
- **qmldir manifests**: Every directory with importable types gets a `qmldir`. Required for singleton registration and IDE resolution.

---

## Phases

### Phase 1: Bar with clock — get something on screen ← START HERE

Minimal viable bar. No theming, no services, no system info. Just validates the scaffold, Hyprland integration, and multi-monitor setup.

1. Create `shell.qml` — `ShellRoot` that loads `BarWrapper`
2. Create `modules/bar/BarWrapper.qml` — `Variants { model: Quickshell.screens }` wrapping a `PanelWindow` anchored top
3. Create `modules/bar/Bar.qml` — `RowLayout` with hardcoded colors for now
4. Create `modules/bar/widgets/Clock.qml` — time display using `SystemClock` or a `Timer`
5. Add `exec-once = quickshell` to Hyprland config
6. **Test**: bar appears on screen, clock shows and ticks

### Phase 2: Workspaces + layout structure

7. Create `config/Config.qml` singleton — bar height, font, padding; `config/qmldir`
8. Extend `Bar.qml` to left / center / right sections
9. Create `modules/bar/widgets/Workspaces.qml` — `Repeater` over `Hyprland.workspaces`, highlight active, click to switch
10. **Test**: workspaces highlight on switch, click to jump works

### Phase 3: System info (volume + battery + network) ← IN PROGRESS

11. Create `services/Audio.qml` — PipeWire singleton; exposes `volume`, `muted`, `setVolume()`, `toggleMute()`; `services/qmldir`
12. Create `modules/bar/widgets/Volume.qml` — icon + percentage, scroll to adjust
13. ~~Create `modules/bar/widgets/Battery.qml` — UPower capacity + charging icon~~ ✅ Done
14. Create `services/Network.qml` — `Process` polling `nmcli` for SSID and connection state
15. Create `modules/bar/widgets/Network.qml` — connected/disconnected + SSID label
16. **Test**: volume changes reflect live, battery shows state, network shows SSID

### Phase 4: Tray + polish

17. Create `modules/bar/widgets/SystemTray.qml` — StatusNotifier items
18. Create `components/PillContainer.qml` — shared rounded-rect wrapper used by widget groups
19. Refine spacing, font sizing, icon sizes using `Config` values
20. Add popup windows for volume/network where useful (instantiated in `BarWrapper`, not inside `Variants`)
21. **Test**: tray icons appear, popups open on correct monitor

### Phase 5: Theme switcher

22. Create `theme/DefaultTheme.qml` — static QtObject with hardcoded color fields
23. Create `theme/themes.json` — initial palettes (Catppuccin Mocha, Tokyo Night, Gruvbox, Nord)
24. Create `theme/Theme.qml` — singleton that reads `themes.json`, exposes color properties; `theme/qmldir`
25. Create `theme/ThemeSwitcher.qml` — searchable list panel, keyboard navigable, hover preview, Enter to commit
26. Wire `Theme.qml` to save/load current index from `~/.config/quickshell/theme.conf`
27. Add `IpcHandler { target: "theme" }` in `shell.qml` to toggle the switcher
28. Migrate widget colors from hardcoded values to `Theme.*` properties
29. **Test**: switcher opens, live preview on hover, persists across restarts

### Future modules (not in scope now)

- OSD overlays (volume/brightness) — `modules/osd/`
- Notifications daemon — `modules/notifications/`
- App launcher — `modules/launcher/`
- Terminal theme sync (apply palette to kitty on theme switch)

---

## References

- [Official guide (v0.2.1)](https://quickshell.org/docs/v0.2.1/guide/introduction/)
- [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) — theme switcher + DefaultTheme pattern
- [tripathiji1312/quickshell](https://github.com/tripathiji1312/quickshell) — three-tier service/component/module architecture
- [Tony's bar tutorial](https://www.tonybtw.com/tutorial/quickshell/)
