#!/usr/bin/env bash
set -euo pipefail

# Set this to your DAC symlink from: ls -l /dev/snd/by-id/
DAC_DEV="/dev/snd/by-id/usb-TTGK_Technology_Co._Ltd_CX31993_384Khz_HIFI_AUDIO-00"

DAC_SINK="alsa_output.usb-TTGK_Technology_Co._Ltd_CX31993_384Khz_HIFI_AUDIO-00.analog-stereo"
BUILTIN_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"

SINK="$BUILTIN_SINK"
[[ -e "$DAC_DEV" ]] && SINK="$DAC_SINK"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-volume.txt"
mkdir -p "$(dirname "$CACHE")"

pactl_t() { timeout 1s pactl "$@" 2>/dev/null; }

vol_line="$(pactl_t get-sink-volume "$SINK" || true)"
mute_line="$(pactl_t get-sink-mute "$SINK" || true)"

# If pactl hangs/fails, don’t freeze Waybar: show last known value
if [[ -z "$vol_line" || -z "$mute_line" ]]; then
  [[ -f "$CACHE" ]] && cat "$CACHE" || printf "󰕿 ?%%\n"
  exit 0
fi

vol="$(grep -oE '[0-9]+%' <<<"$vol_line" | head -n1 | tr -d '%')"
muted=0
grep -q 'yes' <<<"$mute_line" && muted=1

if (( muted )); then
  icon="󰝟"
else
  if   (( vol < 34 )); then icon="󰕿"
  elif (( vol < 67 )); then icon="󰖀"
  else                     icon="󰕾"
  fi
fi

out="$(printf "%s %d%%\n" "$icon" "$vol")"
printf "%s" "$out" | tee "$CACHE"