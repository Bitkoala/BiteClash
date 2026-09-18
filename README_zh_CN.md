<div align="center">

# ⚡ BiteClash

[**简体中文**](README_zh_CN.md) | [**English**](README.md)

[![Release](https://img.shields.io/github/v/release/Bitkoala/BiteClash?style=flat-square&color=00D2FF&logo=github)](https://github.com/Bitkoala/BiteClash/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/Bitkoala/BiteClash/build.yaml?style=flat-square&logo=githubactions)](https://github.com/Bitkoala/BiteClash/actions)
[![Downloads](https://img.shields.io/github/downloads/Bitkoala/BiteClash/total?style=flat-square&color=39FF14&logo=github)](https://github.com/Bitkoala/BiteClash/releases)
[![License](https://img.shields.io/github/license/Bitkoala/BiteClash?style=flat-square&color=white)](LICENSE)

**基于 Mihomo (Clash.Meta) 内核的新一代赛博朋克风全平台代理客户端。**  
高颜值、极速响应、功能完备、纯净开源无广告。

</div>

---

## 🌟 核心特色

- 🛸 **全新赛博朋克 / 毛玻璃视觉设计**: 深度定制暗黑毛玻璃风格，能量反应堆启动核心，移动端悬浮胶囊导航舱，桌面端悬浮停靠栏。
- 🌐 **真正的全平台全覆盖**:
  - **Windows**: 现代化视窗交互、原生系统托盘常驻、后台静默守护、TUN 辅助服务驱动。
  - **Android**: Material You 色彩体系，沉浸式边到边布局，应用分流，快捷设置磁贴。
  - **iOS**: 完整 NetworkExtension 架构集成（`NEPacketTunnelProvider`），App Group IPC 共享，开箱即用的侧载 `.ipa` 与 TrollStore 巨魔商店 `.tipa`。
  - **macOS**: 通用二进制架构（同时支持 Apple Silicon M系列芯片与 Intel 处理器），状态栏快捷菜单。
  - **Linux**: 提供 AppImage、Deb 和 RPM 多种包格式，深度集成 systemd。
- ⚡ **全场景超级网络枢纽 (All-Scenario Super Network Hub)**:
  - 🎮 **双核心运行模式**: 支持“本地独立代理 (Local Core)”与“远程接管中枢 (Remote Hub)”，随身手机/电脑既是独立代理节点，也是全屋软路由与 NAS 的超级遥控器。
  - 🐳 **BiteClash Gateway (Docker 容器版 / 旁路由模式)**: 专为群晖 (Synology)、unRAID、TrueNAS、PVE、树莓派打造，全自动 `nftables` 透明网关 + Fake-IP DNS 劫持，Apple TV / Switch / PS5 零配置无感加速。
  - 📶 **BiteClash for OpenWrt (原生 .ipk 插件)**: 抛弃脆弱易崩溃的 LuCI 插件依赖，采用极简原生的 Linux procd 守护进程与高并发 TProxy 重定向。
  - 🌐 **赛博朋克 Web 控制台**: 统一的极速轻量网页仪表盘，内嵌于网关与软路由端口 `9091`，支持任意终端浏览器秒级监控与切换。
- ⚡ **深度对标 Clash Verge Rev 实用功能**:
  - **实时连接追踪**: 查看当前活跃流量、代理链跳板、源/目的 IP、命中规则，支持一键中断连接。
  - **实时日志终端**: 支持 Debug、Info、Warning、Error 多等级实时滚动过滤，暂停查看与关键词检索。
  - **智能节点管理**: 批量延迟测速、搜索过滤、多种排序模式（延迟排序、名称排序、协议排序）。
  - **系统级集成**: 开机自动启动、最小化到托盘、全局快捷键一键启停。
- ☁️ **云端备份同步**: 支持通过 WebDAV 协议远程备份与恢复订阅节点及个性化配置。
- 🛡️ **纯粹安全隐私**: 零数据收集、零追踪统计、无任何商业广告代码。

---

## 📦 版本下载与部署矩阵

请在 [GitHub Releases 页面](https://github.com/Bitkoala/BiteClash/releases/latest) 下载或通过 Docker 拉取：

| 平台 / 形态 | 安装格式 / 镜像 | 说明与适用设备 |
| :--- | :--- | :--- |
| **Docker 网关** | `docker compose` / 镜像 | [BiteClash Gateway 说明文档](gateway/README.md)（群晖、unRAID、TrueNAS、PVE、Linux） |
| **OpenWrt 软路由** | `.ipk` 原生插件包 | [BiteClash for OpenWrt 说明文档](openwrt/README.md)（工控机软路由、ImmortalWrt 固件） |
| **Windows** | `.exe` / `.zip` | 安装向导版与绿色便携版（支持 x64 / arm64，带一键遥控模式） |
| **Android** | `.apk` | 全架构通用版及单架构精简版（arm64-v8a、armeabi-v7a、x86_64） |
| **iOS** | `.ipa` / `.tipa` | 免证书侧载包（AltStore、SideStore）与巨魔免签包（TrollStore） |
| **macOS** | `.dmg` | 苹果电脑安装磁盘映像（通用二进制） |
| **Linux** | `.AppImage` / `.deb` / `.rpm` | 免安装便携版及各主流发行版安装包 |

---

## 🛠️ 系统架构

BiteClash 采用模块化解耦设计，前端高颜值响应式 UI 与后端高性能网络内核通过安全 IPC 通信：

```
┌────────────────────────────────────────────────────────┐
│             BiteClash Flutter UI 交互层                │
│    (赛博朋克控制台、悬浮交互舱、实时速率监视仪表盘)    │
└──────────────┬──────────────────────────┬──────────────┘
               │                          │
      [MethodChannel / IPC]        [命名管道 / Unix 套接字]
               │                          │
┌──────────────▼──────────────┐┌──────────▼──────────────┐
│        平台底层驱动         ││        Mihomo 核心      │
│  - Windows Helper 辅助服务  ││  - Clash.Meta 转发引擎  │
│  - Android VpnService 驱动  ││  - Mixed/Fake-IP 协议栈 │
│  - iOS PacketTunnelProvider ││  - 规则分流 / 外部提供商│
└─────────────────────────────┘└─────────────────────────┘
```

---

## 🚀 源码构建指南

### 环境准备

- [Flutter SDK](https://flutter.dev/) (3.24+)
- [Go SDK](https://go.dev/) (1.21+)
- Git 及子模块支持

### 构建步骤

1. **克隆代码库并初始化子模块**:
   ```bash
   git clone --recursive https://github.com/Bitkoala/BiteClash.git
   cd BiteClash
   ```

2. **拉取依赖包**:
   ```bash
   flutter pub get
   ```

3. **各平台打包命令**:

   - **Windows**:
     ```bash
     dart setup.dart windows
     ```
   - **Android**:
     ```bash
     dart setup.dart android
     ```
   - **iOS (免签名侧载包)**:
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

## 📄 开源许可

本项目遵循 [GPL-3.0 开源许可协议](LICENSE)。
