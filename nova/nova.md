sudo pacman -S wine-staging yabridge yabridgectl carla pipewire-jack qpwgraph

sudo pacman -U https://archive.archlinux.org/packages/w/wine-staging/wine-staging-9.21-1-x86_64.pkg.tar.zst


EDITOR=nano sudoedit /etc/pacman.conf
IgnorePkg = wine-staging wine

WINEPREFIX="$HOME/.wine-tdr" WINEARCH=win64 wineboot -u


mkdir -p "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"

Download TDR Nova (no installer)

Copy the TDR Nova vst3 file into "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3/"

yabridgectl add "$HOME/.wine-tdr/drive_c/Program Files/Common Files/VST3"

yabridgectl sync

sudo pacman -S --needed realtime-privileges
sudo gpasswd -a "$USER" realtime
reboot

Open carla from the terminal. Open its settings and add ~/.vst3 into the plugin paths.

Settings → Configure Carla → Engine → Process mode → “Continuous Rack”.

Add TDR Nova plugin.

Open it.

Configure it.


pactl load-module module-null-sink sink_name=nova_fx sink_properties=device.description=NovaFX

pactl set-default-sink nova_fx

Connect NovaFX monitor_FL -> TDR Nova input_1

Connect NovaFX monitor_FR -> TDR Nova input_2

Connect TDR Nova output_1 -> your real device playback_FL

Connect TDR Nova output_2 -> your real device playback_FR
Make it exclusive

In qpwgraph save the current graph to ~/.config/qpwgraph/nova-dac.qpwgraph


Then reconnect TDR Nova outputs to Built-in audio analog stereo and save it to 
~/.config/qpwgraph/nova-builtin.qpwgraph
Make it exclusive



Put this: 
'''
pulse.cmd = [
  { cmd = "load-module"
    args = "module-null-sink sink_name=nova_fx sink_properties=device.description=NovaFX"
  }
]
'''
into ~/.config/pipewire/pipewire-pulse.conf.d/nova-fx.conf 


systemctl --user restart pipewire-pulse


Save the carla project into ~/.config/carla/nova.carxp

Add this to autostart:
windowrule = workspace 9 silent, match:class ^(carla)$
exec-once = carla ~/.config/carla/nova.carxp

sudo pacman -S --needed pavucontrol

In pavucontrol check out output devices, make sure that NovaFX is at 100% and you change the actual output devices' volume. 