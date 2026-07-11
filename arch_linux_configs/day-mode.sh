#!/usr/bin/env bash
set -euo pipefail

hyprctl hyprsunset identity
~/.local/bin/theme-switcher light
brightnessctl set 100%
