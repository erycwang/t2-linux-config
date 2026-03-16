# Changes

A running log of changes made to this system — what was added, removed, or modified and why.

---

## 2026-03-16

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
