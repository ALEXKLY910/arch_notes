#!/usr/bin/env bash
set -euo pipefail

SCHEMA="org.gnome.desktop.interface"

gget() {
  gsettings get "$SCHEMA" "$1" 2>/dev/null | sed -e "s/^'//" -e "s/'$//" || true
}

gset_s() {
  gsettings set "$SCHEMA" "$1" "'$2'" 2>/dev/null || true
}

gset_i() {
  gsettings set "$SCHEMA" "$1" "$2" 2>/dev/null || true
}

# Read current settings (keep icons/cursor as-is; only commit GTK theme to Adwaita family)
icon_theme="$(gget icon-theme)";         [[ -z "$icon_theme" ]] && icon_theme="Adwaita"
cursor_theme="$(gget cursor-theme)";     [[ -z "$cursor_theme" ]] && cursor_theme="Adwaita"
cursor_size="$(gget cursor-size)";       [[ -z "$cursor_size" ]] && cursor_size="24"

current_scheme="$(gget color-scheme)"
current_gtk_theme="$(gget gtk-theme)"

# Decide whether we are currently "dark"
is_dark="0"
[[ "$current_scheme" == "prefer-dark" ]] && is_dark="1"
case "$current_gtk_theme" in
  Adwaita-dark|*dark|*:dark|*:Dark|*-dark|*-Dark) is_dark="1" ;;
esac

# Toggle target
if [[ "$is_dark" == "1" ]]; then
  target="light"
  gtk_theme="Adwaita"
  prefer_dark_bool="false"
  qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
else
  target="dark"
  gtk_theme="Adwaita-dark"
  prefer_dark_bool="true"
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
fi

# Set GNOME "dark style preference" (some setups may not support prefer-light; fall back to default)
if [[ "$target" == "light" ]]; then
  gset_s color-scheme "prefer-light"
  if [[ "$(gget color-scheme)" != "prefer-light" ]]; then
    gset_s color-scheme "default"
  fi
else
  gset_s color-scheme "prefer-dark"
fi

# Set the actual GTK theme name (helps GTK3 apps that ignore the prefer-dark flag)
gset_s gtk-theme "$gtk_theme"

# Keep icon/cursor consistent in GNOME settings too
gset_s icon-theme "$icon_theme"
gset_s cursor-theme "$cursor_theme"
gset_i cursor-size "$cursor_size"

write_ini() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-application-prefer-dark-theme=$prefer_dark_bool
EOF
}

# Write both GTK3 and GTK4 config files (many apps read these even outside GNOME)
write_ini "$HOME/.config/gtk-3.0"
write_ini "$HOME/.config/gtk-4.0"

# Update hyprqt6engine (Qt apps usually need restart to pick this up)
cfg="$HOME/.config/hypr/hyprqt6engine.conf"
mkdir -p "$(dirname "$cfg")"

if [[ ! -f "$cfg" ]]; then
  cat > "$cfg" <<EOF
theme {
  style = Fusion
  icon_theme = Breeze
  color_scheme = $qt_scheme
}
misc {
  single_click_activate = true
  menus_have_icons = true
  shortcuts_for_context_menus = true
}
EOF
else
  sed -i -E "s|^([[:space:]]*color_scheme[[:space:]]*=[[:space:]]*).*$|\\1$qt_scheme|" "$cfg"
fi