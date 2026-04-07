#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-toggle}"

STATE="${XDG_CACHE_HOME:-$HOME/.cache}/audio-mode"
WB="$HOME/.config/waybar"
HYPR="$HOME/.config/hypr/conf"
CARLA_PROJECT="$HOME/.config/carla/nova.carxp"

DAC_DEV="/dev/snd/by-id/usb-TTGK_Technology_Co._Ltd_CX31993_384Khz_HIFI_AUDIO-00"
DAC_SINK="alsa_output.usb-TTGK_Technology_Co._Ltd_CX31993_384Khz_HIFI_AUDIO-00.analog-stereo"
BUILTIN_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
NOVA_SINK="nova_fx"

mkdir -p "$(dirname "$STATE")" "$HYPR"

real_sink() {
  if [[ -e "$DAC_DEV" ]]; then
    printf '%s\n' "$DAC_SINK"
  else
    printf '%s\n' "$BUILTIN_SINK"
  fi
}

restart_waybar() {
  pkill waybar || true
  nohup waybar >/dev/null 2>&1 &
}

move_all_inputs() {
  local dst="$1"
  pactl list short sink-inputs | awk '{print $1}' | while read -r id; do
    pactl move-sink-input "$id" "$dst" || true
  done
}

ensure_nova_sink() {
  if ! pactl list short sinks | awk '{print $2}' | grep -qx "$NOVA_SINK"; then
    pactl load-module module-null-sink \
      sink_name="$NOVA_SINK" \
      sink_properties=device.description=NovaFX >/dev/null
    sleep 1
  fi
  pactl set-sink-volume "$NOVA_SINK" 100% || true
  pactl set-sink-mute "$NOVA_SINK" 0 || true
}

remove_nova_sink() {
  pactl list short modules | awk '/module-null-sink/ && /sink_name=nova_fx/ {print $1}' | while read -r id; do
    pactl unload-module "$id" || true
  done
}

notify_mode() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Audio mode" "$1"
}

case "$ACTION" in
  auto)
    if [[ -f "$STATE" ]]; then
      ACTION="$(<"$STATE")"
    else
      ACTION="normal"
    fi
    ;;
  toggle)
    if [[ -f "$STATE" && "$(cat "$STATE")" == "nova" ]]; then
      ACTION="normal"
    else
      ACTION="nova"
    fi
    ;;
esac

case "$ACTION" in
  nova)
    ln -sfn "$WB/config-nova.jsonc" "$WB/config.jsonc"
    ln -sfn "$HYPR/audio-nova.conf" "$HYPR/audio-active.conf"

    ensure_nova_sink
    pactl set-default-sink "$NOVA_SINK"
    move_all_inputs "$NOVA_SINK"

    if ! pgrep -x carla >/dev/null; then
      hyprctl dispatch exec "carla $CARLA_PROJECT"
      sleep 2
    fi

    "$HOME/.local/bin/qpwgraph-select-audio" || true
    systemctl --user start dac-hotplug.path
    
    printf 'nova\n' > "$STATE"
    hyprctl reload
    restart_waybar
    notify_mode "Nova mode enabled"
    ;;
  normal)
    ln -sfn "$WB/config-normal.jsonc" "$WB/config.jsonc"
    ln -sfn "$HYPR/audio-normal.conf" "$HYPR/audio-active.conf"

    systemctl --user stop dac-hotplug.path qpwgraph.service || true

    REAL_SINK="$(real_sink)"
    pactl set-default-sink "$REAL_SINK"
    move_all_inputs "$REAL_SINK"

    pkill -x carla || true
    remove_nova_sink

    printf 'normal\n' > "$STATE"
    hyprctl reload
    restart_waybar
    notify_mode "Normal mode enabled"
    ;;
  *)
    echo "Usage: audio-mode {toggle|nova|normal|auto}"
    exit 1
    ;;
esac