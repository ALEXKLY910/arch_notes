`If in order to connect to Wi-Fi you need to be redirected to a login page in browser, first connect to Wi-Fi and then just go to this link and redirect should occur: `http://neverssl.com/`

If something returns `sudo: unable to resolve host <hostname>`, edit `/etc/hosts/`: add this line `127.0.1.1 yourhostname.localdomain yourhostname`

Maybe consider configuring `XDG user dirs` if home directory folders like Downloads, Documents, etc behave weidly.

If when installing a package with pacman you encounter an error like that: failed retrieving file 'filename' from mirror-name.com : The requested URL returned error: 404. It's worth updating pacman's package database: `sudo pacman -Syyu`

If you really have to install .rpm package in Arch linux:

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
1.  First, try to start it from the Terminal and not from the App Launcher. You'll need to locate its `.desktop` file.

    Run this command:

    > `grep -Ril "koala" /usr/share/applications ~/.local/share/applications 2>/dev/null`

    What it does is it searches for the entry "koala" recursively (`-R`), case-insensetive (`-i`) in the common directories where the `.desktop` files are usually stored. It prints out only the file paths (`-l`) of those files where there was a match. And it redirects error stream (`stderr`, file descriptor `2`) into the void.

    Identify the `.desktop` file. Print its contents with `cat`. Then find `Exec` entry. And it is the actuall command to run the application. Copy it without the parameter placeholders (starting with `%`).

    In the current case that command would be `koala-clash`. Yes, conveniently the same as the package name.

    Finally, start the application from the Terminal with this command. It should throw an error. If says that an error was encountered while loading shared libraries and then prints the missing files, we'll have to install the libraries containing those files ourselves.

1.  Identify the library package name from the missing file. Using pacman search:

    > `pacman -F missing-file-name`

    If you haven't done that before you may have to download the database for search first:

    > `sudo pacman -Fy`

    and install the package with usual `sudo pacman -S package-name`

1.  If later you'll want to uninstall it, run:

> `sudo pacman -Rns koala-clash`

If you really have to install .deb package in Arch linux:

1. Install the tool for repackaging is **Debtap**:

   > `yay -S debtap`

2. Initialize **Debtap**'s database:

   > `sudo debtap -u`

3. Convert the `.deb` package into an archive that is understood by pacman:

   > `debtap your-package.deb`

4. Install the resulting archive with pacman:

   > `sudo pacman -U ./*.pkg.tar.zst`
