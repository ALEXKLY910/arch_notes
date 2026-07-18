# Arch Laptop Through Android Happ Hotspot Proxy

This guide documents the setup we built: an Arch laptop connected to an Android phone hotspot, with Chrome traffic routed through the phone's Happ VPN/proxy client instead of bypassing it.

## Goal

The original problem was:

- Android phone provides hotspot.
- Happ is active on the phone.
- Arch laptop connects to the phone hotspot.
- Laptop traffic was bypassing the phone's VPN/proxy path.
- Running the VPN directly on Arch was not an option.

The working solution is not true system-wide Android VPN tethering. It is a SOCKS5 proxy setup:

```text
Arch laptop app
→ Android hotspot
→ Happ SOCKS5 proxy on phone
→ Happ tunnel
→ internet
```

This works for applications configured to use the proxy. In this guide, we configured Google Chrome to use it.

## Phone-side Happ settings

In Happ on Android, we found the relevant setting:

```text
Settings → Allow connections from the LAN
```

This must be enabled.

In Happ's inbound settings, Happ exposed:

```text
SOCKS5 port: 10808
```

We did not need the HTTP proxy for this setup.

## Finding the phone hotspot IP from Arch

While the Arch laptop was connected to the phone hotspot, we ran:

```bash
ip route
```

The output contained:

```text
default via 172.18.91.130 dev wlp3s0 proto dhcp src 172.18.91.66 metric 20600
172.18.91.0/24 dev wlp3s0 proto kernel scope link src 172.18.91.66 metric 600
```

From that:

```text
Phone hotspot gateway IP: 172.18.91.130
Laptop IP:              172.18.91.66
Happ SOCKS5 proxy:      172.18.91.130:10808
```

The phone IP may change in the future, so the final script detects it automatically from the default route.

## Testing the proxy from Arch

We tested whether Arch could reach the internet through Happ's SOCKS5 proxy:

```bash
curl --proxy socks5h://172.18.91.130:10808 https://api.ipify.org
```

The command returned a public VPN/proxy exit IP, meaning the proxy worked.

Then we tested direct traffic:

```bash
curl https://api.ipify.org
```

That failed, which matched the network environment: direct traffic was blocked, while proxied traffic worked.

Important detail:

```text
socks5h://
```

was used instead of:

```text
socks5://
```

The `h` means hostname/DNS resolution is handled through the SOCKS proxy. This reduces DNS leakage for tools that support `socks5h`.

## Testing Chrome manually

We launched Chrome through the phone's Happ SOCKS5 proxy:

```bash
google-chrome-stable --proxy-server="socks5://172.18.91.130:10808"
```

A blocked site loaded successfully.

That proved Chrome could use the phone's Happ tunnel through the hotspot.

## Creating the `chrome-happ` launcher script

We created a reusable command:

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/chrome-happ
```

Final script can be found at `arch_linux_configs/chrome-happ`

Then we made it executable:

```bash
chmod +x ~/.local/bin/chrome-happ
```

Now Chrome can be launched through Happ with:

```bash
chrome-happ
```

## Why the script checks whether Chrome is already running

Chrome command-line proxy flags are process-level startup flags.

If Chrome is already running, launching:

```bash
google-chrome-stable --proxy-server="socks5://..."
```

may simply open a new window in the already-running Chrome process. In that case, the new proxy flag can be ignored.

That is why the script refuses to launch if Chrome is already running:

Before launching Chrome via Happ, close all normal Chrome windows first.

## Creating the desktop launcher

We created a desktop entry:

```bash
mkdir -p ~/.local/share/applications
nano ~/.local/share/applications/chrome-happ.desktop
```

Contents:

```ini
[Desktop Entry]
Type=Application
Name=Chrome via Happ
Comment=Launch Google Chrome through the phone Happ SOCKS5 proxy
Exec=/home/alex/.local/bin/chrome-happ
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
```

Then:

```bash
chmod +x ~/.local/share/applications/chrome-happ.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

After that, the launcher appeared in the app menu as:

```text
Chrome via Happ
```

## Current working usage

1. On the Android phone:
   - Turn on hotspot.
   - Start Happ.
   - Connect Happ to the needed configuration.
   - Make sure `Allow connections from the LAN` is enabled.

2. On the Arch laptop:
   - Connect to the phone hotspot.
   - Close all normal Chrome windows.
   - Launch `Chrome via Happ` from the app menu, or run:

```bash
chrome-happ
```

# Running terminal commands through the Happ proxy

The Happ SOCKS5 proxy can also be used by terminal programs on Arch.

The phone’s hotspot gateway address can be detected automatically with:

Create a reusable proxy wrapper

Create the script:

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/happ-proxy
```

Final script can be found at `arch_linux_configs/happ-proxy`

Save the file and make it executable:

```bash
chmod +x ~/.local/bin/happ-proxy
```

## Run commands through Happ

Place happ-proxy before the command:

```bash
happ-proxy curl https://api.ipify.org
```

The returned address should be the Happ exit IP rather than the direct mobile connection.

Other examples:

```bash
happ-proxy git clone https://github.com/example/project.git
happ-proxy npm ping
happ-proxy npx live-server --host=0.0.0.0 --port=5500
```

## Why several proxy variables are needed

Different terminal programs inspect different environment variables.

ALL_PROXY is commonly supported by programs such as curl.

HTTP_PROXY and HTTPS_PROXY are needed by programs such as npm and npx.

Both uppercase and lowercase variants are set because applications are inconsistent about which form they recognize.

The proxy address uses socks5h rather than socks5:

socks5h://PHONE_IP:10808

The h means hostname and DNS resolution are handled through the proxy. This reduces the chance of DNS requests bypassing Happ.

Local connections are excluded

The wrapper sets:

NO_PROXY=localhost,127.0.0.1,::1

This prevents local services such as live-server from trying to access themselves through the phone proxy.

## Limitations

The wrapper only works with applications that support proxy environment variables. It does not transparently redirect every network connection made by the system.

Programs such as ping do not work through a SOCKS5 proxy because they use ICMP rather than HTTP or SOCKS-compatible TCP connections.

Some applications may require their own proxy configuration even when the environment variables are set.
