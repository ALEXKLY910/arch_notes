pid="$(ps -u "$USER" -o pid=,args= | awk '$2=="/usr/lib/xdg-desktop-portal-kde"{print $1; exit}')"
echo "KDE portal PID=$pid"



~/.local/share/color-schemes/Bait.colors



Add to hyprland:
env = QT_QUICK_CONTROLS_STYLE,org.kde.desktop

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORMTHEME QT_QUICK_CONTROLS_STYLE
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORMTHEME QT_QUICK_CONTROLS_STYLE

