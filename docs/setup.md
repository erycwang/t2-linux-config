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

| Component | Setup |
|---|---|
| **Qt theme engine** | qt6ct (`QT_QPA_PLATFORMTHEME=qt6ct` in hyprland env) |
| **Qt color scheme** | `qt6ct/colors/` in repo — `Gruvbox.conf` (classic gruvbox) and `gruvbox-material-dark.conf`; deploy to `~/.config/qt6ct/colors/`. qt6ct requires `.conf` extension and QPalette ARGB format. |
| **GTK theme** | `Gruvbox-Material-Dark` (AUR: `gruvbox-material-gtk-theme-git`) — applied via `GTK_THEME=Gruvbox-Material-Dark` env var in hyprland.conf |
| **GTK config** | `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` set theme for apps not using gsettings |

> **Note**: Brave's file picker dialog uses GTK directly (not xdg-desktop-portal-gtk). Theming it requires `GTK_THEME` env var — Brave must inherit it from Hyprland.
>
> **Note**: Brave uses two window classes — `brave-browser` for browser windows, `brave` for native OS dialogs. Hyprland windowrules must use `brave-browser` to target browser windows.

---

## User-space Utilities

| Component | Setup |
|---|---|
| **Terminal** | Ghostty (primary) |
| **Shell** | Fish (with cachyos-fish-config) |
| **Editor** | Neovim (plugins: markview.nvim, transparent.nvim, wilder.nvim, telescope.nvim, colorscheme-persist.nvim) |
| **File manager** | Dolphin |
| **Browser** | Brave |
| **AUR helper** | Paru |
| **Firewall** | UFW |
| **Process scheduler** | ananicy-cpp |

---

## Fonts

- `ttf-meslo-nerd` — primary (Nerd Font, used in terminal)
- `noto-fonts` + `noto-fonts-cjk` + `noto-fonts-emoji` — system-wide coverage

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

## Notes

- Configs symlinked from `~/.config/` to this repo (repo is source of truth): `hypr/`, `nvim/`, `ghostty/`. Hyprland's inotify-based config watcher does not detect changes through symlinks, so auto-reload stopped working. Fixed upstream in [hyprwm/Hyprland#9219](https://github.com/hyprwm/Hyprland/pull/9219) (merged 2025-01-31). If still broken, use `Super+Shift+]` to manually reload (`hyprctl reload`).
- Monitors configured in `hyprland.conf`: `eDP-1` (internal, 1.07x scale), `DP-2` (external, 1.2x scale, centered above)
- Terminal set to `ghostty`, file manager `dolphin`, launcher `wofi`, browser `firefox` in Hyprland config
- `kidletime` (KDE idle detection library) is installed but not actively managing idle/suspend
- Kitty and Alacritty are installed but likely leftovers (Ghostty is the primary terminal)
