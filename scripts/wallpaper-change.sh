#!/usr/bin/env bash
# Changes wallpaper via hyprpaper IPC and applies pywal colors to all apps
set -euo pipefail

WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: wallpaper-change.sh <image-path>" >&2
    exit 1
fi

WALLPAPER="$(realpath "$WALLPAPER")"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "Error: file not found: $WALLPAPER" >&2
    exit 1
fi

# Persist wallpaper in hyprpaper.conf so it survives Hyprland reloads
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat > "$REPO_DIR/hypr/hyprpaper.conf" <<EOF
wallpaper {
    monitor =
    path = $WALLPAPER
    fit_mode = cover
}

splash = false
EOF

# Preload into hyprpaper then apply to all active monitors
hyprctl hyprpaper preload "$WALLPAPER"
for monitor in $(hyprctl monitors -j | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin)]"); do
    hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER"
done

# Extract colors (skip Xresources / terminal apply — we handle it ourselves)
wal -i "$WALLPAPER" -n -q

# Apply colors to all subsystems
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/../theme/apply-wal.sh"
