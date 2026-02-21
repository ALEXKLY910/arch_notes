2. `sudo pacman -S featherpad`

in hyprland.conf:
# Frosted-glass Waybar
layerrule = blur on, match:namespace waybar
layerrule = ignore_alpha 0.20, match:namespace waybar


~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "height": 34,
  "margin": "8 10 0 10",
  "spacing": 10,
  "reload_style_on_change": true,

  "modules-left": [],
  "modules-center": [],
  "modules-right": [
    "clock",
    "group/audio",
    "group/brightness",
    "battery",
    "network",
    "tray",
    "custom/ws"
  ],

  "clock": {
    "format": "{:%H:%M %d:%m}",
    "tooltip-format": "{:%A, %d %B %Y  %H:%M}"
  },

  "group/audio": {
    "orientation": "inherit",
    "drawer": {
      "click-to-reveal": true,
      "transition-duration": 180,
      "children-class": "drawer-hidden",
      "transition-left-to-right": true
    },
    "modules": [
      "pulseaudio",
      "pulseaudio/slider"
    ]
  },

  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "󰝟 0%",
    "format-icons": ["󰕿", "󰖀", "󰕾"],
    "scroll-step": 1.0,
    "on-click-right": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
  },

  "pulseaudio/slider": {
    "min": 0,
    "max": 100,
    "orientation": "horizontal"
  },

  "group/brightness": {
    "orientation": "inherit",
    "drawer": {
      "click-to-reveal": true,
      "transition-duration": 180,
      "children-class": "drawer-hidden",
      "transition-left-to-right": true
    },
    "modules": [
      "backlight",
      "backlight/slider"
    ]
  },

  "backlight": {
    "format": "󰃠 {percent}%",
    "scroll-step": 1.0
    // If it doesn't move the *right* backlight, set:
    // "device": "intel_backlight"
  },

  "backlight/slider": {
    "orientation": "horizontal"
  },

  "battery": {
    "format": "{capacity}%",
    "format-charging": " {capacity}%",
    "format-plugged": " {capacity}%",
    "format-full": "{capacity}%",
    "tooltip": true
  },

  "network": {
    "interval": 5,
    "format-wifi": "{icon}",
    "format-icons": ["󰤟", "󰤢", "󰤥", "󰤨"],
    "format-ethernet": "󰈀",
    "format-linked": "󰤯",
    "format-disconnected": "󰤮",
    "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}",
    "tooltip-format-ethernet": "Ethernet\n{ipaddr}",
    "tooltip-format-disconnected": "No connection",
    "on-click": "ghostty -e nmtui"
  },

  "tray": {
    "icon-size": 16,
    "spacing": 8
  },

  "custom/ws": {
    "exec": "hyprctl activeworkspace -j | jq -r '.id'",
    "interval": 1,
    "format": "{}",
    "tooltip": false
  }
}



~/.config/waybar/style.css


* {
  font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font";
  font-size: 13px;
}

window#waybar {
  background: rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
}

#clock,
#pulseaudio,
#backlight,
#battery,
#network,
#tray,
#custom-ws {
  padding: 0 10px;
}

/* Hide drawer children until revealed */
.drawer-hidden {
  opacity: 0;
  margin: 0;
  padding: 0;
  min-width: 0;
}

/* Make the sliders slim and sane */
#pulseaudio-slider,
#backlight-slider {
  padding: 0 10px 0 0;
  margin-left: 6px;
}

#pulseaudio-slider slider,
#backlight-slider slider {
  opacity: 0;            /* hide the knob */
  min-height: 0px;
  min-width: 0px;
  background: none;
  border: none;
  box-shadow: none;
}

#pulseaudio-slider trough,
#backlight-slider trough {
  min-height: 6px;
  min-width: 90px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.12);
}

#pulseaudio-slider highlight,
#backlight-slider highlight {
  min-height: 6px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.55);
}

/* Small visual feedback for states */
#pulseaudio.muted {
  opacity: 0.6;
}

#network.disconnected {
  opacity: 0.7;
}



pkill waybar; waybar &

























#!/usr/bin/env bash
set -euo pipefail

SCHEMA="org.gnome.desktop.interface"

gget() { gsettings get "$SCHEMA" "$1" 2>/dev/null | sed -e "s/^'//" -e "s/'$//"; }
gset_s() { gsettings set "$SCHEMA" "$1" "'$2'" 2>/dev/null || true; }
gset_i() { gsettings set "$SCHEMA" "$1" "$2" 2>/dev/null || true; }

theme_base_dirs=(
  "$HOME/.themes"
  "$HOME/.local/share/themes"
  "/usr/local/share/themes"
  "/usr/share/themes"
)

theme_exists() {
  # For Adwaita:dark-style variants, the directory is the base theme (before ':')
  local name="$1"
  local base="${name%%:*}"
  for d in "${theme_base_dirs[@]}"; do
    [[ -d "$d/$name" || -d "$d/$base" ]] && return 0
  done
  return 1
}

current_theme="$(gget gtk-theme)";        [[ -z "$current_theme" ]] && current_theme="Adwaita"
icon_theme="$(gget icon-theme)";          [[ -z "$icon_theme" ]] && icon_theme="Adwaita"
cursor_theme="$(gget cursor-theme)";      [[ -z "$cursor_theme" ]] && cursor_theme="Adwaita"
cursor_size="$(gget cursor-size)";        [[ -z "$cursor_size" ]] && cursor_size="24"

current_scheme="$(gget color-scheme)"

# Detect "dark-ish" state from either the scheme or the theme name
is_dark="0"
case "$current_scheme" in
  prefer-dark) is_dark="1" ;;
esac
case "$current_theme" in
  *:dark|*:Dark|*-dark|*-Dark|*Dark) is_dark="1" ;;
esac

base="${current_theme%%:*}"

# Build candidate names for dark and light variants
light_candidates=(
  "$base"
  "$base:light"
  "$base:Light"
)
dark_candidates=(
  "$base-dark"
  "$base-Dark"
  "$base:dark"
  "$base:Dark"
)

pick_first_existing() {
  local out=""
  for c in "$@"; do
    if theme_exists "$c"; then
      out="$c"
      break
    fi
  done
  [[ -n "$out" ]] && printf "%s" "$out"
}

light_theme="$(pick_first_existing "${light_candidates[@]}")"
dark_theme="$(pick_first_existing "${dark_candidates[@]}")"

# Hard fallback if we couldn't validate anything (still better than crashing)
[[ -z "$light_theme" ]] && light_theme="$base"
[[ -z "$dark_theme"  ]] && dark_theme="$base:dark"

if [[ "$is_dark" == "1" ]]; then
  target_scheme="prefer-light"
  gtk_theme="$light_theme"
  prefer_dark_bool="false"
  qt_scheme="/usr/share/color-schemes/BreezeLight.colors"
else
  target_scheme="prefer-dark"
  gtk_theme="$dark_theme"
  prefer_dark_bool="true"
  qt_scheme="/usr/share/color-schemes/BreezeDark.colors"
fi

# GNOME preference (many apps watch this; GNOME 42+ introduced the dark-style preference) :contentReference[oaicite:5]{index=5}
if [[ "$target_scheme" == "prefer-light" ]]; then
  gset_s color-scheme "prefer-light" || gset_s color-scheme "default"
else
  gset_s color-scheme "prefer-dark"
fi

# Actually change GTK theme + keep the usual knobs consistent
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

# Update hyprqt6engine (Qt apps still generally need restart to re-read theme)
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