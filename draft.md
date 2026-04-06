# TDR Nova on Arch Linux with Hyprland as a switchable mode

We are going to set up two audio modes: **Normal mode** and **Nova mode**. We will switch between the two with SUPER+SHIFT+E.

1. Install the required packages. **Wine** runs Windows stuff on Linux. **yabridge** exposes Windows plugins to Linux hosts. **Carla** hosts the plugin. **pipewire-jack** lets Carla speak JACK through PipeWire. **qpwgraph** manages the audio graph.
    >`sudo pacman -S wine-staging yabridge yabridgectl carla pipewire-jack qpwgraph`

2. Downgrade Wine to the version **yabridge** is known to behave well with. 
    1. Install Wine 9.21:
        >`sudo pacman -U https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst`
    2. Pin it so updates do not silently change it later:
        >`EDITOR=nano sudoedit /etc/pacman.conf`
        Add this:
        '''
        IgnorePkg = wine-staging wine
        '''

3. Create a separate Wine prefix for TDR Nova. A Wine prefix is basically a fake Windows install folder. We make one just for Nova so it stays isolated.
    >`WINEPREFIX="$HOME/.wine-tdr" WINEARCH=win64 wineboot -u`

4. Create the VST3 folder inside that prefix:
    >`mkdir -p "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"`

5. Download the no-installer Windows VST3 version of TDR Nova. Then copy the .vst3 plugin into:
    >`"$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3/"`

6. Bridge the plugin with yabridge. This will make the Windows plugin show up to Linux hosts like Carla.
    >`yabridgectl add "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"`
    >`yabridgectl sync`

7. You may need realtime privileges for your user so that demanding apps like sound servers won't get messed with by internal memory management processes causing sound glitches and other issues. Check out `other.md`.

8. Open carla from the terminal. Open its settings and add ~/.vst3 into the plugin paths so that it detects the Nova plugin yabridge exposes. Then set: Settings → Configure Carla → Engine → Process mode → “Continuous Rack”. Just another way to ensure that Carla won't mess with qpwgraph's patchbay (it generally shouldn't because we later configure it to be exclusive, but anyway)

9. Add TDR Nova plugin inside Carla, open it and configure it (reference `nova/nova_*.jpg`). Then save the project to `~/.config/carla/nova.carxp`.

10. Create the Nova virtual sink for testing. This is the audio entry point used only in Nova mode. Apps send sound into `nova_fx`, then that audio gets routed through TDR Nova, then into your real device.
    >`pactl load-module module-null-sink sink_name=nova_fx sink_properties=device.description=NovaFX`
    >`pactl set-default-sink nova_fx`
11. Build the qpwgraph patchbay for both output cases. Open qpwgraph and make two saved graphs.
        1. DAC graph: connect NovaFX output to TDR Nova input and TDR Nova output to DAC device. Mark it EXCLUSIVE and save it as `~/.config/qpwgraph/nova-dac.qpwgraph`
        2. Builtin graph: connect NovaFX output to TDR Nova input and TDR Nova putput to built-in audio device. Mark it EXCLUSIVE and save it as `~/.config/qpwgraph/nova-builtin.qpwgraph`.

12. Rename your current old Waybar config once: 
    `mv ~/.config/waybar/config.jsonc ~/.config/waybar/config-normal.jsonc`.

    Create `~/.config/waybar/config-nova.jsonc`, put the contents of `arch_linux_configs/waybar/nova/config-nova.jsonc` inside.

    Then make the active config a symlink:
    >`ln -sfn ~/.config/waybar/config-normal.jsonc ~/.config/waybar/config.jsonc`

13. Create several scripts. Paste here:
    > `~/.config/waybar/scripts/volume-status`
    > `~/.local/bin/audio-volume`
    > `~/.local/bin/qpwgraph-select-audio`
    
    The contents of this respectfully:
    > `arch_linux_configs/waybar/nova/volume-status.sh`
    > `nova/audio-volume.sh`
    > `nova/qpwgraph-select-audio.sh`

    And make each of them executable:
    > `chmod +x ~/.config/waybar/scripts/volume-status`
    > `chmod +x ~/.local/bin/audio-volume`
    > `chmod +x ~/.local/bin/qpwgraph-select-audio`
    
14. Create the qpwgraph systemd user service. Paste the contents of `nova/qpwgraph.service` into `~/.config/systemd/user/qpwgraph.service`.

15. Create the DAC hotplug units. Paste into `~/.config/systemd/user/dac-hotplug.service` the contents of `nova/dac-hotplug.service`. And into `~/.config/systemd/user/dac-hotplug.path` the contents of `nova/dac-hotplug.path`. This makes the system react when the DAC is plugged in or unplugged. The helper script itself just chooses nova-dac.qpwgraph or nova-builtin.qpwgraph and restarts qpwgraph. Reload uesr systemd: `systemctl --user daemon-reload`

16. Split Hyprland audio keybinds into two small files.
    1. Create the folder: `mkdir -p ~/.config/hypr/conf`
    2. Create `~/.config/hypr/conf/audio-normal.conf`:
        ```
        # Laptop multimedia keys for volume and LCD brightness
        bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        bindel = SHIFT,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+
        bindel = SHIFT,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-
        bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ```
    3. Create `~/.config/hypr/conf/audio-nova.conf`:
        ```
        # Laptop multimedia keys for volume and LCD brightness
        bindel = , XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up
        bindel = , XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down
        bindel = SHIFT, XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up 1%
        bindel = SHIFT, XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down 1%
        bindel = , XF86AudioMute, exec, ~/.local/bin/audio-volume mute
        ```

    4. Create the symlink:
        >`ln -sfn ~/.config/hypr/conf/audio-normal.conf ~/.config/hypr/conf/audio-active.conf`

18. Create the mode-switch script at `~/.local/bin/audio-mode`. Reference `nova/audio-mode.sh`