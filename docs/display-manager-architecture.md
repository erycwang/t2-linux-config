# Display Manager Architecture

## What is UWSM?

**UWSM (Universal Wayland Session Manager)** is a Python-based systemd session manager that wraps Wayland compositors. It handles:
- **Environment setup** — sources env vars before the compositor launches (via `uwsm aux prepare-env`)
- **systemd integration** — launches the compositor as a `Type=notify` systemd user service, so the session has a clean lifecycle with proper start/stop signaling
- **XDG autostart** — manages autostart apps as systemd user units (so `exec-once` in Hyprland config flows through systemd)
- **Clean shutdown** — tears down the session graph cleanly on exit

UWSM is not explicitly configured by the user but is baked into the boot chain — SDDM triggers `wayland-wm@hyprland.service`, a UWSM systemd template.

---

## Current Boot Chain

```
systemd
  └─ graphical.target
     └─ display-manager.service → sddm.service
        └─ SDDM reads /etc/sddm.conf → Session=hyprland, autologin
           └─ PAM login (sddm-autologin stack, no password prompt)
              └─ systemd user manager
                 └─ wayland-wm-env@hyprland.service (uwsm aux prepare-env)
                    └─ wayland-wm@hyprland.service (uwsm aux exec → /usr/bin/start-hyprland)
                       └─ Hyprland compositor
                          └─ uwsm finalize (exports WAYLAND_DISPLAY, notifies systemd)
                             └─ graphical-session.target → XDG autostart
                                └─ gnome-keyring, hyprpolkitagent, hypridle, etc.
```

**Key config**: `/etc/sddm.conf`
```ini
[Autologin]
Session=hyprland
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell
```

**Session definitions**:
- `/usr/share/wayland-sessions/hyprland.desktop` — direct launch via `start-hyprland`
- `/usr/share/wayland-sessions/hyprland-uwsm.desktop` — explicit UWSM-managed launch

---

## SDDM vs Alternatives

| DM | Notes |
|---|---|
| **SDDM** (current) | Qt-based, widely used, good Wayland support, configurable themes, autologin works cleanly. Default for KDE/Hyprland setups. Still spawns an Xorg process for its own greeter even in Wayland mode — invisible in practice since autologin skips the greeter. |
| **greetd** | Minimal daemon, no built-in GUI — pairs with a frontend (`regreet`, `tuigreet`, `gtkgreet`). Purely Wayland-native, no Xorg. Most popular modern choice for minimal Hyprland setups. |
| **ly** | TUI login screen in the TTY. Ultra-minimal, no GUI overhead. Fine for single-user laptops. |
| **GDM** | GNOME-specific, heavy. Not appropriate here. |
| **LightDM** | GTK-based, older, less maintained for Wayland. Skip. |

---

## What Changes if Switching DMs

### SDDM → greetd

1. Install: `sudo pacman -S greetd` + greeter frontend (e.g. `paru -S greetd-regreet`)
2. Configure `/etc/greetd/config.toml` with session command and autologin user
3. `sudo systemctl disable sddm && sudo systemctl enable greetd`
4. UWSM, Hyprland config, and all autostart — **no changes needed**

### SDDM → ly

1. Install: `paru -S ly`
2. `sudo systemctl disable sddm && sudo systemctl enable ly`
3. Configure `/etc/ly/config.ini`
4. UWSM, Hyprland config, and all autostart — **no changes needed**

### What never changes regardless of DM

- UWSM — all DMs hand off to the same `wayland-wm@hyprland.service` unit
- Hyprland config
- `exec-once` autostart items
- gnome-keyring, hypridle, hyprpolkitagent

---

## Recommendation

**Keep SDDM for now.** It works, autologin is configured, and the Xorg greeter process is invisible since autologin skips it entirely. No functional benefit to switching.

If ever switching: **greetd + regreet** is the standard choice for Hyprland setups that want a clean Wayland-only stack.
