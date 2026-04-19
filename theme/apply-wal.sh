#!/usr/bin/env bash
# Applies colors from the most recent pywal run (~/.cache/wal/colors.sh)
set -euo pipefail

WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [[ ! -f "$WAL_COLORS" ]]; then
    echo "Error: $WAL_COLORS not found. Run 'wal -i <wallpaper>' first." >&2
    exit 1
fi

source "$WAL_COLORS"

# Map pywal color0-15 to semantic vars:
# color0=bg (darkest), color7=fg (light), color4=blue→accent, color5=magenta→accent2
# color8=bright black→muted, color1=red, color2=green, color3=yellow, color9=bright red→orange
export bg="$color0"
export fg="$color7"
export accent="$color4"
export accent2="$color5"
export muted="$color8"
export red="$color1"
export orange="$color9"
export yellow="$color3"
export green="$color2"

# 95% opacity (#f2 prefix) — matches apply.sh
export bg_alpha="#f2${bg#\#}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Quickshell Colors.qml
envsubst '$bg $fg $accent $accent2 $muted $red $orange $yellow $green $bg_alpha' \
    < "$REPO_DIR/quickshell/config/Colors.qml.template" \
    > "$REPO_DIR/quickshell/config/Colors.qml"

# 2. Hyprland colors.conf (no # prefix)
cat > "$REPO_DIR/hypr/colors.conf" <<EOF
\$bg      = ${bg#\#}
\$fg      = ${fg#\#}
\$accent  = ${accent#\#}
\$accent2 = ${accent2#\#}
\$muted   = ${muted#\#}
\$red     = ${red#\#}
\$orange  = ${orange#\#}
\$yellow  = ${yellow#\#}
\$green   = ${green#\#}
EOF

# 3. Mako config
envsubst '$bg $fg $accent $muted $red' \
    < "$REPO_DIR/mako/config.template" \
    > "$REPO_DIR/mako/config"

# 4. SwayOSD style
envsubst '$bg $fg $accent $bg_alpha' \
    < "$REPO_DIR/swayosd/style.css.template" \
    > "$REPO_DIR/swayosd/style.css"

# 5. Ghostty — inline palette (replaces named theme reference)
cat > "$REPO_DIR/ghostty/auto/theme.ghostty" <<EOF
background = ${bg#\#}
foreground = ${fg#\#}
cursor-color = ${fg#\#}
selection-background = ${accent#\#}
selection-foreground = ${bg#\#}
palette = 0=${color0}
palette = 1=${color1}
palette = 2=${color2}
palette = 3=${color3}
palette = 4=${color4}
palette = 5=${color5}
palette = 6=${color6}
palette = 7=${color7}
palette = 8=${color8}
palette = 9=${color9}
palette = 10=${color10}
palette = 11=${color11}
palette = 12=${color12}
palette = 13=${color13}
palette = 14=${color14}
palette = 15=${color15}
EOF

# 6. Reload daemons
makoctl reload
hyprctl reload
pkill swayosd-server 2>/dev/null || true
swayosd-server &
pkill quickshell 2>/dev/null || true
quickshell &

echo "Applied wal theme from: $(cat "$HOME/.cache/wal/wal" 2>/dev/null || echo 'unknown')"
