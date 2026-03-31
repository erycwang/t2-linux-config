# Changes

A running log of changes made to this system — what was added, removed, or modified and why.

---

## 2026-03-30

### suspend-fix-t2.service — add btusb cycle (LDAC stutter not resolved)

**Symptom**: WH-1000XM3 LDAC audio stutters heavily after a suspend-resume cycle. AAC works but LDAC does not. On a clean boot, LDAC works perfectly.

**Root cause**: The Broadcom BCM4364 is a combo chip — Wi-Fi (brcmfmac) and Bluetooth (btusb) share the same physical silicon and 2.4GHz antenna. On resume, the Wi-Fi driver aggressively rescans for networks, hogging the shared antenna. LDAC requires up to 990 kbps of uninterrupted 2.4GHz bandwidth; AAC needs ~256 kbps and scrapes through. The existing service already did a PCIe cold-restart of the combo chip for Wi-Fi. However, `btusb` was left loaded across suspend, so Bluetooth did a "warm wake" while Wi-Fi did a cold reset — this desynchronized the coexistence firmware that time-slices the 2.4GHz antenna between radios.

**Fix**: Add `btusb` to the module unload/reload cycle so both the Wi-Fi and Bluetooth sides undergo a cold restart together through the existing PCIe remove/rescan sequence. Also restart `bluetooth.service` on resume so BlueZ renegotiates the A2DP profile with PipeWire cleanly.

**Changes to `suspend-fix-t2.service`**:
- Pre-suspend: `rfkill block wifi` → `rfkill block wifi bluetooth`; `modprobe -r brcmfmac` → `modprobe -r brcmfmac btusb`
- Post-resume: `modprobe brcmfmac brcmfmac_wcc btusb` (combined; modprobe handles dep order — `brcmfmac_wcc` depends on `brcmfmac`); `rfkill unblock wifi` → `rfkill unblock wifi bluetooth`; added `systemctl restart bluetooth`

**Result**: ❌ Did not fix the issue. LDAC stutter persists after suspend. Root cause still unknown.

**Follow-up changes (attempting to fix LDAC)**:
- Added `systemctl stop bluetooth` at the top of pre-suspend sequence — stops BlueZ before btusb is unloaded
- Added `sleep 1` after PCI rescan on resume — gives the Broadcom chip time to initialize before modprobe runs
- Added `sleep 1` after `modprobe brcmfmac brcmfmac_wcc btusb` on resume — gives drivers time to settle before networking/bluetooth services start

### quickshell bar — interactive bluetooth indicator with paired device popup

**Feature**: The bluetooth widget is now always visible and clickable, showing paired devices in a popup when clicked.

**Details**:
- Widget displays `󰂯` (icon) when no devices connected, `󰂱 N` when N devices connected
- Icon color: `Colors.muted` when disconnected, `Colors.accent` when connected
- Click indicator → fullscreen overlay popup appears anchored top-right below the bar
- Popup lists paired devices with connect/disconnect toggle (via `bluetoothctl`)
- Click outside popup or on the indicator again → popup closes
- Single popup instance at ShellRoot level using `WlrLayer.Overlay` to prevent duplication on multi-monitor

**Implementation**:
- New singleton: `services/BluetoothPopupState.qml` (state: `open`, `popupScreen`, `toggle()`, `close()`)
- New popup: `modules/bar/BluetoothPopup.qml` (fullscreen PanelWindow with device list)
- Updated widget: `modules/bar/widgets/Bluetooth.qml` (always visible, clickable, larger hit target)
- Updated bar: `modules/bar/Bar.qml` (wire click signal to popup state)
- Updated root: `modules/bar/shell.qml` (add BluetoothPopup instance)

---

### hyprland — fix lid switch scale out of sync with monitor config

**Symptom**: Opening the laptop lid after suspend re-enabled eDP-1 at scale 1.25 instead of 1.33, causing a brief layout recalculation.

**Root cause**: The `switch:off:Lid Switch` binding hardcodes the eDP-1 scale. When the monitor config scale was bumped from 1.25 → 1.33 in a later commit, the lid switch binding was not updated.

**Fix**: Changed scale in lid switch binding to match `monitor = eDP-1` line.

> **Note**: These two settings must stay in sync — see `setup.md` § Monitor scale.

---

## 2026-03-28

### swayosd — add user to `input` and `uinput` groups

**Symptom**: `swayosd-server` crashes with SIGSEGV inside `libgtk-4.so` shortly after startup. Journal shows `SwayOSD LibInput Backend isn't available, waiting...` on launch.

**Root cause**: swayosd uses libinput to detect keyboard state (capslock/numlock). Without membership in the `input` group, it can't access `/dev/input` devices — the backend hangs waiting, and swayosd eventually segfaults in GTK4.

**Fix**:
```bash
sudo usermod -aG input $USER
# log out and back in for group membership to take effect
```

---

### PipeWire — real-time scheduling fix (Bluetooth audio stuttering)

**Symptom**: WH-1000XM3 Bluetooth headset stuttering heavily, especially with LDAC codec. `journalctl --user -u pipewire` showed `mod.rt: could not set nice-level to -11: Permission denied` on every boot.

**Root cause**: PipeWire's `mod.rt` module requests real-time scheduling via rtkit, but rtkit only grants it to members of the `realtime` group. `rtkit` was installed but `realtime-privileges` (which creates the group + udev rules) was not, and the user was not in the group.

**Fix**:
```bash
sudo pacman -S realtime-privileges
sudo usermod -a -G realtime $USER
sudo systemctl enable --now rtkit-daemon
# then log out and back in for group membership to take effect
```

**What each step does**:
- `realtime-privileges` — creates the `realtime` group and udev rules granting group members permission to request RT scheduling
- `usermod -a -G realtime` — adds user to the group (requires logout to take effect)
- `systemctl enable --now rtkit-daemon` — starts rtkit and enables it on boot; PipeWire's `mod.rt` talks to it over D-Bus to elevate audio thread priority

**Bluetooth headset profile** (WH-1000XM3 accidentally set to `off` via `wpctl set-profile 119 0`):
- Restored with: `pactl set-card-profile bluez_card.38_18_4C_4B_25_6A a2dp-sink-aac`
- Tried LDAC (`a2dp-sink`) first but it requires RT scheduling to run cleanly — switched to AAC (`a2dp-sink-aac`) which is less demanding and lower latency
- After RT fix, LDAC is also viable if preferred: `pactl set-card-profile bluez_card.38_18_4C_4B_25_6A a2dp-sink`
- WirePlumber state file at `~/.local/state/wireplumber/default-profile` persists the chosen profile across reboots
- **Final validated state**: LDAC (`a2dp-sink`) running stutter-free with RT scheduling active. No `mod.rt` errors in `journalctl --user -u pipewire` after fix.

---

## 2026-03-20

### Quickshell — workspace bar improvements

- Added workspace 10 to the repeater (was capped at 9)
- Added special workspace dot indicator: appears when any special workspace exists, highlights when active
- Special workspace detection uses `Hyprland.rawEvent` listening for `activespecial` IPC events (args[0]=workspace name, args[1]=monitor name) — empty name means deactivated
- Initial state seeds from `monitor.lastIpcObject.specialWorkspace.id` at startup
- **Key learnings**:
  - `HyprlandMonitor` does not expose `specialWorkspace` as a first-class property — only `activeWorkspace`
  - `lastIpcObject` has the full raw IPC JSON but is not reactive to state changes — only accurate at initialization
  - Use `Hyprland.rawEvent` + `event.parse(n)` for reactive event-driven state updates
  - `activeWorkspace` never changes when a special workspace is toggled — it stays on the underlying regular workspace
  - Inside a `Connections` block, use an explicit `id` reference rather than `parent` to avoid binding issues

### Hyprland — monitor scale + blur tuning

- `eDP-1` scale updated from `1.25` → `1.33`
- Blur: `size 15, passes 1` → `size 7, passes 2` (sharper, more performant)

### Ghostty — background opacity

- `background-opacity` reduced from `0.92` → `0.88`

### Weather widget — icon color

- Weather icon color changed from `Colors.accent` (teal) to `Colors.fg` (matches text)

---

## 2026-03-19

### Weather widget — icon fixes and full wttr.in code mapping

- Fixed wrong Nerd Font codepoints: `\ue318` is `weather-rain` (not cloudy) — overcast/default now uses `\ue312` (`weather-cloudy`); `\ue314` is `weather-hail` (not light rain) — light rain now uses `\ue318`
- Fixed fallback icon in `Weather.qml` widget from `\ue318` (rain) to `\ue312` (cloud)
- Expanded `codeToIcon` to cover all wttr.in weather codes — previously missing: freezing rain, sleet, blowing snow, ice pellets, snow showers, rain showers, thunder variants
- **Root cause found**: icons were wrong because `\ue318` was assumed to be cloudy but is actually rain in this Nerd Font version

---

### Hyprland — hypridle restarts on config reload

- Changed `exec-once = hypridle` → `exec = pkill -x hypridle; hypridle &`
- Matches the same pattern used for quickshell and hyprpaper — `hyprctl reload` now restarts hypridle, picking up config changes without a full Hyprland restart

---

### Hyprland — Super+V float toggle scales to monitor

- `Super+V` now uses `resizeactive exact 50% 50%` instead of hardcoded `800 600`
- Window floats at 50% of the current monitor's dimensions, centered
- Also added state detection: if window is already floating, `Super+V` tiles it back and resets split ratio to 50/50 (`splitratio exact 1`)

---

### hyprlock — font updated to JetBrains Mono Nerd Font

- Clock label font changed from `MesloLGM Nerd Font` to `JetBrainsMono Nerd Font` for consistency

---

### Hyprland — lid close disables internal display when external monitor is connected

- Added `bindl` handlers for `switch:on:Lid Switch` and `switch:off:Lid Switch`
- On lid close: checks if more than 1 monitor is active (`hyprctl monitors -j | jq length`); if so, disables `eDP-1` via `hyprctl keyword monitor eDP-1,disable` — this also migrates workspaces to the external monitor
- On lid open: re-enables `eDP-1` with original settings (`preferred, auto, 1.25` scale)
- Guard prevents disabling the display if no external monitor is connected

---

### Theming — Dolphin KDE color scheme

- Changed `ColorScheme=Gruvbox` → `ColorScheme=GruvboxMaterialDark` in `~/.config/dolphinrc`
- Points Dolphin's KDE-specific color roles (sidebar, headers, hover states) at `~/.local/share/color-schemes/GruvboxMaterialDark.colors` instead of `/usr/share/color-schemes/Gruvbox.colors`
- **Why two layers**: Dolphin ignores qt6ct palette colors directly (known KDE bug). qt6ct handles the standard Qt palette; the KDE `.colors` file handles KDE-specific roles. Both now use the same Gruvbox Material Dark palette.
- Restart Dolphin to apply.

---

### Theming — Gruvbox Material Dark GTK + qt6ct color schemes

- **GTK theme**: Switched from `gruvbox-dark-gtk` to `Gruvbox-Material-Dark` (AUR: `gruvbox-material-gtk-theme-git`). Updated `GTK_THEME` env var in `hyprland.conf`. Applies to Brave's file picker dialog and other GTK apps.
- **qt6ct color schemes**: Rewrote `Gruvbox.colors` (was in KDE `.colors` format, invisible to qt6ct) and added `gruvbox-material-dark.conf`. qt6ct requires `.conf` extension and QPalette ARGB format (`#ffRRGGBB`, 21 comma-separated values per state). Files stored in `qt6ct/colors/` in repo; deploy to `~/.config/qt6ct/colors/`.
- **Note**: Dolphin is a Qt app — GTK theme has no effect on it. Qt theming is controlled entirely by qt6ct.

---



### Hyprland — inactive opacity exclusion for Brave

- Added `windowrule = opacity 1.0 override 1.0 override 1.0, match:class brave-browser` to exempt Brave from the global `inactive_opacity = 0.88`
- Uses inline `windowrule =` format (not block syntax) — the wiki's opacity examples use this format and the block syntax `opacity =` did not apply the override correctly
- `override` keyword bypasses the global decoration opacity product; without it the values multiply (e.g. `1.0 * 0.88 = 0.88`)
- Window class is `brave-browser` (not `brave`) — also corrected the existing `brave-save` windowrule which had the wrong class

---

### Hyprland — windowrule for Brave save dialogs

- Added windowrule `brave-save` to float Brave's native save/permission dialogs (`class: brave`, title matching `.*wants to save.*`)
- Brave uses two window classes: `brave-browser` for tabs, `brave` for native dialogs
- Brave opens file managers via DBus (`org.freedesktop.FileManager1.ShowItems`) directly — `xdg-mime` settings have no effect on this
- Key lesson: `match:title` uses regex not glob — `*foo*` is invalid, use `.*foo.*`

---

### quickshell bar — Weather widget with city name

- **City name**: Added `city` property to `Weather.qml` service — fetches from `wttr.in/?format=%l` (plain text, separate request) before the main `j1` JSON fetch; city is injected into jq via `--arg` and returned in the same `|`-delimited output
- **Why separate request**: `wttr.in/?format=j1` doesn't include `nearest_area` when using IP-based auto-detection (only `current_condition`, `request`, `weather` keys); `%l` is the only way to get a human-readable city name
- **Delimiter change**: Parser switched from space to `|` — city names can contain spaces
- **Widget**: City displayed after temperature in muted color; hidden when `Weather.city` is empty

### quickshell bar — Weather widget with suspend/wake detection

- **Weather service**: `services/Weather.qml` fetches weather from wttr.in (auto-detects location via IP), parses temp & weather code via `jq`
- **Weather widget**: `widgets/Weather.qml` displays Nerd Font weather icon (accent color when valid) + temperature in °C; fallback to muted cloud + `--°` when offline
- **Suspend/wake detection**: Added dual-timer system — fast 60s heartbeat detects time jumps > 2 min (indicating wake from suspend) and triggers immediate refresh; 15-min regular refresh cycle maintains updates while awake
- **Weather code mapping**: 26 wttr.in weather codes → Nerd Font icons (sunny, cloudy, rainy, snowy, fog, thunderstorm)
- **Prerequisites**: `jq` for JSON parsing (install: `sudo pacman -S jq`)
- **Bar position**: First item in right section (before CPU) with separator

---

## 2026-03-18

### libinput — T2 touchpad palm rejection tuning

- Created `libinput/local-overrides.quirks` in repo
- Increases `AttrPalmSizeThreshold` from 800 → 1600 (default too aggressive on T2, rejects normal finger taps)
- Sets `AttrTouchSizeRange=50:30` for better touch size detection
- Marks keyboard as `internal` so disable-while-typing works correctly
- **Deploy**: `sudo cp ~/Projects/linux-config/libinput/local-overrides.quirks /etc/libinput/local-overrides.quirks`
- **Verify**: `sudo libinput quirks list /dev/input/event7` — should show the new attrs
- **Revert**: `sudo rm /etc/libinput/local-overrides.quirks` then log out/in
- Takes effect on next login (no reboot needed)

---

### mako — adjusted notification margin

- Changed `margin` from `10` (uniform) to `16,16,10,10` (top, right, bottom, left)
- Shifts notification slightly down and left (toward center) for visual separation from tiled windows
- mako is launched via `exec-once = mako` in `hyprland.conf` — not via systemd unit (service is disabled by default; use `pkill mako && mako &` to restart manually)

---

### Config repo — symlinked nvim and ghostty to repo as source of truth

- `~/.config/nvim` → `~/Projects/linux-config/nvim/` (symlink)
- `~/.config/ghostty` → `~/Projects/linux-config/ghostty/` (symlink)
- Same pattern as existing hypr symlinks — repo is source of truth, edit there and changes are live immediately

---

### Neovim — transparency, cmdline completion, relative line numbers

- **transparent.nvim**: Clears Neovim's background highlight groups so terminal/compositor transparency shows through. `enable_on_startup = true`. Config at `~/.config/nvim/lua/plugins/transparent.lua`.
- **wilder.nvim**: Fuzzy cmdline completion for `:`, `/`, `?` modes. Popup menu renderer. Config at `~/.config/nvim/lua/plugins/wilder.lua`.
- **Relative line numbers**: `vim.opt.number = true` + `vim.opt.relativenumber = true` added to `init.lua` — hybrid mode (absolute on current line, relative on others).
- Note: nvim config lives at `~/.config/nvim/` and is **not** symlinked to this repo — changes must be copied manually.

---

### Neovim colorscheme switching with Telescope and auto-persistence

- Installed `colorscheme-persist.nvim` plugin — automatically saves selected colorscheme to disk on Telescope picker selection
- Configured Telescope for lazy-loading with `lazy = false`
- Added `nvim/lua/plugins/telescope.lua` for Telescope setup
- Added `nvim/lua/plugins/colorscheme-persist.lua` — enables persistent theme switching without manual config edits
- Backed up entire `~/.config/nvim` to `nvim/` directory in this repo
- Workflow: `:Telescope colorscheme` → pick theme → automatic persistence across restarts

---

### Fixed Hyprland workspace navigation keybinds

- Updated workspace navigation from `CTRL ALT + j/l` to `CTRL ALT + h/l` for consistency with vim keybind pattern (h=left, l=right)
- Changed direction: `CTRL ALT + h` → previous workspace (-1), `CTRL ALT + l` → next workspace (+1)
- Issue: Original bind syntax was correct but needed `hyprctl reload` to apply (Super+Shift+])

---

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
