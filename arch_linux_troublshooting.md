If VS Code doesn't use the font, try enforcing it in the config:
"editor.fontFamily": "JetBrainsMono Nerd Font, Symbols Nerd Font Mono, Symbols Nerd Font, Noto Color Emoji, monospace"


The desktop-entry approach looks like this: copy the app’s .desktop file into ~/.local/share/applications/, then edit its Exec= line to prefix env QT_QPA_PLATFORMTHEME=qt5ct …. That exact trick is a standard way people force a Qt app to use a specific platform theme.


`If in order to connect to Wi-Fi you need to be redirected to a login page in browser, first connect to Wi-Fi and then just go to this link and redirect should occur: `http://neverssl.com/`

If something returns `sudo: unable to resolve host <hostname>`, edit `/etc/hosts/`: add this line `127.0.1.1 yourhostname.localdomain yourhostname`

Maybe consider configuring `XDG user dirs` if home directory folders like Downloads, Documents, etc behave weidly.

If when installing a package with pacman you encounter an error like that: failed retrieving file 'filename' from mirror-name.com : The requested URL returned error: 404. It's worth updating pacman's package database: `sudo pacman -Syyu`

If you really have to install .rpm package in Arch linux:

````
   1.  Create a temporary "staging" directory and cd into it.

   > `mkdir -p ~/koala-clash-repack-rpm`
   > `cd ~/koala-clash-repack-rpm`

   2.  Download the `.rpm` package into this staging directory.

   3.  Install `rpm-tools` (`sudo pacman -S rpm-tools`) and run the following commands to check whether the package has pre/post install scriptlets:

   > `mkdir -p ~/tmp/rpmdb`
   > `rpm --dbpath ~/tmp/rpmdb --initdb`
   > `rpm --dbpath ~/tmp/rpmdb -qp --scripts Koala.Clash.x86_64.rpm`

   For **Koala Clash** it returns something like this:

   ```
   postinstall scritplet:
   #!/bin/bash

   chmod +x /usr/bin/install-service
   chmod +x /usr/bin/uninstall-service
   chmod +x /usr/bin/koala-clash-service

   preuninstall scriptlet:
   #!/bin/bash
   /usr/bin/uninstall-service
   ```

   We will need to recreate this behaviour in `.install` script.

   4.  Paste this into `koala-clash.install`:

   ```
   post_install() {
   chmod +x /usr/bin/install-service
   chmod +x /usr/bin/uninstall-service
   chmod +x /usr/bin/koala-clash-service
   }

   post_upgrade() {
   chmod +x /usr/bin/install-service \
            /usr/bin/uninstall-service \
            /usr/bin/koala-clash-service
   }

   pre_remove() {
   /usr/bin/uninstall-service || true
   }
   ```

   _P.s. we had to recreate postinstall scriplet using two functions here. Or else we'd lose the intended behavior. We've also added a bailout in case the uninstall script won't return successfully so that we would still be able to uninstall the software_

   5.  Paste this into `PKGBUILD`:

   ```
   pkgname=koala-clash
   pkgver=1.0
   pkgrel=1
   pkgdesc="Koala Clash (repacked from RPM for Arch)"
   arch=('x86_64')
   license=('custom')
   source=('Koala.Clash.x86_64.rpm')
   sha256sums=('SKIP')
   install=koala-clash.install

   package() {
   bsdtar -xf "$srcdir/Koala.Clash.x86_64.rpm" -C "$pkgdir"
   }
   ```

   6.  Build the package and install it:

   > `makepkg -si`

   7.  If the appilication doesn't start, do this troubleshooting:
````

If you really have to install .deb package in Arch linux:

```
1. Install the tool for repackaging is **Debtap**:

   > `yay -S debtap`

2. Initialize **Debtap**'s database:

   > `sudo debtap -u`

3. Convert the `.deb` package into an archive that is understood by pacman:

   > `debtap your-package.deb`

4. Install the resulting archive with pacman:

   > `sudo pacman -U ./*.pkg.tar.zst`
```

If you want a simple UI greeter, do this:

````
**greetd** is the login daemon, **tuigreet** is the actual UI you see

   > `sudo pacman -S greetd greetd-tuigreet`

   Now edit the config file located at `/etc/greetd/config.toml`. Add something like:

```

[terminal]

# TTY where the greeter runs

vt = 7

[default_session]

# tuigreet as greeter, starting Hyprland via the _wrapper_

command = "tuigreet --time --remember --asterisks --cmd start-hyprland"
user = "greeter"

```

And enable **greetd** on boot:

> `sudo systemctl enable --now greetd.service`
````

To run SDDM in test mode:

> `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/cherry-bloom/`
