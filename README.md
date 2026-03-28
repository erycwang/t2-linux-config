# linux-config

Personal dotfiles and system configuration for a 2020 MacBook Pro (Apple T2) running CachyOS (Arch-based) with Hyprland.

## Desktop Environment

**Compositor**: [Hyprland](https://hyprland.org/) (Wayland tiling WM)
**Display manager**: SDDM + UWSM
**Terminal**: Ghostty
**Notifications**: mako
**App launcher**: wofi
**Lock screen**: hyprlock (via hypridle)

### Status Bar

The status bar is built with [Quickshell](https://quickshell.org/), a Qt/QML-based shell toolkit. Widgets include:

- Workspaces (with special workspace indicator)
- Clock and date
- Weather (via wttr.in — no API key required)
- CPU, memory, temperature
- Battery, WiFi, Bluetooth

Configuration lives in `quickshell/`. The bar layout is in `quickshell/modules/bar/`, services (data sources) are in `quickshell/services/`, and shared config (font, sizing) is in `quickshell/config/Config.qml`.

### Theming

Theme is **Gruvbox Material Dark**, applied consistently across:

- Hyprland (border colors via `hypr/colors.conf`)
- Quickshell status bar (QML colors via `quickshell/config/Colors.qml`)
- mako notifications (`mako/config`)
- swayosd (`swayosd/style.css`)
- GTK (Gruvbox Material GTK theme)
- Qt (`qt6ct/colors/gruvbox-material-dark.conf`)
- Ghostty terminal (`ghostty/auto/theme.ghostty`)

Theming is driven by `theme/apply.sh`, which sources a theme definition file (`theme/gruvbox-material-dark.sh` or `theme/tokyo-night-moon.sh`) and uses `envsubst` to populate `.template` files across the repo. To switch themes:

```bash
./theme/apply.sh theme/gruvbox-material-dark.sh
```

## T2 Suspend Fix

MacBook Pro T2 models require specific kernel modules to be unloaded before suspend and reloaded after resume to avoid kernel panics and hardware hangs. Two files handle this:

| File | Purpose |
|---|---|
| `suspend-fix-t2.service` | Systemd unit that runs `Before=sleep.target`. Stops NetworkManager/iwd, unloads `brcmfmac`, `apple-bce`, `aaudio`, and touch bar modules pre-suspend; reloads them in reverse order on resume. |
| `t2-suspend-fix.sh` | Shell script called by the service to perform the actual module unloading/loading and rfkill handling. |

To install the service:

```bash
sudo cp suspend-fix-t2.service /etc/systemd/system/
sudo systemctl enable --now suspend-fix-t2.service
```

Fan control is handled separately by `t2fanrd`, with config at `t2fand.conf`.

## Docs

The `docs/` folder contains running notes on this system:

- **`changes.md`** — changelog of what was added, removed, or modified and why
- **`setup.md`** — full system component overview (hardware, drivers, display stack, apps)
- **`display-manager-architecture.md`** — notes on the SDDM + UWSM + Hyprland session setup
- **`knowledge-base.md`** — reference notes on tools and configs
- **`todo.md`** — in-progress and planned work

A `troubleshooting-notes` file at the repo root logs specific incidents with root cause analysis and fixes.

## Other Config

| Path | What it configures |
|---|---|
| `hypr/` | Hyprland, hyprlock, hypridle, hyprpaper |
| `nvim/` | Neovim (lazy.nvim plugin manager) |
| `mako/` | Notification daemon |
| `ghostty/` | Terminal emulator |
| `libinput/local-overrides.quirks` | Touchpad palm rejection and touch size tuning |
| `scripts/` | Miscellaneous helper scripts |
| `kde-gruvbox-git/` | AUR PKGBUILD for the KDE Gruvbox color scheme (used for GTK theming) |
