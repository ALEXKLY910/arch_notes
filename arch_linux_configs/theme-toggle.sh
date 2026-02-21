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

# Preserve these so settings.ini doesn't drift from what you actually configured.
icon_theme="$(gget icon-theme)";     [[ -z "$icon_theme" ]] && icon_theme="Adwaita"
cursor_theme="$(gget cursor-theme)"; [[ -z "$cursor_theme" ]] && cursor_theme="Adwaita"
cursor_size="$(gget cursor-size)";   [[ -z "$cursor_size" ]] && cursor_size="24"

# --- Single source of truth: GNOME color-scheme ---
current_scheme="$(gget color-scheme)"

# Toggle ONLY the truth value.
# Use prefer-dark for dark. Use default for light (more compatible than prefer-light).
if [[ "$current_scheme" == "prefer-dark" ]]; then
  gset_s color-scheme "default"
else
  gset_s color-scheme "prefer-dark"
fi

# Re-read the truth after setting, so we enforce the final state.
scheme="$(gget color-scheme)"
is_dark="0"
[[ "$scheme" == "prefer-dark" ]] && is_dark="1"

# Enforce GTK outputs based on the truth.
if [[ "$is_dark" == "1" ]]; then
  gtk_theme="Adwaita-dark"
  prefer_dark_bool="true"
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
else
  gtk_theme="Adwaita"
  prefer_dark_bool="false"
  qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
fi

# GTK: set the actual theme name (helps GTK3) to match the truth.
gset_s gtk-theme "$gtk_theme"

# Keep icon/cursor settings aligned (so settings.ini readers don't diverge).
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

# Qt6: enforce the palette via hyprqt6engine config (apps may need restart).
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