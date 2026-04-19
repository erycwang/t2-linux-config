# System Setup

## Hardware

- **Machine**: MacBook Pro (Apple T2)
- **CPU**: Intel Core i7-1068NG7 @ 2.30GHz
- **RAM**: 32GB
- **GPU**: Intel Iris Plus Graphics G7
- **Storage**: BTRFS

---

## System Layer (Kernel & Boot)

| Component | Setup |
|---|---|
| **Distro** | CachyOS (Arch-based, performance-optimized) |
| **Kernel** | linux-cachyos |
| **Init system** | systemd |

---

## Hardware & Driver Layer

| Component | Setup |
|---|---|
| **GPU drivers** | mesa (Intel Iris) |
| **Audio subsystem** | PipeWire (with WirePlumber + PulseAudio compat) — real-time scheduling via rtkit + `realtime` group |
| **Audio (T2-specific)** | apple-t2-audio-config, sof-firmware |
| **Networking** | iwd (WiFi), NetworkManager |
| **Bluetooth** | bluetooth daemon |
| **Power management** | power-profiles-daemon |
| **Suspend (T2)** | suspend-fix-t2.service (unloads apple-bce, brcmfmac_wcc, brcmfmac, btusb, touch bar modules + iwd/NM around sleep; PCIe cold-restart of Broadcom combo chip; bluetooth daemon restarted on resume; S3 deep sleep) |
| **Touchpad (T2)** | libinput quirks at `/etc/libinput/local-overrides.quirks` — raises palm rejection threshold to 1600, tunes touch size range |
| **Fan control (T2)** | t2fanrd (enabled, active) |
| **Storage optimization** | Snapper (BTRFS snapshots, configured for root) |

---

## Display Layer

| Component | Setup |
|---|---|
| **Display server** | Wayland (no Xorg) |
| **Compositor** | Hyprland (Wayland tiling) |
| **Display manager** | SDDM |
| **Session manager** | UWSM |

---

## Window Manager Layer (Standalone WM Setup)

| Component | Setup | Status |
|---|---|---|
| **Window manager** | Hyprland | ✅ |
| **Status bar** | quickshell | Phase 3 done (weather + city, CPU, MEM, TEMP, battery, WiFi, BT live). Phase 4 (volume + tray) next. Bar background opacity configurable in `quickshell/config/Colors.qml`. |
| **App launcher** | wofi | ✅ |
| **Notifications** | mako | ✅ top-right, 5s timeout, per-urgency rules |
| **Screenshot** | hyprshot | ✅ |
| **Wallpaper** | — | Using Hyprland default |
| **Screen lock** | hyprlock | ✅ `Super+Shift+L`; blurred screenshot + clock |
| **Idle/suspend daemon** | hypridle | ✅ 2 min dim → 3 min lock → 10 min suspend |
| **Clipboard** | wl-clipboard | ✅ |
| **Polkit agent** | hyprpolkitagent (at `/usr/local/libexec/`) | ✅ |

---

## Credential & Key Management

| Component | Setup |
|---|---|
| **Secret store** | gnome-keyring (secrets component only; autostarted via Hyprland exec-once) |
| **GPG agent** | gpg-agent (systemd user socket activation; also handles SSH via gpg-agent-ssh.socket) |
| **SSH agent** | gpg-agent (no separate ssh-agent; uses gpg-agent SSH emulation) |

> **Note**: Shell config (`~/.config/fish/config.fish`) sets `SSH_AUTH_SOCK` to gpg-agent socket (required for SSH auth via gpg-agent).
> ```fish
> set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
> ```
> `EDITOR=nvim`, `VISUAL=nvim`, and `TERMINAL=ghostty` are set in `hyprland.conf` env block so they apply to all child processes.

---

## Theming

Three separate theming layers — Qt, GTK, and libadwaita — each managed independently:

| Layer | Affects | Managed by |
|---|---|---|
| **Qt** | Dolphin, Brave file picker (uses Qt shim) | qt6ct |
| **GTK3** | GTK3 apps | nwg-look → `~/.config/gtk-3.0/settings.ini` |
| **GTK4** | GTK4 apps | nwg-look → `~/.config/gtk-4.0/settings.ini` + CSS symlink |
| **libadwaita dark mode** | Satty file picker and other libadwaita apps | gsettings `color-scheme` |

### Qt (qt6ct + Dolphin)

| Component | Setup |
|---|---|
| **Qt theme engine** | qt6ct (`QT_QPA_PLATFORMTHEME=qt6ct` in hyprland.conf env) |
| **Qt color scheme** | `qt6ct/colors/` in repo — `Gruvbox.conf` and `gruvbox-material-dark.conf`; deploy to `~/.config/qt6ct/colors/`. qt6ct requires `.conf` extension and QPalette ARGB format. |
| **Dolphin KDE colors** | `~/.config/dolphinrc` → `ColorScheme=Gruvbox-Native-Dark` — points to `~/.local/share/color-schemes/Gruvbox-Native-Dark.colors` (extracted from Gruvbox-GTK-Theme SASS palette). Dolphin is a KDE app and uses KDE-specific color roles (sidebar, headers, hover states) on top of the Qt palette; these come from the `.colors` file, not qt6ct. |
| **Dolphin icons** | `~/.config/kdeglobals` → `[Icons]` section → `Theme=Adwaita`. KDE reads icons from kdeglobals, not from dolphinrc. |

> **Note**: Dolphin has a known bug where it ignores qt6ct palette colors directly ([KDE Bug](https://www.mail-archive.com/kde-bugs-dist@kde.org/msg1019025.html)). The two-layer approach (qt6ct for Qt palette + KDE `.colors` file for KDE-specific roles) is required for full theming. The Gruvbox-Native-Dark color scheme is extracted from the Gruvbox-GTK-Theme SASS palette for color coherence with GTK apps.

> **Note**: Brave's file picker uses Qt (via `/opt/brave-bin/libqt6_shim.so`), not GTK or xdg-desktop-portal. It inherits qt6ct theming automatically.

#### Dolphin full theming setup

To apply a unified GTK + KDE theme to Dolphin:

1. **Extract color palette** from Gruvbox-GTK-Theme SASS files (`themes/src/sass/_color-palette-default.scss` and `_colors.scss`) into a KDE `.colors` file:
   ```bash
   # Create ~/.local/share/color-schemes/Gruvbox-Native-Dark.colors with KDE color scheme format
   # (see file structure in ~/.local/share/color-schemes/ for examples)
   ```

2. **Apply color scheme** in `~/.config/dolphinrc`:
   ```ini
   [UiSettings]
   ColorScheme=Gruvbox-Native-Dark
   ```

3. **Set icon theme** in `~/.config/kdeglobals` (KDE global config):
   ```ini
   [Icons]
   Theme=Adwaita
   ```

4. **Verify** — restart Dolphin. Colors should match your GTK theme, and icons should reflect the icon theme set in kdeglobals.

### GTK

GTK theming comes from two sources:

**Primary theme (nwg-look managed)**:
GTK3 and GTK4 are configured via **nwg-look**, which writes to `settings.ini` for both versions and handles the GTK4 CSS symlink.

| Component | Setup |
|---|---|
| **GTK3 theme** | `Gruvbox-Native-Dark` — set via nwg-look → `~/.config/gtk-3.0/settings.ini` |
| **GTK4 theme** | `Gruvbox-Native-Dark` — set via nwg-look → `~/.config/gtk-4.0/settings.ini` |
| **GTK4 CSS** | `~/.config/gtk-4.0/gtk.css` symlinked from the active theme |

**Alternative theme source (Gruvbox-GTK-Theme)**:
The [Gruvbox-GTK-Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme) repo in this project (`/Gruvbox-GTK-Theme/`) provides icons and additional GTK theme variants. The `gruvbox-dark-gtk` theme is available at `/usr/share/themes/gruvbox-dark-gtk/` and affects non-Brave GTK dialogs and file pickers.

> **Note**: Dolphin uses the KDE color scheme system, not GTK theme engine directly. However, its color scheme (`Gruvbox-Native-Dark.colors`) is derived from the same Gruvbox-GTK-Theme SASS palette as the GTK theme, ensuring visual consistency across the desktop.

### libadwaita

libadwaita apps (e.g. satty) ignore GTK theme settings entirely and only respond to the system color scheme preference. Set once via gsettings:

```bash
# Apply dark mode (current setting)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Revert to system default (light)
gsettings set org.gnome.desktop.interface color-scheme 'default'
```

This setting persists in dconf and survives reboots — no need to add it to `exec-once`.

---

## User-space Utilities

| Component | Setup |
|---|---|
| **Terminal** | Ghostty (primary) |
| **Shell** | Fish (with cachyos-fish-config) |
| **Editor** | Neovim (plugins: markview.nvim, transparent.nvim, wilder.nvim, telescope.nvim, colorscheme-persist.nvim) — config files in `lua/config/` must be explicitly `require()`'d in `init.lua` to be loaded (e.g. `require("config.keymaps")`) |
| **File manager** | Dolphin |
| **Browser** | Brave |
| **AUR helper** | Paru |
| **Firewall** | UFW |
| **Process scheduler** | ananicy-cpp |

---

## Fonts

- `ttf-jetbrains-mono-nerd` — primary (used in terminal, bar, hyprlock)
- `noto-fonts` + `noto-fonts-cjk` + `noto-fonts-emoji` — system-wide coverage

### Nerd Font icon codepoints

The quickshell bar uses weather icons from the Nerd Fonts weather set (`0xe300–0xe3e3`). Codepoints differ from what online references often show — always validate against the actual installed font:

```bash
# Verify what a codepoint actually renders as in your font:
python3 -c "
from fontTools.ttLib import TTFont
# ... (parse post table for glyph names at codepoints)
"
```

Key codepoints in use (validated against `JetBrainsMonoNerdFont-Regular.ttf`):

| Codepoint | Glyph name | Used for |
|---|---|---|
| `\ue30d` | `weather-day_sunny` | Clear/sunny |
| `\ue302` | `weather-day_cloudy` | Partly cloudy |
| `\ue312` | `weather-cloudy` | Cloudy/overcast/default |
| `\ue313` | `weather-fog` | Fog/mist |
| `\ue31b` | `weather-sprinkle` | Light drizzle/patchy rain |
| `\ue318` | `weather-rain` | Rain |
| `\ue319` | `weather-showers` | Heavy rain |
| `\ue316` | `weather-rain_mix` | Freezing rain/sleet mix |
| `\ue3ad` | `weather-sleet` | Sleet |
| `\ue31a` | `weather-snow` | Snow |
| `\ue35e` | `weather-snow_wind` | Blowing snow/blizzard |
| `\ue314` | `weather-hail` | Ice pellets/hail |
| `\ue31c` | `weather-storm_showers` | Thunder + light precip |
| `\ue31d` | `weather-thunderstorm` | Thunderstorm |

> **Note**: `\ue318` is `weather-rain`, NOT cloudy — a common mistake. Use `\ue312` for cloudy/overcast.

---

## File Manager Integration — Yazi in Ghostty

When apps (like Brave) call "Show in folder", they use the `inode/directory` MIME type handler. To open folders in Yazi (running inside Ghostty) instead of the default file manager:

1. **Copy the wrapper script and desktop file**:
   ```bash
   cp ~/Projects/linux-config/scripts/yazi-in-ghostty ~/.local/bin/
   mkdir -p ~/.local/share/applications
   cp ~/Projects/linux-config/scripts/yazi-custom.desktop ~/.local/share/applications/
   chmod +x ~/.local/bin/yazi-in-ghostty
   ```

2. **Set as default MIME handler**:
   ```bash
   xdg-mime default yazi-custom.desktop inode/directory
   ```

**How it works**: The wrapper script (`yazi-in-ghostty`) changes to the provided directory, then launches `ghostty -e fish -c "yazi"`. The explicit Fish shell ensures your full environment (PATH, aliases, config) loads before yazi starts.

---

## Quickshell Configuration

### Bar Background Opacity

The bar's background opacity is controlled via the `bgAlpha` property in `quickshell/config/Colors.qml`. The format is `#AARRGGBB` where the first two hex digits (AA) control opacity on a 0–255 scale.

Common opacity values (with current background color `#282828`):

| Opacity | Hex value | Example |
|---------|-----------|---------|
| 100% (fully opaque) | `ff` | `#ff282828` |
| **95% (current)** | **`f2`** | **`#f2282828`** |
| 90% | `e6` | `#e6282828` |
| 85% | `d9` | `#d9282828` |
| 80% | `cc` | `#cc282828` |
| 75% | `bf` | `#bf282828` |
| 70% | `b3` | `#b3282828` |
| 65% | `a6` | `#a6282828` |
| 60% | `99` | `#99282828` |
| 55% | `8c` | `#8c282828` |
| 50% | `80` | `#80282828` |

To adjust, edit `quickshell/config/Colors.qml:14`:
```qml
readonly property color bgAlpha: "#d9282828"  // Example: 85% opacity
```

**Important**: The window's `surfaceFormat.opaque` property must be false (the default for non-opaque colors) at startup for transparency to work. If changed later, the bar may need to be restarted.

---

## Quickshell — Hyprland IPC patterns

Patterns learned from building the bar widgets:

| Need | Approach |
|---|---|
| Reactive workspace/monitor state | Use first-class properties: `monitor.activeWorkspace`, `Hyprland.workspaces`, `Hyprland.monitors` |
| Special workspace active state | `HyprlandMonitor` does NOT expose `specialWorkspace` — use `Hyprland.rawEvent` |
| One-time init from raw IPC JSON | `monitor.lastIpcObject.specialWorkspace.id` — accurate at startup, not reactive |
| Reactive event-driven state | `Connections { target: Hyprland; function onRawEvent(event) { ... } }` |
| Parsing IPC event args | `event.parse(n)` where `n` = expected arg count — required because some args contain commas |
| Reference from inside Connections | Use explicit `id` on the parent item — `parent` is unreliable inside Connections handlers |

**`activespecial` event**: fires when a special workspace is toggled. `event.parse(2)` → `[workspaceName, monitorName]`. Empty `workspaceName` means deactivated.

**Special workspace behavior**: toggling a special workspace does NOT change `monitor.activeWorkspace` — the underlying regular workspace stays active. The special workspace is an overlay.

---

## Notes

- Configs symlinked from `~/.config/` to this repo (repo is source of truth): `hypr/`, `nvim/`, `ghostty/`. Hyprland's inotify-based config watcher does not detect changes through symlinks, so auto-reload stopped working. Fixed upstream in [hyprwm/Hyprland#9219](https://github.com/hyprwm/Hyprland/pull/9219) (merged 2025-01-31). If still broken, use `Super+Shift+]` to manually reload (`hyprctl reload`).
- Monitors configured in `hyprland.conf`: `eDP-1` (internal, 1.33x scale), `DP-2` (external, 1.07x scale, centered above)

### Monitor scale

**Two places must stay in sync** whenever eDP-1 scale changes:
1. `monitor = eDP-1, preferred, auto, <scale>` — sets scale at startup
2. `bindl = , switch:off:Lid Switch, exec, hyprctl keyword monitor eDP-1,preferred,auto,<scale>` — re-applies scale when lid opens

If they drift, opening the lid after suspend will momentarily apply the wrong scale and trigger a layout recalculation.
- Terminal set to `ghostty`, file manager `dolphin`, launcher `wofi`, browser `firefox` in Hyprland config; `TERMINAL=ghostty`, `EDITOR=nvim`, `VISUAL=nvim` set as env vars
- **PipeWire RT scheduling**: requires `realtime-privileges` + `rtkit` packages, user in `realtime` group, and `rtkit-daemon` enabled. Without this, `mod.rt: could not set nice-level to -11: Permission denied` appears every boot and demanding codecs (LDAC) stutter. Set profile via `pactl set-card-profile <card> <profile>` — not `wpctl set-profile` (wpctl uses numeric indices, pactl uses names).
- **WH-1000XM3 Bluetooth**: LDAC (`a2dp-sink`) is the preferred profile — works on clean boot and after suspend (requires the btusb cycle in `suspend-fix-t2.service`). Profile persisted in `~/.local/state/wireplumber/default-profile`. Root cause of post-suspend LDAC stutter: Broadcom BCM4364 is a combo Wi-Fi+BT chip sharing the 2.4GHz antenna — see `docs/changes.md` § 2026-03-30 suspend entry.
- `kidletime` (KDE idle detection library) is installed but not actively managing idle/suspend
- Kitty and Alacritty are installed but likely leftovers (Ghostty is the primary terminal)


For the wifi, I set the fiOs network to autoconnect using nmcli commands. I also have a new file that overwrites or hides t2 wifi


