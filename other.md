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

<!-- system monitoring aka task manager tool -->
sudo pacman -S mission-center

<!-- volume control -->
sudo pacman -S pavucontrol

<!-- docker -->
sudo pacman -S docker docker-buildx docker-compose
sudo systemctl start docker
sudo usermod -aG docker $USER