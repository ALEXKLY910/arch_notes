remove autostart line for the qpwgraph.

Create a script qpwgraph-select-audio.sh
Create a qpwgraph user service
Run the script

pkill qpwgraph || true
systemctl --user daemon-reload
systemctl --user enable --now qpwgraph.service

Create doc-hotplug.service and doc-hotplug.path

systemctl --user daemon-reload
systemctl --user enable --now dac-hotplug.path

Run qpwgraph-select-audio on startup (with this keybinding):
bind = $mainMod SHIFT, A, exec, ~/.local/bin/qpwgraph-select-audio

Create audio-volume script.

Tie it down to the main volume knob:
bindel = , XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up
bindel = , XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down

bindel = SHIFT, XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up 1%
bindel = SHIFT, XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down 1%

bindel = , XF86AudioMute, exec, ~/.local/bin/audio-volume mute

Create volume-status.sh under waybar/scripts
Replace waybar's config.jsonc with the contents of config-nova.jsonc


# Update hyprland-current.conf in the docs








