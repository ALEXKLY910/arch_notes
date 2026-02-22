#!/usr/bin/env bash
set -euo pipefail

notify() {
  notify-send -a "zapret" "$1" "${2:-}"
}

notify "Toggling zapret..."

status="$(
  sudo /usr/bin/bash "$HOME/zapret-discord-youtube-linux/service.sh" --status
)"

if echo "$status" | grep -Fq "Статус: Сервис установлен и активен."; then
  if sudo /usr/bin/bash "$HOME/zapret-discord-youtube-linux/service.sh" --stop; then
    notify "Stopped" "Service is now inactive."
  else
    notify "Stop failed" "Check logs / permissions."
    exit 1
  fi
else
  if sudo /usr/bin/bash "$HOME/zapret-discord-youtube-linux/service.sh" general_alt.bat; then
    notify "Started" "Service is now active."
  else
    notify "Start failed" "Check logs / permissions."
    exit 1
  fi
fi