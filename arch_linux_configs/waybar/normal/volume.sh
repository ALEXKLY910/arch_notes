#!/usr/bin/env bash
set -euo pipefail

action="${1:-print}"

if command -v wpctl >/dev/null 2>&1; then
  sink='@DEFAULT_AUDIO_SINK@'
  case "$action" in
    up)   wpctl set-volume -l 1.0 "$sink" 1%+ ;;
    down) wpctl set-volume        "$sink" 1%- ;;
    mute) wpctl set-mute          "$sink" toggle ;;
    print|*)
      line="$(wpctl get-volume "$sink")"              # e.g. "Volume: 0.45 [MUTED]"
      v="$(awk '{print $2}' <<<"$line")"              # 0.45
      vol="$(awk -v v="$v" 'BEGIN{printf "%d", v*100+0.5}')"  # 45
      if grep -qi muted <<<"$line"; then
        icon="󰝟"
      else
        if   (( vol < 34 )); then icon="󰕿"
        elif (( vol < 67 )); then icon="󰖀"
        else                     icon="󰕾"
        fi
      fi
      printf "%s %d%%\n" "$icon" "$vol"
      ;;
  esac
else
  sink='@DEFAULT_SINK@'
  case "$action" in
    up)   pactl set-sink-volume "$sink" +1% ;;
    down) pactl set-sink-volume "$sink" -1% ;;
    mute) pactl set-sink-mute   "$sink" toggle ;;
    print|*)
      vol="$(pactl get-sink-volume "$sink" | sed -n 's/.* \([0-9]\+\)%.*/\1/p' | head -n1)"
      if pactl get-sink-mute "$sink" | grep -q yes; then
        icon="󰝟"
      else
        if   (( vol < 34 )); then icon="󰕿"
        elif (( vol < 67 )); then icon="󰖀"
        else                     icon="󰕾"
        fi
      fi
      printf "%s %d%%\n" "$icon" "$vol"
      ;;
  esac
fi