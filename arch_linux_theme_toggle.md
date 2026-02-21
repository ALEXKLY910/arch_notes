1. Install necessary packages:
    >`sudo pacman -S --needed dconf gsettings-desktop-schemas breeze gnome-themes-extra`
    >`yay -S hyprqt6engine`

2. Make Hyprland export **hyprqt6engine** for user services. Put this into `~/.config/hypr/hyprland.conf` near the top:
    ```
    env = QT_QPA_PLATFORMTHEME,hyprqt6engine

    exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORMTHEME
    ```
    Then reboot so the portals are properly restarted.

    Put into `~/.config/hypr/hyprqt6engine.conf`:
    ```
    theme {
    style = Fusion
    icon_theme = Breeze
    color_scheme = /usr/share/color-schemes/BreezeLight.colors
    }
    misc {
    single_click_activate = true
    menus_have_icons = true
    shortcuts_for_context_menus = true
    }
  ```

3. Create `~/.local/bin/toggle-theme` file:
    >`mkdir -p ~/.local/bin`
    >`touch ~/.local/bin/toggle-theme`
    >`chmod +x ~/.local/bin/toggle-theme`

5. Paste the contents of `arch-notes/arch_linux_configs/toggle-theme.sh` into `~/.local/bin/toggle-theme`.

6. Bind it in Hyprland. Add this to `~/.config/hypr/hyprland.conf`:
    >`bind = $mainMod SHIFT, T, exec, ~/.local/bin/toggle-theme`

    Reload so that you can use it:
    >`hyprctl reload`
