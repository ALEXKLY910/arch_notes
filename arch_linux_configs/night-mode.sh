#!/usr/bin/env bash
set -euo pipefail

hyprctl hyprsunset temperature 5000
~/.local/bin/theme-switcher dark
brightnessctl set 15%
