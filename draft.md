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


The desktop-entry approach looks like this: copy the app’s .desktop file into ~/.local/share/applications/, then edit its Exec= line to prefix env QT_QPA_PLATFORMTHEME=qt5ct …. That exact trick is a standard way people force a Qt app to use a specific platform theme.


