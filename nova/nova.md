1. We are going to install and configure TDR Nova. Because TDR Nova is a Windows-only plugin, we are going to need a workaround solution. For running Windows-native applications under Linux there is a tool called **Wine**. For exposing a sound plugin working under Wine to sound hosts like **Carla** we are going to need **yabridge** and for Carla specifically, we are going to need **Pipewire JACK** because it speaks JACK's "language". And for configuring the patchbay (the sound graph) we will need **Qpwgraph**. Install all the tools:

  >`sudo pacman -S wine-staging yabridge yabridgectl carla pipewire-jack qpwgraph`

2. yabridge is tested for the older version of Wine (9.21), so downgrade:

  >`sudo pacman -U https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst`

3. Fix Wine package so that it won't get updated along other packages when you run a package update:
  >`EDITOR=nano sudoedit /etc/pacman.conf`
  Paste:
  '''
  IgnorePkg = wine-staging wine
  '''

4. Create a wine directory tree (prefix) for TDR Nova alone:

  >`WINEPREFIX="$HOME/.wine-tdr" WINEARCH=win64 wineboot -u`

5. Create a folder where you will put the TDR Nova plugin file:

  >`mkdir -p "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"`

6. Download TDR Nova for Windows (no installer)

7. Copy the TDR Nova vst3 file into `"$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3/"`

8. Stage the Nova directory in yabridge and then construct the bridge:

  >`yabridgectl add "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"`

  >`yabridgectl sync`

9. You may need realtime privileges for your user so that demanding apps like sound servers won't get messed with by internal memory management processes causing sound glitches and other issues. Check out `other.md`.

10. Open carla from the terminal. Open its settings and add ~/.vst3 into the plugin paths so that it detects the Nova plugin yabridge exposes. 

11. Settings → Configure Carla → Engine → Process mode → “Continuous Rack”. Just another way to ensure that Carla won't mess with qpwgraph's patchbay (it generally shouldn't because we later configure it to be exclusive, but anyway)

12. Add TDR Nova plugin inside Carla, open it and configure it (reference `nova/nova_*.jpg`).

13. Create a new default sink through which all the sound will be rerouted.
  >`pactl load-module module-null-sink sink_name=nova_fx sink_properties=device.description=NovaFX`

  >`pactl set-default-sink nova_fx`

  We need this step because otherwise we won't be able to route through TDR Nova systemwide. We need one sink through which all the apps will be sending their audio. Then we route the output of that sink through Nova.

14. Open qpwgraph, connect NovaFX sink's output to the Nova plugin's input. Connect Nova plugin's output to the DAC, make it exclusive and save the graph to `~/.config/qpwgraph/nova-dac.qpwgraph`.

15. Open qpwgraph, connect NovaFX sink's output to the Nova plugin's input. Connect Nova plugin's output to the Builtin audio device, make it exclusive and save the graph to `~/.config/qpwgraph/nova-builtin.qpwgraph`.


16. Make NovaFX be the default sink permanently: 
    '''
    pulse.cmd = [
      { cmd = "load-module"
        args = "module-null-sink sink_name=nova_fx sink_properties=device.description=NovaFX"
      }
    ]
    '''
    into `~/.config/pipewire/pipewire-pulse.conf.d/nova-fx.conf`


    `systemctl --user restart pipewire-pulse`

17. Save the carla project into `~/.config/carla/nova.carxp`

18. Autostart carla's project in the 9th workspace by adding the following to autostart section of hyprland.conf:
  '''
  windowrule = workspace 9 silent, match:class ^(carla)$
  exec-once = carla ~/.config/carla/nova.carxp
  '''

19. Install a more advanced volume control app:
  >`sudo pacman -S --needed pavucontrol`

  In pavucontrol check out output devices, make sure that NovaFX is at 100% and you change the actual output devices' volume. 

Right now it's all supposed to work but we can't change the volume of our actual devices because the default knobs affect the default sink which in our case must stay at 100%. Also the current logic doesn't change the qpwgraph's patchbay on whether the DAC is plugged in or not, we want to automate that.

20. Create a script that selects the patchbay based on whether the DAC is plugged in. If it is, qpwgraph loads `nova-dac.qpwgraph`, if it isn't it loads `nova-builtin.qpwgraph`. Reference `nova/qpwgraph-select-audio.sh`.

21. For making it automatically run the script based on when the DAC is plugged in or not, we need to first make qpwgraph a user service:
  >`pkill qpwgraph || true`
  >`systemctl --user daemon-reload`
  >`systemctl --user enable --now qpwgraph.service`

22. Now create dac-hotplug.service and dac-hotplug.path. The latter watches the pluggin in/out and the former runs the script and restarts qpwgraph's service. Reference `nova/dac-hotplug.service` and `nova/dac-hotplug.path`.

  >`systemctl --user daemon-reload`
  >`systemctl --user enable --now dac-hotplug.path`

23. Run qpwgraph-select-audio on startup (with this keybinding):  
  >`bind = $mainMod SHIFT, A, exec, ~/.local/bin/qpwgraph-select-audio`

24. Create the script that changes the volume of the devices. Reference `nova/audio-volume.sh`.

25. Change the default keybindings for changing the volume to implement the script:
  '''
  bindel = , XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up
  bindel = , XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down

  bindel = SHIFT, XF86AudioRaiseVolume, exec, ~/.local/bin/audio-volume up 1%
  bindel = SHIFT, XF86AudioLowerVolume, exec, ~/.local/bin/audio-volume down 1%

  bindel = , XF86AudioMute, exec, ~/.local/bin/audio-volume mute
  ```
Now the default keybindings change the actual volume of the devices.

26. Make Waybar show the volume of the devices and change the volume of the devices when you scroll the sound icon:
  26.1 Create volume-status.sh under waybar/scripts. Reference `nova/volume-status.sh`
  26.2 Replace waybar's config.jsonc with the contents of config-nova.jsonc




