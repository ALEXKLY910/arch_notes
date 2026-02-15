1. For packages that are not in the official package list we'll have to use **yay** to install them easier. So you'll need to install **yay**:

   > `sudo pacman -S --needed git base-devel`
   > `git clone https://aur.archlinux.org/yay.git`
   > `cd yay`
   > `makepkg -si`

   You may remove the `yay` directory that was created in the process.

2. Install **Hyprland** - the **Wayland** _compositor_ that provides the graphical session (it’s the thing that actually draws frames and manages windows/input). Add **XWayland** so legacy **X11** apps can still run under **Wayland**. Install **xdg-desktop-portal** (the standard “desktop integration” API on **Wayland**) plus the **Hyprland** _portal backend_ for _compositor_ features like screenshots/screencast/screen sharing, and a **GTK** _portal backend_ so apps get a usable file picker and other dialogs:

   > `sudo pacman -S hyprland xorg-xwayland xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-kde xdg-desktop-portal-gtk`

   If prompted which _qt6 multimedia to pick_, choose `qt6-multimedia-ffmpeg`.

   Write to this config file `~/.config/xdg-desktop-portal/hyprland-portals.conf` the following:

   ```
   [preferred]
   default=hyprland;gtk
   org.freedesktop.impl.portal.FileChooser=kde
   ```

3. Install the **Kitty** terminal emulator:

   > `sudo pacman -S kitty`

4. Start **Hyprland** **as user**:
   > `start-hyprland`

### Read the _Getting started_ manual. See the required software. We'll install it now. Exit Hyprland.

#### for future reference, **Hyprland** config file is located at ~/.config/hypr/hyprland.conf

5. Edit the config file by adding the following section so that X11 apps don't render pixelated:

   ```
   xwayland {
      force_zero_scaling = true
      use_nearest_neighbor = false
   }
   ```

6. Install and configure all the required software:
   1. _Authentication agent_ (the thing that pops up a window asking you for a password whenever an app wants to elevate its privileges). We'll use **hyprpolkitagent**.

      > `sudo pacman -S hyprpolkitagent`

      Then open up **Hyprland** config file. Under _AUTOSTART_ section, add the following line:

      > `exec-once = systemctl --user start hyprpolkitagent`

   2. Install a _notification daemon_ (Many apps (e.g. Discord) may freeze without one running). We'll install **mako** - it's lightweight and doesn't actually include a notification center: it shows the notifications and forgets about them. If you really want a notification center, install **swaync** otherwise.

      > `sudo pacman -S mako`

      We don't have to wire this up manually in the config because it will be activated automatically when needed (via _D-Bus_).

   3. Install a _file manager_. We'll install a GUI, light-weight **Thunar**:

      > `sudo pacman -S thunar`

      The default keybind for opening a file manager is `SUPER+E`.

   4. Install a _clipboard_. We'll install **clipse** - it features the clipboard history overlay window.

      >`yay -S clipse`

      Add this to Hyprland's config:

      >`exec-once = clipse -listen`

      >`bind = $mainMod SHIFT, V, exec, ghostty --class=app.clipse -e clipse`

      >`windowrule = match:class ^app\.clipse$, float on, size 622 652`

      Also, install `wl-clipboard` just to make the guide shut up and it will be useful later. It's a tiny CLI clipboard thing. Gives you two commands: `wl-copy` and `wl-paste` that can write to a clipboard from _stdin_ and write to _stdout_ clipboard's contents.

      > `sudo pacman -S wl-clipboard`

   5. Install a _status bar / shell_. We'll install the most popular one - **Waybar**.

      > `sudo pacman -S waybar`

      When prompted, choose `pipewire-jack`.

      Then open up the config file and paste this under _AUTOSTART_:

      > `exec-once = waybar`

   6. Install an _app launcher_. We'll install **Hyprlauncher**:

      > `sudo pacman -S hyprlauncher`

      Add a keybind in _KEYBINDINGS_ in the config file:

      > `bind = SUPER, SPACE, exec, hyprlauncher`

   7. Install a _wallpaper_ daemon. We'll install **Hyprpaper**:

      > `sudo pacman -S hyprpaper`

      Then open up the config file and paste under _AUTOSTART_:

      > `exec-once = hyprpaper`

7. Install **Hyprlock** and **Hypridle** so that you'll have the lock screen and can auto-sleep, auto-turn-screen-off, etc.

   > `sudo pacman -S hyprlock hypridle`

   Configure **Hyprlock**. It's configuration file is located at `~/.config/hypr/hyprlock.conf`. Paste something like this for starters:

   ```
   background {
    monitor =
    color = rgba(0, 0, 0, 0.7)
   }

   input-field {
      monitor =
      size = 250, 50
      position = 0, 0
      halign = center
      valign = center
   }
   ```

   Configure **Hypridle**. It's configuration file is located at `~/.config/hypr/hypridle.conf`. Reference `arch_linux_configs/hypridle_default_config.conf`

   Then open up the config file for Hyprland and paste under _AUTOSTART_:

   > `exec-once = hypridle`

   And add a manual lock keybind under _KEYBINDINGS_:

   > `bind = SUPER, L, exec, loginctl lock-session`

8. Now let's make it so the system boots into a UI _greeter_ that then directly launches Hyprland. **greetd** is the login daemon, **tuigreet** is the actual UI you see

   > `sudo pacman -S greetd greetd-tuigreet`

   Now edit the config file located at `/etc/greetd/config.toml`. Add something like:

   ```
   [terminal]
   # TTY where the greeter runs
   vt = 7

   [default_session]
   # tuigreet as greeter, starting Hyprland via the *wrapper*
   command = "tuigreet --time --remember --asterisks --cmd start-hyprland"
   user = "greeter"
   ```

   And enable **greetd** on boot:

   > `sudo systemctl enable --now greetd.service`

9. Add some keybindings:
   - Toggle true fullscreen:

   > `bind = $mainMod, F, fullscreen, 0`
   - Toggle fullscreen in tile mode:

   > `bind = $mainMod, M, fullscreen, 0`

   _P.S. uncomment the shortcut for closing Hyprland_
   - Change the proportions of the focused tile:

   > `binde  = $mainMod SHIFT, left, splitratio, -0.05`
   > `binde  = $mainMod SHIFT, right, splitratio, +0.05`
