#!/bin/sh

SERVICE="syncthing.service"
SERVICE_NAME="Syncthing"

if systemctl --user is-active --quiet "$SERVICE"; then
    if systemctl --user stop "$SERVICE"; then
        notify-send "$SERVICE_NAME" "Stopped"
    else
        notify-send "$SERVICE_NAME" "Failed to stop"
    fi
else
    if systemctl --user start "$SERVICE"; then
        notify-send "$SERVICE_NAME" "Started"
    else
        notify-send "$SERVICE_NAME" "Failed to start"
    fi
fi