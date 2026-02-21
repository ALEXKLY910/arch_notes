1. Install necessary packages:
    >`sudo pacman -S --needed dconf gsettings-desktop-schemas breeze`
    >`yay -S hyprqt6engine`

2. Make Hyprland export **hyprqt6engine** for user services. Put this into `~/.config/hypr/hyprland.conf` near the top:
    ```
    env = QT_QPA_PLATFORMTHEME,hyprqt6engine

    exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORMTHEME
    ```

    Then reboot so the portals are properly restarted.

3. Create `~/.local/bin/toggle-theme` file:
    >`mkdir -p ~/.local/bin`
    >`touch ~/.local/bin/toggle-theme`
    >`chmod +x ~/.local/bin/toggle-theme`


5. Paste the following into `~/.local/bin/toggle-theme`:

```
#!/usr/bin/env bash
set -euo pipefail

SCHEMA="org.gnome.desktop.interface"

get_str() {
  gsettings get "$SCHEMA" "$1" 2>/dev/null | tr -d "'" || true
}

get_int() {
  gsettings get "$SCHEMA" "$1" 2>/dev/null | tr -d "'" || true
}

gtk_theme="$(get_str gtk-theme)";        [[ -z "$gtk_theme" ]] && gtk_theme="Adwaita"
icon_theme="$(get_str icon-theme)";      [[ -z "$icon_theme" ]] && icon_theme="Adwaita"
cursor_theme="$(get_str cursor-theme)";  [[ -z "$cursor_theme" ]] && cursor_theme="Adwaita"
cursor_size="$(get_int cursor-size)";    [[ -z "$cursor_size" ]] && cursor_size="24"

current="$(get_str color-scheme)"
if [[ "$current" == "prefer-dark" ]]; then
  target="prefer-light"
  prefer_dark="0"
else
  target="prefer-dark"
  prefer_dark="1"
fi

if [[ "$target" == "prefer-dark" ]]; then
  gsettings set "$SCHEMA" color-scheme 'prefer-dark' 2>/dev/null || true
else
  gsettings set "$SCHEMA" color-scheme 'prefer-light' 2>/dev/null || \
  gsettings set "$SCHEMA" color-scheme 'default' 2>/dev/null || true
fi

write_ini() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-application-prefer-dark-theme=$prefer_dark
EOF
}

write_ini "$HOME/.config/gtk-3.0"
write_ini "$HOME/.config/gtk-4.0"

qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
if [[ "$prefer_dark" == "1" ]]; then
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
fi

cfg="$HOME/.config/hypr/hyprqt6engine.conf"
mkdir -p "$(dirname "$cfg")"

# Create if missing, otherwise just patch the color_scheme line
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
  sed -i "s|^[[:space:]]*color_scheme[[:space:]]*=.*$|  color_scheme = $qt_scheme|" "$cfg"
fi

systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-hyprland.service 2>/dev/null || true

```



6. Bind it in Hyprland. Add this to `~/.config/hypr/hyprland.conf`:
    >`bind = $mainMod SHIFT, T, exec, ~/.local/bin/toggle-theme`

    Reload so that you can use it:
    >`hyprctl reload`
