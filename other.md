Downloaded:

<!-- java development kit and maven project builder -->
sudo pacman -S jdk21-openjdk maven

<!-- some fonts -->
sudo pacman -S --needed noto-fonts noto-fonts-cjk && fc-cache -fv

<!-- the disk usage analyzer -->
sudo pacman -S baobab

<!-- terminal pager -->
sudo pacman -S less

<!-- some sound plugins, not using now -->
sudo pacman -S --needed lsp-plugins-lv2


<!-- realtime privileges -->
sudo pacman -S --needed realtime-privileges
sudo gpasswd -a "$USER" realtime
reboot