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

sink_id_by_name() {
  pactl list short sinks | awk -v name="$1" '$2 == name {print $1; exit}'
}

move_inputs_from_sink() {
  local src_name="$1" dst_name="$2" src_id
  src_id="$(sink_id_by_name "$src_name")"
  [[ -n "$src_id" ]] || return 0

  pactl list short sink-inputs | awk -v sid="$src_id" '$2 == sid {print $1}' | while read -r input_id; do
    pactl move-sink-input "$input_id" "$dst_name" || true
  done
}

stop_proc() {
  local name="$1"
  pkill -x "$name" || true
  for _ in {1..30}; do
    pgrep -x "$name" >/dev/null || return 0
    sleep 0.1
  done
  return 0
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

    if ! pgrep -x carla >/dev/null; then
      hyprctl dispatch exec "carla $CARLA_PROJECT"
      sleep 2
    fi

    "$HOME/.local/bin/qpwgraph-select-audio" || true
    systemctl --user start dac-hotplug.path

    # Move only after the Nova path exists
    sleep 0.5
    pactl set-default-sink "$NOVA_SINK"
    move_all_inputs "$NOVA_SINK"
    sleep 0.3
    move_all_inputs "$NOVA_SINK"

    printf 'nova\n' > "$STATE"
    hyprctl reload
    restart_waybar
    notify_mode "Nova mode enabled"
    ;;

  normal)
    ln -sfn "$WB/config-normal.jsonc" "$WB/config.jsonc"
    ln -sfn "$HYPR/audio-normal.conf" "$HYPR/audio-active.conf"

    REAL_SINK="$(real_sink)"

    # Kill everything that can keep enforcing the Nova graph
    systemctl --user stop dac-hotplug.path qpwgraph.service || true
    stop_proc qpwgraph
    stop_proc carla
    sleep 0.5

    # Make hardware default again
    pactl set-default-sink "$REAL_SINK"

    # Explicitly move anything still stuck on nova_fx
    for _ in {1..6}; do
      move_inputs_from_sink "$NOVA_SINK" "$REAL_SINK"
      sleep 0.2
    done

    # Then sweep any remaining sink-inputs to the real sink
    move_all_inputs "$REAL_SINK"
    sleep 0.2
    move_all_inputs "$REAL_SINK"

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