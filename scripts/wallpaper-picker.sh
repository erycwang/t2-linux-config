#!/usr/bin/env bash
# Rofi-based wallpaper picker — lists ~/Downloads/wallpapers/, runs wallpaper-change.sh on selection
WALLPAPER_DIR="$HOME/Downloads/wallpapers"

selected=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    | sort | xargs -I{} basename {} \
    | rofi -dmenu -p "Wallpaper" -i)

[[ -z "$selected" ]] && exit 0

exec "$(dirname "${BASH_SOURCE[0]}")/wallpaper-change.sh" "$WALLPAPER_DIR/$selected"
