<div align="center">

# ⚡ BiteClash

[**简体中文**](README_zh_CN.md) | [**English**](README.md)

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
  - 📶 **BiteClash for OpenWrt (Native .ipk Package)**: Pure and lightweight Linux procd daemon with transparent nftables redirection without unstable LuCI crashes.
  - 🌐 **Cyberpunk Web Console**: Embedded web management dashboard on port `9091` for instant browser access from any device.
- ⚡ **Clash Verge Rev Functional Parity**:
  - **Connection Tracker**: Real-time traffic, proxy chains, source/destination IP, rule matching, and connection closing.
  - **Live Log Terminal**: Real-time log streaming with multi-level filtering (Debug, Info, Warning, Error), pause, and search.
  - **Node Management**: Quick latency tests, keyword search, flexible sorting (by delay, name, or protocol), and group views.
  - **Auto-Start & Tray**: Automatic launch on boot, minimize-to-tray, and global shortcut toggles.
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

## 🛠️ Architecture

BiteClash separates user interaction from high-throughput network routing through a robust layered design:

```
┌────────────────────────────────────────────────────────┐
│             BiteClash Flutter UI Layer                 │
│      (Cyberpunk Dock, Reactive Dashboard, Charts)      │
└──────────────┬──────────────────────────┬──────────────┘
               │                          │
   [MethodChannel / IPC]      [Named Pipes / Unix Socket]
               │                          │
┌──────────────▼──────────────┐┌──────────▼──────────────┐
│       Platform Driver       ││       Mihomo Core       │
│  - Windows Service Helper   ││  - Clash.Meta Engine    │
│  - Android VpnService       ││  - Mixed/Fake-IP Stack  │
│  - iOS PacketTunnelProvider ││  - Rules & External Prov│
└─────────────────────────────┘└─────────────────────────┘
```

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

## 📄 License

This project is open source under the [GPL-3.0 License](LICENSE).
