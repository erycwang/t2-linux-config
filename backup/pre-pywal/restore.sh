#!/usr/bin/env bash
# Reverts to pre-pywal state
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="$(dirname "${BASH_SOURCE[0]}")"

cd "$REPO_DIR"

cp "$BACKUP_DIR/hyprland.conf"     hypr/hyprland.conf
cp "$BACKUP_DIR/theme.ghostty"     ghostty/auto/theme.ghostty
cp "$BACKUP_DIR/Colors.qml"        quickshell/config/Colors.qml
cp "$BACKUP_DIR/colors.conf"       hypr/colors.conf
cp "$BACKUP_DIR/mako.config"       mako/config
cp "$BACKUP_DIR/swayosd.style.css" swayosd/style.css

# Re-apply preset gruvbox theme to regenerate all generated files correctly
bash theme/apply.sh theme/gruvbox-material-dark.sh

echo "Reverted to pre-pywal state."
echo "Pywal-added scripts can be removed manually:"
echo "  rm theme/apply-wal.sh scripts/wallpaper-change.sh scripts/wallpaper-picker.sh"
