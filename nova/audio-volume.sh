#!/usr/bin/env bash
set -euo pipefail

VIRT="nova_fx"
STEP_RAW="${2:-5%}"

# Accept "5%" only
if [[ ! "$STEP_RAW" =~ ^[0-9]+%$ ]]; then
  echo "Step must be like 5% or 10% (got: $STEP_RAW)"
  exit 1
fi
STEP="${STEP_RAW%\%}"  # strip %

real_sinks() {
  pactl list sinks short | awk -v v="$VIRT" '$2 != v {print $2}'
}

get_vol() {
  # first percentage we find, e.g. "100"
  pactl get-sink-volume "$1" | grep -oE '[0-9]+%' | head -n1 | tr -d '%'
}

set_vol_clamped() {
  local sink="$1" target="$2"
  (( target < 0 )) && target=0
  (( target > 100 )) && target=100
  pactl set-sink-volume "$sink" "${target}%"
}

case "${1:-}" in
  up)
    real_sinks | while read -r s; do
      cur="$(get_vol "$s")"
      set_vol_clamped "$s" "$((cur + STEP))"
    done
    ;;
  down)
    real_sinks | while read -r s; do
      cur="$(get_vol "$s")"
      set_vol_clamped "$s" "$((cur - STEP))"
    done
    ;;
  mute)
    real_sinks | while read -r s; do pactl set-sink-mute "$s" toggle; done
    ;;
  fix)
    pactl set-sink-volume "$VIRT" 100%
    ;;
  *)
    echo "Usage: $0 {up|down|mute|fix} [STEP%]"
    echo "Example: $0 up 2%"
    exit 1
    ;;
esac

# Always keep NovaFX pinned at 100%
pactl set-sink-volume "$VIRT" 100%