#!/usr/bin/env bash
set -euo pipefail

default="eng"

langs="$(kdialog --title "OCR" --inputbox "Tesseract language code(s). Example: eng+jpn" "$default" 2>/dev/null || true)"

# Cancel or empty input -> do nothing
[[ -z "${langs// /}" ]] && exit 0

# Validate against installed language models
available="$(tesseract --list-langs | tail -n +2)"
IFS='+' read -ra parts <<<"$langs"
for l in "${parts[@]}"; do
  l="${l// /}"
  [[ -z "$l" ]] && continue
  if ! printf "%s\n" "$available" | grep -Fxq "$l"; then
    command -v notify-send >/dev/null && notify-send "OCR" "Language '$l' not installed. Check: tesseract --list-langs"
    exit 1
  fi
done

tmp="$(mktemp --suffix=.png)"
grim -g "$(slurp)" "$tmp"

text="$(tesseract "$tmp" stdout -l "$langs" --psm 6 | sed 's/[[:space:]]\+$//')"
printf "%s" "$text" | wl-copy

command -v notify-send >/dev/null && notify-send "OCR" "Copied to clipboard (${langs})"
rm -f "$tmp"