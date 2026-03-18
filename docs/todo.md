# Setup To-Do

Gaps and planned changes to the current system setup, ordered by priority.

---

## Priority 1 — Security & Power (do these first)

### Keyring daemon (gnome-keyring) ✅ Done

- `gnome-keyring` installed, autostarted in Hyprland with `--components=secrets` (secrets only — gpg-agent handles SSH/GPG)
- `gh auth login` re-run; token now stored in keyring (`gh auth status` confirms `(keyring)`)
- `hosts.yml` no longer contains `oauth_token`

---

### Lock screen + idle daemon ✅ Done

- `hyprlock` + `hypridle` installed
- `hypridle` autostarted via `exec-once` in Hyprland; idle chain: 2 min dim → 3 min lock → 10 min suspend
- `hyprlock` bound to `Super+Shift+L`; also triggered by `hypridle` and before suspend
- `kidletime` kept — pulled in by `baloo` → `dolphin`, cannot remove
- Lock screen: blurred screenshot background, clock, centered password input

---

### Suspend

**Hardware**: 2020 MacBook Pro 13" (T2 chip) — see `changes.md` for full fix history.

`/etc/systemd/system/suspend-fix-t2.service` unloads `apple-bce`, `brcmfmac`, and Touch Bar modules before sleep and reloads them on resume. S3 deep sleep confirmed working. See [t2linux wiki](https://wiki.t2linux.org/guides/postinstall/) for background.

**Remaining items**:
- [x] Lid close triggers suspend, lid open resumes
- [~] No spurious immediate wakeups (`XHC1`/`ARPT` ACPI wakeup sources) — not observed in practice, not doing
- [x] Reduce suspend/resume latency — replaced all fixed sleeps with `udevadm settle` in v8. See `changes.md`.
- [~] Replace `sleep 2` after `modprobe apple-bce` with `udevadm settle --timeout=5` — not doing; apple-bce triggers async USB enumeration so `udevadm settle` returns immediately. Fixed sleep is required.

---

## Priority 2 — Usability (important gaps)

### Status bar (quickshell) — in progress

**Plan**: See `quickshell/PLAN.md` for architecture and phased build plan.

- [x] Install `quickshell`
- [x] Phase 1: Minimal bar with clock — bar renders on all monitors, clock ticks, `exec-once = quickshell` in Hyprland
- [x] Phase 2: Workspaces + layout structure
- [x] Phase 3: System info — CPU, MEM, TEMP, battery, WiFi, Bluetooth all live
- [ ] Phase 4: Volume widget + tray + polish
- [ ] Phase 5: Theme switcher

**Notes on quickshell**: It's newer and less documented than waybar. If the QML config becomes a blocker, waybar is a well-trodden fallback that can be swapped out later.

---

### Notification daemon ✅ Done

- `mako` installed, autostarted via `exec-once = mako` in Hyprland
- Config at `mako/config` (symlinked to `~/.config/mako/config`): Catppuccin Mocha palette, 12px border radius, per-urgency rules (low → muted, normal → blue, high → red + no timeout)

---

## Priority 3 — Planned changes

### Browser migration: Firefox → Brave

- Already noted in `setup.md`
- Install `brave-bin` (AUR)
- Configure with system keyring for password storage (`kwallet` or `gnome-keyring`)
- Update default browser in Hyprland config once switched

---

## Priority 4 — Nice to have

### Screenshot tool — ✅ Done

- ~~Install `grim` + `slurp` (composable Wayland screenshot tools)~~
- ~~Or install `hyprshot` (wrapper around grim/slurp with Hyprland-aware window/region selection)~~ — installed `hyprshot`
- ~~Bind to a key in Hyprland config~~ — bound `Super+Shift+X` → `hyprshot -m region`

---

### OSD / HUD bars

Visual overlays for volume, brightness, and keyboard brightness on keypress. Common Wayland options:

- `swayosd` (AUR: `swayosd-git`) — runs as a background service, handles volume/brightness/caps lock natively, integrates cleanly with Hyprland
- `wob` — simpler pipe-based bar, requires wiring manually to each keybind

Recommended: `swayosd` — less wiring, handles all three use cases out of the box.

- Install and enable: `paru -S swayosd-git` + `exec-once = swayosd-server` in Hyprland config
- Update volume/brightness keybinds to call `swayosd-client` instead of raw `wpctl`/`brightnessctl`
- Add keyboard brightness keybind if not already present

---

### Clipboard manager

No clipboard history currently configured. `wl-clipboard` is installed but only provides basic copy/paste with no history.

- Install `cliphist` — lightweight Wayland clipboard history daemon
- Add to Hyprland autostart: `exec-once = wl-paste --type text --watch cliphist store`
- Bind a key to open history picker: `bind = $mainMod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy`

---

### Screenshot annotation

No annotation tool configured. Useful for marking up screenshots before sharing.

- Install `satty` — Wayland-native annotation tool (arrows, text, blur, shapes)
- Optionally wire into a new keybind that captures then opens in satty: `hyprshot -m region -r | satty --filename -`

---

### Multi-monitor workspace strategy — not decided

Hyprland workspaces are global by default: switching to workspace 3 from monitor 2 pulls it onto monitor 2, even if it was on monitor 1. Options to investigate:

- **Bind workspaces to monitors** in `hyprland.conf` (e.g. workspaces 1–5 on monitor 1, 6–9 on monitor 2) — simple, no plugins
- **`split-monitor-workspaces` plugin** — each monitor gets independent 1–9, GNOME-like behavior
- **Leave floating** — current behavior, workspaces follow focus

Decide based on actual usage: do workspace numbers jumping between monitors feel disorienting?

---

### Display manager migration (optional)

Current stack: SDDM → UWSM → Hyprland. SDDM still spawns an Xorg process for its greeter even in Wayland mode (invisible with autologin, but not purely Wayland).

Alternative: **greetd + regreet** — purely Wayland-native, no Xorg, more modular. Popular in minimal Hyprland setups.

Switching only requires changing the DM — UWSM, Hyprland config, and all autostart items are unaffected. See `docs/display-manager-architecture.md` for full details.

---

### Wallpaper

- Install `hyprpaper` (Hyprland-native) or `swww` (supports animated wallpapers)
- Currently using Hyprland default (solid color)

---

### Migrate suspend fix from service to sleep hook

`suspend-fix-t2.service` (systemd `Before=sleep.target` service) works but is complex. `t2-suspend-fix.sh` (sleep hook in `/etc/systemd/system-sleep/`) is simpler — runs as a direct subprocess of `systemd-sleep`, after all unit ordering is done.

- Port v8 changes (udevadm settle, PCI remove/rescan) to `t2-suspend-fix.sh`
- Test suspend/resume cycle reliability
- Deploy hook, disable service

---

### Cleanup orphaned terminals

- Kitty and Alacritty are installed but unused (Ghostty is primary)
- Uninstall if not dependencies of anything: `paru -Rns kitty alacritty`

---

### t2fanrd — ✅ Done

- Enabled via `systemctl enable --now t2fanrd`
- Custom config at `/etc/t2fand.conf`: logarithmic curve, 50°C–72°C
- Logarithmic: fans ramp quickly at low temps, flatten near max — more responsive at the low end, quieter under sustained load

---

## Summary table

| Item | Priority | Status |
|---|---|---|
| Keyring daemon (gnome-keyring) | 🟢 Done | ✅ Token in keyring, hosts.yml clean |
| Lock screen (hyprlock + hypridle) | 🟢 Done | ✅ hyprlock + hypridle configured |
| Suspend (test + configure) | 🟢 Done | v8 — all sleeps replaced with udevadm settle, full resume working |
| Status bar (quickshell) | 🟠 Medium | Phase 3 done — CPU, MEM, TEMP, battery, WiFi, Bluetooth live. Phase 4 (volume + tray) next. |
| Multi-monitor workspace strategy | ⚪ Optional | Not decided — bind to monitors, plugin, or leave floating |
| Notification daemon (mako) | 🟢 Done | ✅ mako installed and configured |
| Browser migration (Brave) | 🟡 Planned | Not started |
| Screenshot tool | 🟢 Nice to have | ✅ Done |
| OSD / HUD bars (swayosd or wob) | 🟢 Nice to have | Not started |
| Clipboard manager (cliphist) | 🟢 Nice to have | Not started |
| Screenshot annotation (satty) | 🟢 Nice to have | Not started |
| Suspend hook migration | 🟢 Nice to have | Not started — migrate service to sleep hook |
| Display manager migration (greetd) | ⚪ Optional | Not started — see display-manager-architecture.md |
| Wallpaper | 🟢 Nice to have | Not started |
| Cleanup orphaned terminals | 🟢 Nice to have | Not started |
| t2fanrd decision | 🟢 Nice to have | ✅ Done |
