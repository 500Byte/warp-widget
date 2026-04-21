# 🛡️ WARP Center (KDE Plasma 6 Widget)

An advanced and lightweight Cloudflare WARP controller for **KDE Plasma 6**. Manage your VPN connection, systemd service, and autostart configuration directly from your desktop or panel.

![KDE Plasma 6](https://img.shields.io/badge/KDE-Plasma_6-blue?logo=kde&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

- **VPN Toggle**: Connect or disconnect from the Cloudflare network with one click.
- **Service Management**: Start or stop the `warp-svc` systemd daemon (uses `pkexec` for security).
- **Autostart Control**: Toggle the service `enable/disable` state for the next system boot.
- **Real-time Status**: Monitors the health of both the VPN connection and the system service.
- **Activity Log**: Built-in console to see exactly what's happening behind the scenes.
- **Plasma 6 Native**: Built using modern Kirigami and Plasma 6 components.

## 🚀 Installation

### 1. Requirements
Make sure you have `cloudflare-warp-bin` (AUR) and `plasma5support` installed:
```bash
# Arch / CachyOS
paru -S cloudflare-warp-bin
sudo pacman -S plasma5support
```

### 2. Manual Installation
Clone this repository and install it using `kpackagetool6`:
```bash
git clone https://github.com/500Byte/warp-widget.git
cd warp-widget
kpackagetool6 -t Plasma/Applet --install .
```

## 🛠️ Development
To update the widget after making changes:
```bash
kpackagetool6 -t Plasma/Applet --upgrade .
```

To test without adding to the taskbar:
```bash
plasmawindowed com.500byte.warp-widget
```

## 👤 Author
Developed with ❤️ by **500Byte**.

---
*Disclaimer: This is an unofficial widget and is not affiliated with Cloudflare.*
