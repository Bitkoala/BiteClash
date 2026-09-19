<div align="center">

# ⚡ BiteClash

[**简体中文**](README.md) | [**English**](README_en.md)

[![Release](https://img.shields.io/github/v/release/Bitkoala/BiteClash?style=flat-square&color=00D2FF&logo=github)](https://github.com/Bitkoala/BiteClash/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/Bitkoala/BiteClash/build.yaml?style=flat-square&logo=githubactions)](https://github.com/Bitkoala/BiteClash/actions)
[![Downloads](https://img.shields.io/github/downloads/Bitkoala/BiteClash/total?style=flat-square&color=39FF14&logo=github)](https://github.com/Bitkoala/BiteClash/releases)
[![License](https://img.shields.io/github/license/Bitkoala/BiteClash?style=flat-square&color=white)](LICENSE)

**A next-generation, cyberpunk-styled multi-platform proxy client powered by Mihomo (Clash.Meta).**  
Fast, beautiful, feature-complete, completely open-source, and free of ads.

</div>

---

## 🌟 Highlights

- 🛸 **Cyberpunk Aesthetic Overhaul**: Tailored dark glassmorphic UI, glowing reactor core start button, floating mobile capsule navigation bar, and desktop floating sidebar.
- 🌐 **True All-Platform Coverage**:
  - **Windows**: Modern UI, native Windows system tray, background daemon, helper service for TUN mode.
  - **Android**: Material You & edge-to-edge support, per-app proxying, quick settings tile.
  - **iOS**: Full NetworkExtension integration (`NEPacketTunnelProvider`), shared App Group IPC, sideloadable `.ipa` and TrollStore `.tipa` releases.
  - **macOS**: Universal binaries (Apple Silicon arm64 & Intel x64), status bar icon.
  - **Linux**: AppImage, Deb, and RPM packages with systemd integration.
- ⚡ **All-Scenario Super Network Hub**:
  - 🎮 **Dual Core Mode**: Choose between "Local Core" (standalone client proxy) and "Remote Hub" (remote controller mode). Your phone and PC act as instant remote controls for whole-home OpenWrt routers and NAS setups.
  - 🐳 **BiteClash Gateway (Docker Container / Side-Router)**: Zero-client transparent proxy gateway tailored for Synology, unRAID, TrueNAS, PVE, and Raspberry Pi with automated `nftables` TProxy & Fake-IP DNS interception.
  - 📶 **BiteClash for OpenWrt (Native .ipk Package)**: Pure and lightweight Linux procd daemon with high-throughput nftables transparent redirection.
  - 🌐 **Cyberpunk Web Console**: Embedded web management dashboard on port `9091` for instant browser access from any device.
- 🛠️ **Professional Network Suite**:
  - **Live Connection Tracker**: Real-time inspection of active connections, outbound chains, IP resolution, and transfer speeds with one-click closing.
  - **Streaming Log Terminal**: Real-time log streaming with multi-level filtering (Debug, Info, Warning, Error), pause, and search.
  - **Smart Node Matrix**: Concurrent batch latency testing, keyword filtering, and multi-mode sorting (by delay, name, or protocol).
  - **Deep System Integration**: Native autostart on boot, system tray menu controls, and global hotkey shortcuts.
- 🔮 **Next-Gen Protocol Stack**: Full out-of-the-box support for Shadowsocks(R), VMess, VLESS, Trojan, Hysteria 2, WireGuard, and TUIC.
- ☁️ **Sync & Backup**: Remote WebDAV subscription and configuration backup & restore.
- 🛡️ **Zero Telemetry**: No trackers, no telemetry, no advertisements.

---

## 📦 Downloads & Deployment Matrix

Grab the latest pre-compiled binaries from [GitHub Releases](https://github.com/Bitkoala/BiteClash/releases/latest) or pull from Docker:

| Platform / Form Factor | Package Format / Image | Description & Target Devices |
| :--- | :--- | :--- |
| **Docker Gateway** | `docker compose` / Image | [BiteClash Gateway Guide](gateway/README.md) (Synology, unRAID, TrueNAS, PVE, Linux) |
| **OpenWrt Router** | `.ipk` Package | [BiteClash for OpenWrt Guide](openwrt/README.md) (Mini PC Routers, ImmortalWrt) |
| **Windows** | `.exe` / `.zip` | Setup installer and portable ZIP (x64 / arm64, with Remote Hub mode) |
| **Android** | `.apk` | Universal APK and ABI-split APKs (arm64-v8a, armeabi-v7a, x86_64) |
| **iOS** | `.ipa` / `.tipa` | Sideloadable IPA (AltStore, SideStore) & TrollStore TIPA |
| **macOS** | `.dmg` | Disk image for Apple Silicon & Intel Macs |
| **Linux** | `.AppImage` / `.deb` / `.rpm` | Portable AppImage and distro package installers |

---

## 🛠️ System Architecture

BiteClash features a modular design that completely decouples presentation from routing execution, enabling both standalone device proxying and whole-home gateway interception:

```
┌────────────────────────────────────────────────────────┐
│             BiteClash Native Client App                │
│   (iOS / Android / macOS / Windows / Linux)            │
│   ├── Standalone Client Mode (Local Core)              │
│   └── Super Remote Controller Mode (Remote Hub)        │
└──────────────────────────┬─────────────────────────────┘
                           │ Unified Dispatch (REST API / WebSocket: 9090)
┌──────────────────────────▼─────────────────────────────┐
│          BiteClash Network Hub Infrastructure          │
│   ├── Docker Gateway Container (Synology / unRAID/ PVE)│
│   ├── OpenWrt / ImmortalWrt Native Package (.ipk)      │
│   └── Cyberpunk Web Console (Direct Browser Access)    │
└──────────────────────────┬─────────────────────────────┘
                           │ Automated nftables TProxy + Fake-IP (1053)
┌──────────────────────────▼─────────────────────────────┐
│ Whole-Home Devices: Apple TV / Switch / PS5 / Smart Hub│
└────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start

### 1. Native Client Mode (Mobile & Desktop)
1. Download BiteClash for your OS from [Releases](https://github.com/Bitkoala/BiteClash/releases/latest);
2. Go to the **Config** tab and click **+** to import via subscription URL, local YAML file, or clipboard;
3. Return to the dashboard and press the glowing energy reactor to start proxying.

### 2. Docker Side-Router Gateway (NAS / Servers)
```bash
# Enable IPv4 forwarding on host
sudo sysctl -w net.ipv4.ip_forward=1

# Clone and run BiteClash Gateway
git clone https://github.com/Bitkoala/BiteClash.git
cd BiteClash/gateway
docker compose up -d
```
- Open `http://<HOST_IP>:9091` in any browser to open the Web Console;
- Or open BiteClash App on your phone/PC -> **Settings** -> **Network & Core** -> **Core Mode** and connect directly to the gateway IP.

### 3. OpenWrt Router Mode
```bash
# Install native .ipk package
opkg install biteclash_1.0.0-1_*.ipk

# Enable and start service
uci set biteclash.main.enabled=1 && uci commit biteclash
/etc/init.d/biteclash start
```
The router will instantly intercept DNS and outbound traffic with transparent TProxy acceleration.

---

## 🚀 Building from Source

### Prerequisites

- [Flutter SDK](https://flutter.dev/) (3.24+)
- [Go SDK](https://go.dev/) (1.21+)
- Git with submodule support

### Steps

1. **Clone the repository and submodules**:
   ```bash
   git clone --recursive https://github.com/Bitkoala/BiteClash.git
   cd BiteClash
   ```

2. **Fetch Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Build by platform**:

   - **Windows**:
     ```bash
     dart setup.dart windows
     ```
   - **Android**:
     ```bash
     dart setup.dart android
     ```
   - **iOS (Unsigned / Sideload)**:
     ```bash
     flutter build ios --release --no-codesign
     ```
   - **macOS**:
     ```bash
     dart setup.dart macos
     ```
   - **Linux**:
     ```bash
     dart setup.dart linux
     ```

---

## 🙏 Acknowledgments & Upstream Attribution

BiteClash is built upon the invaluable contributions of the open-source community:

- **[FlClash](https://github.com/chen08209/FlClash)** (Copyright © chen08209) - Foundational cross-platform client architecture and implementation.
- **[Mihomo (Clash.Meta)](https://github.com/MetaCubeX/mihomo)** (Copyright © MetaCubeX) - High-throughput core routing and proxy engine.
- **[Surfboard](https://getsurfboard.com/)** - UI and card interaction design inspiration.
- **[Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)** - Network diagnostics and connection tracking reference.

---

## 📄 License

This project is open source under the [GPL-3.0 License](LICENSE).

