#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCHEMA="org.gnome.desktop.interface"

gget() {
  gsettings get "$SCHEMA" "$1" | sed -e "s/^'//" -e "s/'$//"
}

gset_s() {
  gsettings set "$SCHEMA" "$1" "'$2'"
}

gset_i() {
  gsettings set "$SCHEMA" "$1" "$2"
}

# Ensure schema + keys exist (otherwise bail with a readable message)
gsettings list-schemas | grep -qx "$SCHEMA" \
  || { echo "Missing schema: $SCHEMA (install gsettings-desktop-schemas + dconf?)" >&2; exit 1; }

for k in color-scheme gtk-theme icon-theme cursor-theme cursor-size; do
  gsettings list-keys "$SCHEMA" | grep -qx "$k" \
    || { echo "Missing key: $SCHEMA $k" >&2; exit 1; }
done

# Preserve existing icon/cursor settings so settings.ini readers don't diverge
icon_theme="$(gget icon-theme)";       [[ -n "$icon_theme" ]] || { echo "icon-theme is empty" >&2; exit 1; }
cursor_theme="$(gget cursor-theme)";   [[ -n "$cursor_theme" ]] || { echo "cursor-theme is empty" >&2; exit 1; }
cursor_size="$(gget cursor-size)";     [[ -n "$cursor_size" ]] || { echo "cursor-size is empty" >&2; exit 1; }

# Single source of truth: GNOME color-scheme
current_scheme="$(gget color-scheme)"

# Toggle the truth value (prefer-dark <-> default). Treat default as light.
if [[ "$current_scheme" == "prefer-dark" ]]; then
  gset_s color-scheme "default"
else
  gset_s color-scheme "prefer-dark"
fi

# Re-read what actually stuck
scheme="$(gget color-scheme)"
is_dark="0"
[[ "$scheme" == "prefer-dark" ]] && is_dark="1"

if [[ "$is_dark" == "1" ]]; then
  gtk_theme="Adwaita-dark"
  prefer_dark_bool="true"
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
else
  gtk_theme="Adwaita"
  prefer_dark_bool="false"
  qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
fi

[[ -f "$qt_scheme" ]] \
  || { echo "Missing Qt color scheme file: $qt_scheme (install 'breeze')" >&2; exit 1; }

# Enforce GTK state
gset_s gtk-theme "$gtk_theme"
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

write_ini "$HOME/.config/gtk-3.0"
write_ini "$HOME/.config/gtk-4.0"

# Enforce Qt6 state via hyprqt6engine
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
  grep -Eq '^[[:space:]]*color_scheme[[:space:]]*=' "$cfg" \
    || { echo "hyprqt6engine.conf exists but has no 'color_scheme =' line" >&2; exit 1; }

  sed -i -E "s|^([[:space:]]*color_scheme[[:space:]]*=[[:space:]]*).*$|\\1$qt_scheme|" "$cfg"
fi