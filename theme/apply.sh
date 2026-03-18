#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
THEME_FILE="${1:-$REPO_DIR/theme/tokyo-night-moon.sh}"

if [[ ! -f "$THEME_FILE" ]]; then
    echo "Theme file not found: $THEME_FILE"
    exit 1
fi

source "$THEME_FILE"

# Compute bg with alpha (0.95 = 0xF2) for Qt.rgba usage in QML
bg_alpha="#f2${bg#\#}"

# Export all vars for envsubst
export bg fg accent accent2 muted red orange yellow green bg_alpha

# 1. Generate hypr/colors.conf (Hyprland $var format, no # prefix)
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

# 2. Generate Colors.qml from template
envsubst '$bg $fg $accent $accent2 $muted $red $orange $yellow $green $bg_alpha' \
    < "$REPO_DIR/quickshell/config/Colors.qml.template" \
    > "$REPO_DIR/quickshell/config/Colors.qml"

# 3. Generate mako/config from template
envsubst '$bg $fg $accent $muted $red' \
    < "$REPO_DIR/mako/config.template" \
    > "$REPO_DIR/mako/config"

# 4. Generate swayosd/style.css from template
envsubst '$bg $fg $accent $bg_alpha' \
    < "$REPO_DIR/swayosd/style.css.template" \
    > "$REPO_DIR/swayosd/style.css"

# 5. Reload daemons
makoctl reload
hyprctl reload
pkill swayosd-server 2>/dev/null || true
swayosd-server &
pkill quickshell 2>/dev/null || true
quickshell &

echo "Applied: $(basename "$THEME_FILE" .sh)"
