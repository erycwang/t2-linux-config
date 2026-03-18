# Changes

A running log of changes made to this system — what was added, removed, or modified and why.

---

## 2026-03-18

### TokyoNight Moon theme applied across all components

Replaced Catppuccin Mocha palette with TokyoNight Moon across the entire setup:
- **quickshell bar**: BarWrapper bg (`#222436`), all widget colors updated — text (`#c8d3f5`), accent (`#82aaff`), muted (`#636da6`), green/yellow/orange/red status colors
- **mako**: bg, text, border, urgency colors updated
- **swayosd**: border, bg, progress bar colors updated
- **hyprland.conf**: active border gradient updated to blue (`#82aaff`) + purple (`#c099ff`), inactive border to `#636da6`

---

### swayosd — OSD overlays for volume and brightness

- Installed `swayosd` from `extra` repo (no AUR needed)
- `exec-once = swayosd-server` added to Hyprland autostart
- Volume/brightness keybinds replaced: `wpctl`/`brightnessctl` → `swayosd-client` (keyboard brightness stays on `brightnessctl`)
- Custom CSS at `swayosd/style.css` (symlinked to `~/.config/swayosd/style.css`): TokyoNight Moon palette, `border-radius: 12px`

---

### Screenshot workflow — clipboard-first + satty annotation

- `Super+Shift+X`: updated to `hyprshot -m region --clipboard-only` — screenshot goes to clipboard, no file saved
- `Super+Shift+A`: new keybind — `wl-paste | satty --filename -` — opens clipboard screenshot in satty for annotation; save to file or re-copy from satty
- Windowrule added: satty (`com.gabm.satty`) always opens as centered floating window at 1400×900

---

### Notification daemon — mako

- Installed `mako` (Wayland-native, minimal, no notification history panel)
- Config at `mako/config`, symlinked to `~/.config/mako/config`
- Style: Catppuccin Mocha palette (`#1e1e2e` bg, `#cdd6f4` text), `border-radius=12`, `anchor=top-right`, Noto Sans 11, 5s default timeout
- Per-urgency rules: low → muted border (`#6c7086`), 3s timeout; normal → blue border (`#89b4fa`); high → red border + text (`#f38ba8`), no timeout (persists until dismissed)
- `exec-once = mako` added to `hyprland.conf` autostart
- Test: `notify-send "Test" "Hello world"`, reload config: `makoctl reload`

---



### quickshell bar — CPU, MEM, TEMP widgets + Bluetooth indicator

- **CPU widget**: `services/Cpu.qml` reads `/proc/stat` every 1s, diffs successive idle/total values to compute usage %. Color: green < 50%, yellow 50–80%, red ≥ 80%.
- **MEM widget**: `services/Mem.qml` reads `/proc/meminfo` every 1s, computes `(MemTotal - MemAvailable) / MemTotal`. Same color thresholds.
- **TEMP widget**: `services/Temp.qml` polls `sensors -u coretemp-isa-0000` every 5s, parses `Package id 0` temp. Color: green < 60°, yellow 60–80°, red ≥ 80°.
- **Bluetooth widget**: `widgets/Bluetooth.qml` uses native `Quickshell.Bluetooth` module (no polling). Shows `BT: N` when devices connected, hides entirely (with its separator) when none.
- **Bar order**: `CPU | MEM | TEMP | BT | WiFi | Battery`
- **Note**: `Quickshell.Networking` module exists in upstream master but not v0.2.1 — no SSID property anyway, nmcli polling is still the right approach.

---

### quickshell bar — WiFi widget, battery charging color, transparency, separator

- **WiFi widget**: Added `services/Wifi.qml` — polls `nmcli -t -f active,ssid,signal dev wifi` every 30s via `Quickshell.Io.Process`. Exposes `ssid`, `signal`, `connected` properties.
- **WiFi display**: `widgets/Wifi.qml` shows `▃▅█ SSID` with 3-bar signal strength (thresholds at 40%/70%), `xxx NO NETWORK` in red when disconnected. SSID capped at 12 chars. Dropped 4-bar design — `▆` renders as full height in monospace fonts.
- **Separator widget**: Added `widgets/Separator.qml` — reusable `|` divider, use `Separator {}` between any widgets.
- **Battery charging color**: Battery text turns green (`#a6e3a1`) when charging, replacing the previous white/lavender.
- **Bar transparency**: `BarWrapper.qml` background set to 95% opacity via `Qt.rgba()` (hex colors don't support alpha readably).
- **eDP-1 scale**: Adjusted from 1.6 → 1.33 in `hyprland.conf`.

---

### Added `hyprctl reload` keybind + documented symlink config issue

- Hypr configs (`hyprland.conf`, `hypridle.conf`, `hyprlock.conf`) are symlinked from `~/.config/hypr/` to this repo
- Hyprland's inotify-based config watcher doesn't detect changes through symlinks, so auto-reload stopped working
- Fixed upstream in [hyprwm/Hyprland#9219](https://github.com/hyprwm/Hyprland/pull/9219) (merged 2025-01-31), but still not working on v0.54.2
- Added `Super+Shift+]` → `hyprctl reload` keybind as a manual workaround
- Updated `docs/setup.md` notes section

---

### quickshell Phase 1 complete — bar with clock live

- Built minimal status bar: `shell.qml` → `BarWrapper.qml` → `Bar.qml` → `widgets/Clock.qml`
- Bar renders on all monitors via `Variants { model: Quickshell.screens }`, docked top with exclusion zone
- Clock uses `SystemClock` (reactive, updates each minute) — no `new Date()` stale binding
- Added `exec-once = quickshell` to `hyprland.conf` for autostart
- Quickshell auto-discovers `~/.config/quickshell/shell.qml` (symlinked from this repo)

---

## 2026-03-16

### Suspend fix finalized — `suspend-fix-t2.service` v8

Replaced all 5 fixed `sleep` calls (7s total) with `udevadm settle`, which blocks only until pending udev events are processed. Also removed the sleep between `iwd` and NetworkManager start since `systemctl start` is synchronous.

**Exception — `sleep 2` after `modprobe apple-bce` must stay**: Apple-bce triggers USB enumeration asynchronously on the T2's virtual USB bus. `udevadm settle` returns immediately because the events haven't been queued yet. Without the sleep, the Touch Bar devices don't exist when `modprobe hid_appletb_bl/kbd` runs, breaking keyboard/trackpad on resume.

**Lesson learned**: `udevadm settle` only works when the preceding operation queues udev events synchronously (PCI rescan, modprobe brcmfmac). For async USB enumeration (apple-bce), a fixed sleep is required.

Also added suspend/resume WiFi debugging commands to `knowledge-base.md`.

---

### Installed `quickshell` + symlinked to config

- Installed `quickshell` from extra (v0.2.1 — stable, avoids AUR rebuild issues on Qt updates)
- Created `~/.config/quickshell` symlinked to `quickshell/` in this repo
- Created `quickshell/PLAN.md` with three-tier architecture and phased build plan for status bar (workspaces, clock, system info, tray)

---

### Suspend fix updated — `suspend-fix-t2.service` v7

Fixed WiFi not recovering after first resume. After v6 properly unloaded brcmfmac, the PCIe device (`0000:e5:00.0`) would get stuck in D3cold during S3 — on resume, `modprobe brcmfmac` failed with `Unable to change power state from D3cold to D0, device inaccessible` and MMIO reads returned `0xffffffff`.

**Fix**: Remove the WiFi PCI device from sysfs (`echo 1 > .../remove`) **before** suspend so the kernel's PCI power management doesn't touch it. On resume, `echo 1 > /sys/bus/pci/rescan` rediscovers the device in a clean power state and brcmfmac probes successfully.

**Latency**: Pre-suspend ~2.9s, resume ~7.2s (~10s total overhead). See `docs/suspend-latency.csv` for measurements. Fixed sleeps are the main bottleneck — replacing with `udevadm settle` is next.

Applied the same fix to `t2-suspend-fix.sh` (sleep hook, not yet deployed).

---

### Suspend fix updated — `suspend-fix-t2.service` v6

Added `modprobe -r brcmfmac_wcc` before `modprobe -r brcmfmac` in the pre-suspend sequence.

**Root cause of previous issue**: `brcmfmac_wcc` is a dependent module that holds a reference on `brcmfmac`, preventing it from unloading. Every suspend was logging `Module brcmfmac is in use`, causing brcmfmac to go through its full PCIe D3 suspend sequence instead of being cleanly unloaded — adding ~19s to suspend entry time.

Also added `t2-suspend-fix.sh` — a `/etc/systemd/system-sleep/` hook version of the same fix for future reference. Not yet deployed. The hook approach runs later in the suspend sequence (after systemd unit ordering is complete) and is simpler, but the service is what originally fixed the black-screen hang so it was patched first.

---

## 2026-03-15

### Suspend fully fixed — `suspend-fix-t2.service` v5 ✅

S3 deep sleep working. Keyboard/trackpad, WiFi, audio, Touch Bar all resume cleanly. Took 5 iterations to get right.

**Root cause**: T2 Macs require `apple-bce` (T2 bridge driver) and `brcmfmac` (WiFi) to be unloaded before suspend — otherwise the chip is unresponsive on resume. The tricky part was releasing all references to `brcmfmac` before `rmmod` could succeed.

**v1**: Created `suspend-fix-t2.service` to stop NM and rmmod brcmfmac before sleep.
- **Failed**: `rmmod brcmfmac` got "Resource temporarily unavailable" — NM held the device. Service reported success (all lines prefixed `-`) so `ExecStop` never ran on resume, leaving `apple-bce` unloaded → keyboard/trackpad dead.

**v2**: Added `systemctl stop NetworkManager` explicitly before rmmod.
- **Failed**: NM stop alone wasn't enough — device still held. WiFi went through suspend in broken state, `timed out waiting for txstatus` on resume. Touch Bar also dead (modules unmanaged).

**v3**: Added `rfkill block wifi` + 1s delay before rmmod. Added Touch Bar modules (`hid_appletb_kbd`, `hid_appletb_bl`) + 2s resume delay for `apple-bce` to init.
- **Result**: Keyboard/Touch Bar ✅. WiFi still failing — `wlan0` interface remained up after rfkill, holding a module refcount.

**v4**: Added `ip link set wlan0 down` between rfkill and rmmod. Added `rmmod -f brcmfmac brcmfmac_wcc` on resume as safety net.
- **Failed**: `rmmod` still got EBUSY. Diagnosed via journalctl: two bugs found — (1) `iwd` was never stopped (system uses iwd as WiFi backend, not wpa_supplicant — NM stop left iwd holding the device), (2) rmmod order was wrong (`brcmfmac` listed before `brcmfmac_wcc` which depends on it, so refcount was always 1).

**v5**: Added `systemctl stop iwd` after NM. Replaced `rmmod -f brcmfmac brcmfmac_wcc` with `modprobe -r brcmfmac` (resolves dep order automatically). Added `systemctl start iwd` on resume before NM.
- **Result**: ✅ Full resume. `PM: suspend entry (deep)` + `ACPI: PM: Waking up from system sleep state S3` confirmed in logs.

**Known benign resume noise** (no action needed):
- `hid-appletb-kbd: error -ENODEV: Failed to get backlight device` — timing race on BCE USB bus enumeration; Touch Bar works fine
- `brcmfmac: timed out waiting for txstatus` — transient during WiFi firmware re-init, clears within seconds
- `t2_ncm` DHCP failures — NM tries to activate the T2's internal NCM Ethernet (no DHCP server on it); harmless

---

### Configured `gnome-keyring` and secured `gh` credentials

- **What**: Installed `gnome-keyring`, autostarted via Hyprland `exec-once` with `--components=secrets` only. Re-ran `gh auth login` to move token from plaintext `hosts.yml` into the keyring.
- **Why**: GitHub token was sitting in plaintext at `~/.config/gh/hosts.yml`
- **Note**: `--components=secrets` only — `gpg-agent` handles SSH/GPG via socket activation; keyring ssh/gpg components would conflict

---

### Configured `hyprlock` + `hypridle`

- **What**: Installed and configured Hyprland-native lock screen and idle daemon
- **hyprlock**: Blurred screenshot background, centered clock + password input; bound to `Super+Shift+L`
- **hypridle**: 2 min → dim screen; 3 min → lock; 10 min → suspend. Also locks before sleep via `before_sleep_cmd`
- **Why**: No lock screen was a security gap; idle suspend also depended on this

---

---

### Installed `hyprshot` and bound screenshot key

- **What**: Installed `hyprshot` (AUR); bound `Super+Shift+X` → `hyprshot -m region` in `hyprland.conf`
- **Why**: No screenshot capability was previously installed
- **Keybind**: `$mainMod SHIFT, X` — region selection screenshot

---

### Enabled `t2fanrd` fan control daemon

- **What**: Enabled `t2fanrd` systemd service (`systemctl enable --now t2fanrd`)
- **Why**: T2 Macs need an explicit daemon to control fan speed under Linux; without it the fan runs unmanaged
- **Config**: No `/etc/t2fand.conf` created — running on defaults (linear curve, 55°C–75°C, 1350–6864 RPM)
- **Status**: Active and enabled on boot

---

### Added WiFi suspend hook

- **What**: Created `/usr/lib/systemd/system-sleep/wifi-sleep`
- **Why**: T2 Mac's `brcmfmac` WiFi driver times out during suspend, causing a blank screen on resume. Unloading it before suspend and reloading after fixes the issue.
- **How**: systemd runs all executable scripts in `/usr/lib/systemd/system-sleep/` on sleep/wake. The script unloads `brcmfmac` on `pre` (suspend) and reloads it on `post` (resume).
- **Made executable**: `sudo chmod +x /usr/lib/systemd/system-sleep/wifi-sleep`

---

### Configured `sddm.conf` for Wayland

- **What**: Created/edited `/etc/sddm.conf` with Wayland-specific settings
- **Why**: Ensures SDDM runs its greeter natively on Wayland and autologs into Hyprland
- **Settings**:
  - `Session=hyprland` — autologin directly into Hyprland
  - `DisplayServer=wayland` — SDDM greeter uses Wayland backend instead of X11
  - `GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell` — allows Qt greeter UI to use the Wayland layer-shell protocol so it displays correctly
---

### Installed `markview.nvim`

- **What**: Markdown rendering plugin for Neovim
- **Why**: Improves readability of markdown files directly in the editor — renders headings, tables, code blocks, etc. visually
- **Installed via**: lazy.nvim (`~/.config/nvim/lua/plugins/markview.lua`)
- **Config**: `lazy = false` (lazy-loading not recommended per upstream docs)
- **Note**: Works with Neovim's built-in tree-sitter; no additional parser plugin needed

---

## 2026-03-14

### Installed `hyprpolkitagent`

- **What**: Polkit authentication agent designed for Hyprland
- **Why**: Provides GUI prompts for privilege escalation (e.g. package installs, system changes) within a Hyprland session. Replaces `polkit-kde-agent` which works but isn't native to the Hyprland ecosystem.
- **Installed from**: `~/src/hyprpolkitagent` (built from source via CMake)
- **Binary**: `/usr/local/libexec/hyprpolkitagent`
- **Service**: `/usr/local/lib/systemd/user/hyprpolkitagent.service` — active, launched at session start by Hyprland (not systemd-enabled)
- **Note**: Logs a non-fatal DBus portal warning on start — does not affect functionality
