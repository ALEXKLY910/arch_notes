#!/usr/bin/env bash
set -euo pipefail

SCHEMA="org.gnome.desktop.interface"

usage() {
  echo "Usage: $(basename "$0") [light|dark]" >&2
}

gget() {
  gsettings get "$SCHEMA" "$1" | sed -e "s/^'//" -e "s/'$//"
}

gset_s() {
  gsettings set "$SCHEMA" "$1" "'$2'"
}

# Accept zero or one argument only
if (( $# > 1 )); then
  usage
  exit 2
fi

requested_mode="${1:-toggle}"

case "$requested_mode" in
  light)
    is_new_dark="false"
    ;;
  dark)
    is_new_dark="true"
    ;;
  toggle)
    current_scheme="$(gget color-scheme)"

    if [[ "$current_scheme" == "prefer-dark" ]]; then
      is_new_dark="false"
    else
      is_new_dark="true"
    fi
    ;;
  *)
    echo "Invalid mode: $requested_mode" >&2
    usage
    exit 2
    ;;
esac

# Preserve existing icon/cursor settings so settings.ini readers don't diverge
icon_theme="$(gget icon-theme)"
[[ -n "$icon_theme" ]] || {
  echo "icon-theme is empty" >&2
  exit 1
}

cursor_theme="$(gget cursor-theme)"
[[ -n "$cursor_theme" ]] || {
  echo "cursor-theme is empty" >&2
  exit 1
}

cursor_size="$(gget cursor-size)"
[[ -n "$cursor_size" ]] || {
  echo "cursor-size is empty" >&2
  exit 1
}

if [[ "$is_new_dark" == "true" ]]; then
  gset_s color-scheme "prefer-dark"

  gtk_theme="Adwaita-dark"
  qt_icon_theme="breeze-dark"
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
  copyq_theme="black.ini"
  ghostty_scheme="$HOME/.config/ghostty/themes/default-dark.conf"
  fuzzel_scheme="$HOME/.config/fuzzel/themes/dark-modern.ini"
  plasma_scheme="BreezeDark"
else
  gset_s color-scheme "default"

  gtk_theme="Adwaita"
  qt_icon_theme="breeze"
  qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
  copyq_theme="simple.ini"
  ghostty_scheme="$HOME/.config/ghostty/themes/default-light.conf"
  fuzzel_scheme="$HOME/.config/fuzzel/themes/light.ini"
  plasma_scheme="BreezeLight"
fi

[[ -f "$qt_scheme" ]] || {
  echo "Missing Qt color scheme file: $qt_scheme (install 'breeze')" >&2
  exit 1
}

[[ -f "$ghostty_scheme" ]] || {
  echo "Missing Ghostty color scheme file: $ghostty_scheme" >&2
  exit 1
}

[[ -f "$fuzzel_scheme" ]] || {
  echo "Missing Fuzzel color scheme file: $fuzzel_scheme" >&2
  exit 1
}

command -v copyq >/dev/null 2>&1 || {
  echo "Missing CopyQ" >&2
  exit 1
}

command -v plasma-apply-colorscheme >/dev/null 2>&1 || {
  echo "Missing plasma-apply-colorscheme" >&2
  exit 1
}

# Apply CopyQ theme
copyq eval "loadTheme(info('themes') + '/$copyq_theme')"

# Wire up Ghostty's theme
mkdir -p "$HOME/.config/ghostty/themes"
ln -sf "$ghostty_scheme" "$HOME/.config/ghostty/themes/current.conf"

# Reload Ghostty's config if Ghostty is running
if pgrep -x ghostty >/dev/null; then
  pkill -USR2 -x ghostty
fi

# Wire up Fuzzel's theme
mkdir -p "$HOME/.config/fuzzel/themes"
ln -sf "$fuzzel_scheme" "$HOME/.config/fuzzel/themes/current.ini"

# Enforce GTK state
gset_s gtk-theme "$gtk_theme"

write_ini() {
  local dir="$1"

  mkdir -p "$dir"

  cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-application-prefer-dark-theme=$is_new_dark
EOF
}

write_ini "$HOME/.config/gtk-3.0"
write_ini "$HOME/.config/gtk-4.0"

# Enforce Qt6 state via hyprqt6engine
cfg="$HOME/.config/hypr/hyprqt6engine.conf"

[[ -f "$cfg" ]] || {
  echo "Missing $cfg. Create it once with a 'color_scheme =' line and rerun." >&2
  exit 1
}

grep -Eq '^[[:space:]]*color_scheme[[:space:]]*=' "$cfg" || {
  echo "$cfg exists but has no 'color_scheme =' line" >&2
  exit 1
}

sed -i -E \
  "s|^([[:space:]]*color_scheme[[:space:]]*=[[:space:]]*).*$|\\1$qt_scheme|" \
  "$cfg"

grep -Eq '^[[:space:]]*icon_theme[[:space:]]*=' "$cfg" || {
  echo "$cfg exists but has no 'icon_theme =' line" >&2
  exit 1
}

sed -i -E \
  "s|^([[:space:]]*icon_theme[[:space:]]*=[[:space:]]*).*$|\\1$qt_icon_theme|" \
  "$cfg"

plasma-apply-colorscheme "$plasma_scheme"

systemctl --user restart plasma-xdg-desktop-portal-kde.service
