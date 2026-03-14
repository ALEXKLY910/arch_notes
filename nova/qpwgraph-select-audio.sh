#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/qpwgraph"
ACTIVE="$CFG/nova-active.qpwgraph"

# CHANGE THIS to the exact symlink you see in: ls -l /dev/snd/by-id/
DAC_DEV="/dev/snd/by-id/usb-TTGK_Technology_Co._Ltd_CX31993_384Khz_HIFI_AUDIO-00"

if [[ -e "$DAC_DEV" ]]; then
  ln -sf "$CFG/nova-dac.qpwgraph" "$ACTIVE"
else
  ln -sf "$CFG/nova-builtin.qpwgraph" "$ACTIVE"
fi

systemctl --user restart qpwgraph.service