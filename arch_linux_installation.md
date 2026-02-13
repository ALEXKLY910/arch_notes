[Official download page]: https://archlinux.org/download/

# Chapter 1. Arch Linux installation process, documented.

### This assumes UEFI, no dual-boot, single drive, single ext4 root + EFI partition, no swap partition, 64-bit only.

<!-- In order to view the preview of this Markdown in VS Code, hit Ctrl+Shift+V -->

1.  Go to [Official download page][Official download page], download **.torrent** file for the ISO. And the signature file ending with **.iso.sig**. Open up the **.torrent** file, for example, with **μTorrent**, download the ISO.

2.  You can either
    - verify that the downloaded ISO was not corrupted: check for **integrity**
    - verify that the downloaded ISO was not corrupted AND can be trusted: check for **integrity** and **authenticity**

    I recommend the second option. But I'm gonna list both.
    1. Verify that the downloaded ISO was not corrupted in any way by computing SHA256 hash of the ISO file and comparing it to the one listed on the [Official download page][Official download page].

       Use this command for computing the hash, it uses **certutil** - a preinstalled Windows utility (available on basically every Windows version):

       > `certutil -hashfile "C:\path\to\archlinux-2026.02.01-x86_64.iso" SHA256 > hash.txt`

       and then compare, for example, in **Powershell**:

       > ```powershell
       > $content = (Get-Content .\path\to\hash.txt -Raw).Trim()
       > if ($content -eq "ACTUALL_HASH_FROM_THE_PAGE"){
       > "Match"
       > }
       > else{
       > "No match"
       > }
       > ```

    2. Verify that the downloaded ISO hasn't been maliciously tampered with and can be trusted, by checking whether its PGP signature is valid. For it you will need a tool, for example **GnuPG**. In order for it to work on Windows, you'll need to first install [**Gpg4win**](https://www.gpg4win.org/), run it and then finally install **GnuPG** (uncheck all the other boxes during the installation).

       To verify that GnuPG was successfully installed and added to PATH, run:

       > `gpg --version`

       Then to verify the signature, first ensure that the ISO and the signature file are located in the same directory, then go the the directory where you store the ISO and the signature file, and:
       1. Download the signing key from WKD (needed for verification alongside the signature file):
          > `gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org`
       2. Verify that the signature is valid:
          > `gpg --verify archlinux-2026.02.01-x86_64.iso.sig archlinux-2026.02.01-x86_64.iso`

    The output must look something like this:

    ```
    C:\Users\ALEXKLY\Downloads>gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
    gpg: enabled compatibility flags:
    gpg: использую модель доверия pgp
    gpg: pub  ed25519/76A5EF9054449A5C 2022-10-31  Pierre Schmitz <pierre@archlinux.de>
    gpg: ключ 76A5EF9054449A5C: импортирован открытый ключ "Pierre Schmitz <pierre@archlinux.org>"
    gpg: no running gpg-agent - starting 'C:\\Program Files\\Gpg4win\\..\\GnuPG\\bin\\gpg-agent.exe'
    pub   ed25519 2022-10-31 [SC] [   годен до: 2037-10-27]
          3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C
    uid         [ неизвестно ] Pierre Schmitz <pierre@archlinux.org>
    sub   ed25519 2022-10-31 [A] [   годен до: 2037-10-27]
          340A4851793E61A36CE91EAFD6D13C45BFCFBAFD
    sub   cv25519 2022-10-31 [E] [   годен до: 2037-10-27]
          70B3000A32970956A8D52FCF7F56ADE50CA3D899

    ```

3.  Prepare the installation medium. Plug in a USB drive with NO useful data on it (it will be erased). We'll need to partition it and format it to FAT32 using **diskpart** (a Windows tool for manipulating disks and partitions, preinstalled on every relevant Windows version); you will need to run the following commands _as an Administrator_. This will work for UEFI-boots only - which is fine by us since that's what we're gonna be using anyway:
    1. Start an interactive shell inside of which we will run all the following commands:

       > `diskpart`

    2. List all physical disks currently plugged in into the system:

       > `list disk`

    3. Identify the USB stick by its size. **BE CAREFUL**. If you choose the wrong stick and proceed to format it, you will lose all your data. The disks are numbered. Select the USB stick by its number. For example, **IN MY CASE**, it's been assigned the number 1:

       > `select disk 1`

       _P.S. if you accidentally selected the wrong disk, resellect the right one NOW! by running the same command, but with the right number instead_

    4. To delete the existing partitions layout (without wiping all the data yet), run:

       > `clean`

    5. Create a single 8000MB primary partition (you may have to resellect the USB stick disk after the previous step). We cap the size because in order to further format it to FAT32 it must be smaller than 32GB. ~8GB is more than enough for Arch ISO:

       > `create partition primary size=8000`

    6. Select the created partition by its index (it normally should be selected automatically, but just to be sure). First, list the partitions:

       > `list partition`

       Then select:

       > `select partition 1`

    7. Format the partition to FAT32 file system (we'll do a quick format for our purposes) and assign a volume name that you'll see in Explorer (I'll make it be _"ARCHISO"_):

       > `format fs=fat32 quick label=ARCHISO`

    8. Now our volume should be displayed in Explorer with the size of roughly 8Gb. If it didn't display there, run the following command to assign it a volume letter:

       > `assign`

    9. Run this to exit the interactive shell:

       > `exit`

    10. Right click on **archlinux-version-x86_64.iso** and select **Mount**.

    11. Navigate to the newly created DVD drive (with Arch files on it) and copy all files and folders to the USB flash drive.

    12. When done copying, right click on the DVD drive and select Eject.

4.  Boot the live environment
    1.  Disable the **UEFI Secure boot**, because Arch Linux installation images do not support it:
        - Go to UEFI firmware interface, navigate to Security tab, find Secure boot, disable it. The process may differ from interface to interface, but should be pretty intuitive. Save the changes and exit the interface.
    2.  Open the Boot menu and boot from the USB. When the installation medium's boot menu appears, select _Arch Linux install medium_.
5.  Set the console font to a bigger one:
    > `setfont ter-132b`
6.  Verify that you are booted in UEFI mode. This command should return `64`:
    > `cat /sys/firmware/efi/fw_platform_size`
7.  Configure network
    1. Ensure your network interface is listed:

       > `ip link`

       You'll see `lo` - ignore it. The stuff to pay attention to is whether there is entries like `enp3s0`, `enp0s25`, `eno1` for Ethernet or `wlp2s0`, `wlan0` for Wi-Fi.

    2. For Wi-Fi make sure that the card is not blocked. By running:

       > `rfkill`

       If it says, for example, that **wlan** is _soft locked_, then run:

       > `rfkill unblock wlan`

       If it is _hard locked_ you have to manually switch some kind of hardware button to unlock it.

    3. Connect to the network. For the Ethernet you have to just plug in the cable. For Wi-Fi use `iwctl` for configuration:
       1. To enter the interactive shell, run (to exit it later, press `Ctrl+d`):
          > `iwctl`
       2. List the devices' names:

          > `device list`

          If the device is turned off, run (instead of `wlan0` enter the actual device name. It's just that in my case it was `wlan0`.):

          > `device wlan0 set-property Powered on`

       3. Then, scan the networks (this command will not output anything):
          > `station wlan0 scan`
       4. Now you can list all available networks (the list autoupdates, so if you don't see your network there you may have to wait for it to appear):
          > `station wlan0 get-networks`
       5. Finally, connect to a network (instead of SSID, enter the actual SSID (_Wi-Fi network name_)):

          > `station wlan0 connect SSID`

          After it you may be prompted to enter the passphrase (the Wi-Fi password).

       6. Now you should be connected. To verify the connection, ping a site:

          > `ping -c 3 archlinux.org`

          If it sends stuff back, then you're good.

8.  The system clock must synchronize itself with reality once the system is connected to the internet. Although, just to make sure that it did, run:

    > `timedatectl`

    It should show the current time.

9.  Partitioning the disk
    1. When recognized by the live system, physical disks are assigned to _block devices_. For example, _/dev/sda_, _/dev/nvme0n1_, etc. To see such devices, run:

       > `fdisk -l`

       There recognize the _device_ onto which you will be installing Arch linux by its size. The result eiding in `loop` may be ignored.

    2. Run the following program to enter the editing mode of the selected _device_, in my example I'll be editing (i.e. partitioning in our case) _/dev/sda_:

       > `fdisk /dev/sda`

       All the changes thankfully will remain only in memory until we commit. If you want to bail out at whatever point, simply run `q`.

    3. Next we'll wipe the existing partition table and create a new one of type GPT (GUID Partitioning Table). Run:
       > `g`
    4. To create a new partition, run:

       > `n`

       It will ask for:
       - partition number. Simply press Enter and go with the default one
       - first sector. Press Enter, take default
       - Last sector. This is where you define the size of the partition. You write +512M to assign it to be 512MB, +1G corresponds to 1GB, and etc. Pressing Enter would assign all remaining space on the _device_.

       First we'll create the _EFI partition_. The recommended size for it the guide suggests is 1GB.  
       So, we would do: `n`, **Enter**, **Enter**, `+1G`.  
       At the end it may say that the created partition contains some kind of signature (in my case it was _vfat_), when prompted whether to remove it, we'll leave it be. Just because we are going to reformat it anyway in the future.

       We'll also need to change the type of the created partition. To change a type, run:

       > `t`

       If there is only one partition on the disk, we can specify its type right away. If there were multiple partitions, we'd have to specify the partition's number.

       When prompted to enter the type, we'll write `uefi` for our EFI partition.

       Good. Now to the main Linux partition. I.e. _root partition_

       We would do: `n`, **Enter**, **Enter**, **Enter** (to take all remaining space).

       We won't configure _swap partition_ for now. We got good 8GB of RAM and _swap_ is not strictly needed.

       Now to check the draft of all the partitions we are about to commit, run:

       > `p`

       And finally, to commit all the changes (**THINK TWICE BEFORE DOING IT**), run:

       > `w`

10. Formatting the partitions.

    From now on I'm gonna refer to my _root partition_ as `/dev/root_partition` in code, although its actual name would be `/dev/sda2`. And to my _EFI partition_ as `/dev/efi_partition`, although its actual name would be `/dev/sda1`.

    To format the _root partition_ to **ext4**, run:

    > `mkfs.ext4 /dev/root_partition`

    To format the _efi partition_ to **FAT32**, run:

    > `mkfs.fat -F 32 /dev/efi_partition`

    To check that you formatted the partitions correctly, you may want to run:

    > `lsblk -f`

11. Mount the file systems
    1. Mount the _root partition_ to `/mnt`:

       > `mount /dev/root_partition /mnt`

    2. Mount the _EFI partition_ to `/mnt/boot`:

       > `mount --mkdir /dev/efi_partition /mnt/boot`

    To verify that you mounted correct partitions to correct mountpoints, run:

    > `lsblk`

12. The following command installs a minimal Arch system (base userland, Linux kernel, firmware) into /mnt and copies the pacman keyring so package signature verification works in the new install. It also installs the CPU microcode (for patching some low-level hardware bugs: for Intel it's `intel-ucode`; for AMD it's `amd-ucode`), `networkmanager` and `nano` (the text editor):

    > `pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager nano`

    To check whether it was executed successfully, do this:
    1. Check the exit status. 0 means the pacstrap itself completed without throwing:
       > `echo $?`
    2. Make sure there is now a system inside `/mnt`. It should print directories like `bin boot dev etc home var`, etc:
       > `ls /mnt`
    3. Try entering the new system with _chroot_. The following command should drop you into a shell with `/mnt` being actually `/` (to exit the shell, type `exit` or press `Crtl+d`):
       > `arch-chroot /mnt`
    4. Inside the _chroot jail_ you can use tools like `pacman` to verify whether the packages were installed. Every one of those should print the version:
       > `pacman -Q base linux linux-firmware networkmanager nano intel-ucode`
    5. Don't forget to exit the _chroot_ before proceeding with the guide.

13. The following command handles auto-mounts on boots. More precisely, it scans everything currently mounted under /mnt, generates the proper auto-mount lines for them using UUIDs, and appends those lines to `/mnt/etc/fstab` so they’ll be mounted automatically on future boots. Only run the following command once, or you'll duplicate entries in `/mnt/etc/fstab`:

    > `genfstab -U /mnt >> /mnt/etc/fstab`

    You can verify that it was executed properly by checking the contents of the file:

    > `nano /mnt/etc/fstab`

14. To directly interact with the new system's environment, tools, and configurations for the next steps as if you were booted into it, change root into the new system:

    > `arch-chroot /mnt`

15. Time
    1. Set the timezone:

       > `ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime`

       To verify that the timezone was set, check the `/etc/localtime` file. It should print the linking: `/etc/localtime -> /usr/share/zoneinfo/Europe/Moscow`:

       > `ls -l /etc/localtime`

    2. Set the hardware clock from system clock so the system references the correct time in the future:

       > `hwclock --systohc`

    3. Set the time synchronization using Network Time Protocol so the clock doesn't drift from reality:

       > `timedatectl set-ntp true`

16. Set up the US locale:
    1. open up `/etc/locale.gen` and uncomment `en_US.UTF-8 UTF-8`. Save and close the file.
    2. generate the locale by running:
       > `locale-gen`
    3. set the LANG variable accordingly:

       > `echo 'LANG=en_US.UTF-8' > /etc/locale.conf`

17. Set the hostname:

    > `echo YOUR_HOSTNAME > /etc/hostname`

18. Configure the **NetworkManager** to start automatically on boot:

    > `systemctl enable NetworkManager.service`

19. Set the password for the _root user_, by running the following command and entering your password (have it in mind that when typing in the password it won't be displayed at all, not even under the form of asterisks):

    > `passwd`

20. Configure the boot loader. We'll opt for **GRUB**
    1. Install the `grub` and `efibootmgr` packages:
       > `pacman -S grub efibootmgr`
    2. Put GRUB's files in the right place and register it with firmware

       > `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`

    3. Generate GRUB config file:

       > `grub-mkconfig -o /boot/grub/grub.cfg`

21. Exit the _chroot jail_ by typing `exit` or pressing `Crtl+d`. Then type `reboot` to reboot the machine. Remove the USB stick when it's restarting and not doing anything in the shell anymore.

## That should be it. Log in as `root`, enter the password you set before and proceed to further set up you environment. You're inside Arch Linux now, yay!

# Chapter 2. Post-installation process, documented

1.  If you want your USB to be back in a working state, you should reformat it. The procedure is pretty much the same. We'll format it back to exFAT - the most compatible and not crippled filesystem - great for all-purpose USBs. We'll be using **diskpart** again (in Windows, of course). So, be careful not to reformat the wrong device accidentally.
    1. Launch **diskpart** shell, by running:
       > `diskpart`
    2. Lists all the disks:
       > `list disk`
    3. Select **THE RIGHT ONE** judging by size (instead of `N` write the actual number of the disk):
       > `select disk N`
    4. Delete the existing partitions layout (without wiping all the data yet), run:

       > `clean`

    5. Create a single primary partition (you may have to resellect the USB stick disk after the previous step):

       > `create partition primary`

    6. Select the created partition by its index (it normally should be selected automatically, but just to be sure). First, list the partitions:

       > `list partition`

       Then select:

       > `select partition 1`

    7. Format the partition to exFAT file system (we'll do a quick format for our purposes) and assign a volume name that you'll see in Explorer (I'll make it be _"ALEXKLYUSB"_):

       > `format fs=exfat quick label=ALEXKLYUSB`

    8. Now our volume should be displayed in Explorer. If it didn't display there, run the following command to assign it a volume letter:

       > `assign`

    9. Run this to exit the interactive shell:

       > `exit`

2.  Connect to the internet. You can now use a tool provided by the **NetworkManager** called **nmtui**:
    1. Run:
       > `nmtui`
    2. Choose **"Activate a connection"**, pick your Wi-Fi, enter you password. Exit the tool.
    3. Check the connection by running:
       > `ping -c 3 archlinux.org`

    _P.S. for further network management use this tool_

3.  Right now all you're seeing is TTY. But it has an awfully small font. Let's set another one. Actually, the one we used during the Arch installation.
    1. You have to download the font package because it doesn't come preinstalled like it was on the _live system_:
       > `pacman -S terminus-font`
    2. Now you can set the font. Note that this will set the font only for the current session:
       > `setfont ter-132b`
    3. To make it set across sessions, we'll have to edit the TTY configuration file in `/etc/vconsole.conf`:

       > `nano /etc/vconsole.conf`

       Add the following line, then save and close the file:

       > `FONT=ter-132b`

4.  Let's add a user, because always being root is extremely unsafe. I'll add a new user, call him `alex`. I'll add him to the `wheel` group - a group of users that conventionally gets granted the access to `sudo` - a tool that lets a user run commands with root priviliges.
    1. First lets create the user and add him to the group. Also, it's worth setting the `login shell` that will be used for this user later, I'll stick with `bash`. `-m` flag creates a `/home/username` directory:

       > `useradd -m -G wheel -s /bin/bash alex`

    2. Then let's set the user's password:

       > `passwd alex`

    3. We can double-check that the user has been added by running:
       > `id alex`

5.  Once we added the user and added him to the `wheel` group, let's install `sudo` and grant `sudo` access to the `wheel` group:
    1. Install `sudo`:

       > `pacman -S sudo`

    2. Open up the _sudo config file_. We'll use `visudo` tool that wouldn't let us save the file if there were syntax errors - because that could lead to bad errors. `visudo` all by itself may use some cursed editor, so we explicitly tell it to use our familiar `nano` instead. We don't specify the path to the _sudo config file_ because `visudo` already knows it:

       > `EDITOR=nano visudo`

       And uncomment the following line:

       > `%wheel ALL=(ALL:ALL) ALL`

    3. To check that we granted the access successfully, run this:
       - switch to the user shell (to exit back to root, press `Ctrl+d`):

         > `su - alex`

       - quick check that the `sudo` works. This command doesn't do anything other than validates your `sudo` credentials and makes you authenticated for some time so that you won't have to enter your password each time if, say, you have to run several elevated commands in a row. The timer is 5 minutes on most systems. _(To kill the timer, you run `sudo -k`)_:

         > `sudo -v`

### Now we created a user. We won't be logging in as `root` anymore for now. So, run `reboot` and log in as the user. And keep logging in as the user in the future.

## The next step would be installing drivers. Reference `arch_linux_drivers.md`.

## The next step would be installing and configuring **Hyprland**. Reference `arch_linux_hyprland.md`

6.  Enable **TRIM** if you have SSD or NVMe. It's a technology that helps free space more efficiently (discard unused filesystem blocks once a week):

    > `sudo systemctl enable --now fstrim.timer`

    Check that it enabled successfully:

    > `systemctl status fstrim.timer`

    And run it now just to check that it'll actually _trim_:

    > `sudo fstrim -av`

7.  Set up a _firewall_. We'll configure **ufw**:

    > `sudo pacman -S ufw`

    If you previously messed with it, wipe the config clean:

    > `sudo ufw reset`

    Configure it so it denies incoming traffic but allows outgoing:

    > `sudo ufw default deny incoming`
    > `sudo ufw default allow outgoing`

    Allow SSH connections if needed:

    > `sudo ufw allow 22/tcp`

    Now, enable IPv6 in the config file located at `/etc/default/ufw` so the firewall protects IPv4 AND IPv6:

    > Change the line `IPV6=no` to `IPV6=yes`.

    Now, enable the service and enable the rules:

    > `systemctl enable --now ufw`
    > `sudo ufw enable`

    _And finally, if you'll ever want to open up a port later, do this:_

    > `sudo ufw allow 3000/tcp`

    _And to delete:_

    > `sudo ufw delete allow 3000/tcp`

    Finally, check the status:

    > `sudo ufw status verbose`

8.  Let's configure a RAM swap. Without it if you exceed your RAM capacity the kernel will start killing processes which could result in unsaved work and disrupted workflow. We'll use **zram**:

    > `sudo pacman -S zram-generator`

    Open up a config file at `/etc/systemd/zram-generator.conf` and add the following lines:

    ```
    [zram0]
    zram-size = ram / 2
    ```

    And apply:

    > `systemctl daemon-reload`
    > `systemctl start /dev/zram0`

    And check that it works:

    > `swapon --show`

9.  Let's add **udisks2** - a disk-managing daemon that **Thunar** can ask to mount your devices. Basically that means that whenever you plug in, say, a USB, it would mount automatically.

    > `sudo pacman -S udisks2`

    and check whether it's working:

    > `udisksctl status`

    But **Thunar** wouldn't be able to _directly_ talk to **udisks2**. It needs some kind of backend for that. Conveniently, that backend will also provide a _trash bin_ for us and some network browsing shit. That backend is **GVFS**. We'll also install `gvfs-mtp` for Android compatibility (if we'll ever decide to browse our Android phone through USB-C) and `thunar-volman` - a Thunar extension that actually does removable media management - without it USBs still won't automount.

    > `sudo pacman -S gvfs thunar-volman gvfs-mtp`

    Then turn on Thunar's volume manager:

    > Open Thunar, go to Edit -> Preferences -> Advanced and check "Enable Volume Management". Then click "Configure" and enable the behavior you want.

    And finally in _Hyprland config_ write this under _AUTOSTART_ to make automount work even when no Thunar is actually launched:

    > `exec-once = thunar --daemon`

10. Configure power management on laptop.
    Install **TLP** - a power management tool. The default configuration is good enough so we'll not tweak it.

    > `sudo pacman -S tlp`

    Enable **TLP** service

    > `sudo systemctl enable --now tlp.service`

    Also, install **Thermald** for better temp / cooling management.

    > `sudo pacman -S thermald`
    > `sudo systemctl enable --now thermald.service`

    And finally, make the laptop suspend on lid close:

    Edit the config file located at `/etc/systemd/logind.conf`

    Uncomment the following under `[Login]`:

    ```
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=suspend
    HandleLidSwitchDocked=ignore
    ```

    Reboot to apply the changes.

11. Install the tool that allows you to change the screen brightness. The default shortcuts are already pre-written in the Hyprland's config file. But the tools is missing:

    > `sudo pacman -S brightnessctl`

12. Let's configure Bluetooth.
    1. First, install the Bluetooth stack and CLI tools:

       > `sudo pacman -S bluez bluez-utils`

    2. Enable Bluetooth:

       > `sudo systemctl enable --now bluetooth.service`

    3. Then install the GUI for managing Bluetooth devices:

       > `sudo pacman -S blueman`

    And to run it, in the **App launcher** type "Bluetooth manager"

13. Disable mouse acceleration. Edit Hyprland's config file by editing this section:

    ```
    input{
       accel_profile = flat
    }
    ```

14. Install **Firefox** and **Google Chrome**:

    > `sudo pacman -S firefox`

    Choose `noto-fonts` if prompted to pick a provider for `ttf-font`.

    > `yay -S google-chrome`

15. Install a simple text editor. For example, **Featherpad**:

    > `sudo pacman -S featherpad`

16. Install VPN. I'll install **Happ**. It doesn't have a pacman package of course and the stuff on AUR seems sketchy. So we'll grab a `pkg.tar.zst` from the official Github repo:

    > `https://github.com/Happ-proxy/happ-desktop/releases`

    Install Happ:

    > `sudo pacman -U `path/to/the-archive.pkg.tar.zst`

    And uninstall if need be:

    > `pacman -Rns happ`

    The default configuration may break DNS resolving so in _Advanced settings_ and choose _TUN mode_ to be **gVisor**.
