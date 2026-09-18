# BiteClash

<p align="center">
  <img src="https://raw.githubusercontent.com/MetaCubeX/Clash.Meta/Alpha/docs/logo.png" width="90" alt="BiteClash Logo" />
</p>

<p align="center">
  <strong>⚡ Light as a bite, fast as light. ⚡</strong><br>
  现代化、极度轻巧、高颜值的全平台代理客户端，基于 <b>Flutter</b> 与 <b>Mihomo (Clash.Meta)</b> 内核打造。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.4-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13.3-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Core-Mihomo%20Meta%20v1.19.31-6366F1" alt="Mihomo" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20iOS%20%7C%20Web-10B981" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## ✨ 核心特性

- 🌌 **极客美学与玻璃拟态 (Glassmorphism)**
  - 深邃太空黑渐变背景，搭配半透明磨砂亚克力卡片与呼吸微光边框。
  - 拒绝单调平淡，告别传统代理工具的笨重感。
- 📈 **60fps 实时流体带宽波形图**
  - 自研高性能贝塞尔平滑曲线画布（`CustomPainter`），下行（青绿）与上行（紫蓝）双流速丝滑滚动。
- 🛡️ **强劲内核驱动 (Mihomo Meta Core)**
  - 内置最新稳定版 `Mihomo v1.19.31 with_gvisor`，协议生态丰富、分流规则兼容度极高。
- 🌐 **多端自适应响应式布局 (Adaptive Layout)**
  - **宽屏桌面端**：左侧悬浮玻璃侧边栏、大屏多列节点瀑布流。
  - **窄屏移动端**：自动切换为底部毛玻璃灵动 Dock 栏。
- 🚀 **智能节点与策略组管理**
  - 支持多策略组折叠面板（`Selector`、`URL-Test`、`Fallback` 等）。
  - **一键并发批量测速**：秒级返回延迟，动态变色状态徽章（极佳绿、良好黄、超时红）。
  - 乐观即时切换，点击无感点亮。
- 📥 **Clash YAML 订阅中心**
  - 支持直接粘贴机场订阅 URL，自动拉取、YAML 语法结构校验、节点数量统计。
  - 切换订阅一键通过 API **热重载**，无需重启内核。
- 🔌 **Windows 系统代理一键开关**
  - 底层操作 Windows 注册表，毫秒级接管与还原系统 HTTP 代理（`127.0.0.1:7890`）。
- 🤖 **GitHub Actions 云端全自动打包**
  - 本地无需安装庞大的编译环境（如 Visual Studio 或 Android Studio），推送到 GitHub 即可自动生成 Windows 和 Android 安装包。

---

## 🏛️ 系统架构设计

```mermaid
graph TD
    subgraph UI_Presentation [表现层 (Flutter & Riverpod)]
        Dashboard[仪表盘 / 流量波形]
        Proxies[节点列表 / 批量测速]
        Profiles[订阅管理 / 热重载]
        Settings[端口配置 / 内存遥测]
    end

    subgraph State_Layer [响应式状态管理]
        AppState[AppState (进程/系统代理/历史点)]
        ProxiesState[ProxiesState (节点与延迟)]
        ProfilesState[ProfilesState (配置持久化)]
    end

    subgraph Core_Bridge [核心通信与控制层]
        ProcessMgr[MihomoProcessService (守护与自检)]
        ApiClient[MihomoApiClient (REST & WebSocket)]
        ProxyMgr[WindowsProxyManager (注册表接管)]
    end

    subgraph Kernel [底层网络引擎]
        Mihomo[Mihomo Meta v1.19.31 Core]
    end

    UI_Presentation --> State_Layer
    State_Layer --> Core_Bridge
    Core_Bridge --> Kernel
```

---

## 📁 目录结构

```text
biteclash/
├── .github/workflows/
│   └── build.yml               # GitHub Actions 云端全自动编译与发布流水线
├── app/                        # Flutter 前端与状态管理代码
│   ├── lib/
│   │   ├── core/               # 内核管理、RESTful Client、WebSocket、系统代理
│   │   ├── models/             # 节点、策略组、实时流量数据模型
│   │   ├── state/              # Riverpod 状态提供者
│   │   ├── ui/                 # 现代化玻璃拟态 UI (主题、波形图、各主页面)
│   │   ├── main.dart           # 应用入口
│   │   └── test_runner.dart    # 自动化端到端测试脚本
│   └── pubspec.yaml            # 依赖配置
├── core/
│   ├── configs/                # 默认配置与订阅缓存目录
│   └── windows/
│       └── mihomo.exe          # Mihomo Meta 内核
└── README.md
```

---

## ⚡ 快速开始

### 方式一：直接下载使用（通过 GitHub Releases）

1. 前往本仓库的 **[Releases 页面](../../releases)**。
2. 下载最新产物：
   - **Windows**：下载 `BiteClash-windows-x64.zip`，解压后双击运行即可。
   - **Android**：下载 `BiteClash-android.apk`，安装到手机即可。

---

### 方式二：本地开发与调试

#### 前置要求
- [Flutter SDK](https://docs.flutter.dev/) (>= 3.24.0)
- [Git](https://git-scm.com/)
- [Go](https://go.dev/) (可选，仅在重新编译内核时需要)

#### 运行端到端底层自检
在不启动 UI 的情况下验证内核拉起、节点读取、测速与代理切换全链路：
```powershell
cd app
dart run lib/test_runner.dart
```

#### 本地启动调试
```powershell
# 进入应用目录
cd app

# 获取依赖
flutter pub get

# 在 Web (Chrome) 中秒级热重载预览完整 UI 交互
flutter run -d chrome

# 在 Windows 桌面端原生运行 (需已安装 VS 2022 C++ 工作负载)
flutter run -d windows
```

---

## ☁️ 利用 GitHub Actions 进行云端打包

本项目已完整配置了 CI/CD 工作流，当你将代码推送到自己的 GitHub 仓库后：

1. **一键手动触发**：
   - 进入 GitHub 仓库 ➔ 点击 **Actions** 标签 ➔ 选中 **Build & Release BiteClash Client** ➔ 点击 **Run workflow**。
2. **打 Tag 自动发布 Release**：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   GitHub 虚拟机将自动编译 Windows 绿色包与 Android APK，并自动生成发布页面挂载安装包！

---

## 📜 开源协议与免责声明

- 本项目基于 [MIT License](LICENSE) 开源。
- 本项目仅供网络技术学习、接口对接与软件工程研究交流，请勿用于违反当地法律法规之用途。
