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
| **Audio subsystem** | PipeWire (with WirePlumber + PulseAudio compat) |
| **Audio (T2-specific)** | apple-t2-audio-config, sof-firmware |
| **Networking** | iwd (WiFi), NetworkManager |
| **Bluetooth** | bluetooth daemon |
| **Power management** | power-profiles-daemon |
| **Suspend (T2)** | suspend-fix-t2.service (unloads apple-bce, brcmfmac_wcc, brcmfmac, touch bar modules + iwd/NM around sleep; S3 deep sleep) |
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
| **Status bar** | quickshell | Phase 3 done (weather + city, CPU, MEM, TEMP, battery, WiFi, BT live). Phase 4 (volume + tray) next. |
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

> **Note**: Shell config (`~/.config/fish/config.fish`) sets `EDITOR=ghostty` for Yazi and other TUI tools, and `SSH_AUTH_SOCK` to gpg-agent socket (required for SSH auth via gpg-agent).
> ```fish
> set -x EDITOR ghostty
> set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
> ```

---

## Theming

### Qt (qt6ct + Dolphin)

| Component | Setup |
|---|---|
| **Qt theme engine** | qt6ct (`QT_QPA_PLATFORMTHEME=qt6ct` in hyprland.conf env) |
| **Qt color scheme** | `qt6ct/colors/` in repo — `Gruvbox.conf` and `gruvbox-material-dark.conf`; deploy to `~/.config/qt6ct/colors/`. qt6ct requires `.conf` extension and QPalette ARGB format. |
| **Dolphin KDE colors** | `~/.config/dolphinrc` → `ColorScheme=GruvboxMaterialDark` — points to `~/.local/share/color-schemes/GruvboxMaterialDark.colors`. Dolphin is a KDE app and uses KDE-specific color roles (sidebar, headers, hover states) on top of the Qt palette; these come from the `.colors` file, not qt6ct. |

> **Note**: Dolphin has a known bug where it ignores qt6ct palette colors directly ([KDE Bug](https://www.mail-archive.com/kde-bugs-dist@kde.org/msg1019025.html)). The two-layer approach (qt6ct for Qt palette + KDE `.colors` file for KDE-specific roles) is required for full theming. Both files use the same Gruvbox Material Dark palette.

### GTK

GTK theming is split across multiple mechanisms depending on the app:

| Mechanism | File | Affects |
|---|---|---|
| `GTK_THEME` env var | `hyprland.conf` → `env = GTK_THEME,Gruvbox-Material-Dark` | GTK3 + GTK4 apps that inherit Hyprland's env (Brave file picker, most apps) |
| GTK4 CSS | `/usr/share/themes/Gruvbox-Material-Dark/gtk-4.0/gtk.css` | GTK4/libadwaita apps (Ghostty dialogs, etc.) — loaded automatically when `GTK_THEME` is set |
| GTK3 settings | `~/.config/gtk-3.0/settings.ini` | GTK3 apps not using gsettings |
| GTK4 settings | `~/.config/gtk-4.0/settings.ini` | GTK4 apps not using gsettings |

**Theme package**: `gruvbox-material-gtk-theme-git` (AUR) — installs to `/usr/share/themes/Gruvbox-Material-Dark/`

> **Note**: To apply GTK_THEME changes, a full Hyprland restart is required — `hyprctl reload` is not sufficient since env vars set at session start are inherited by all child processes and cannot be updated mid-session.
>
> **Note**: Brave's file picker dialog uses GTK directly (not xdg-desktop-portal-gtk). Theming it requires the `GTK_THEME` env var — Brave must inherit it from Hyprland at launch.
>
> **Note**: Brave uses two window classes — `brave-browser` for browser windows, `brave` for native OS dialogs. Hyprland windowrules must use `brave-browser` to target browser windows.

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
- Monitors configured in `hyprland.conf`: `eDP-1` (internal, 1.07x scale), `DP-2` (external, 1.2x scale, centered above)
- Terminal set to `ghostty`, file manager `dolphin`, launcher `wofi`, browser `firefox` in Hyprland config
- `kidletime` (KDE idle detection library) is installed but not actively managing idle/suspend
- Kitty and Alacritty are installed but likely leftovers (Ghostty is the primary terminal)
