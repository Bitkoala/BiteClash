# BiteClash Gateway (Docker 容器版 / 旁路由模式)

全场景超级网络枢纽（All-Scenario Super Network Hub）的 Docker 旁路由容器实现。
支持群晖（Synology）、unRAID、TrueNAS、PVE、物理机 Ubuntu/Debian 及树莓派，为局域网全屋设备（Apple TV、Switch、PS5、智能家居）提供无需安装客户端的无感透明代理分流。

---

## 核心特性

- **双接口控制**：
  - **RESTful API (`9090`)**：与 BiteClash 全平台原生客户端（iOS / Android / macOS / Windows / Linux）无缝协同，App 变身“超级遥控器”；
  - **赛博朋克 Web 控制台 (`9091`)**：任意终端（iPad、电视浏览器、手机）无需安装 App，开箱即可访问完整图形管理界面。
- **全自动 TProxy 透明代理**：
  - 基于 `nftables` + `fwmark` 路由策略；
  - 自动保留内网通信（Private Subnets），只对出海流量进行透明转发；
  - 容器停止或异常退出时，自动执行退出清理函数（Trap Clean），彻底杜绝局域网断网隐患。
- **开箱即用 DNS 劫持**：
  - 监听 `1053` Fake-IP 增强模式；
  - 局域网 DHCP 将网关和 DNS 指向本机 IP 即可瞬间完成全屋接管。

---

## 快速上手

### 1. 开启宿主机 IPv4 转发

在宿主机终端执行：
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. 使用 Docker Compose 一键启动

在当前目录运行：
```bash
docker compose up -d
```

### 3. 访问控制台与客户端连接

- **Web 控制台**：浏览器直接打开 `http://<宿主机IP>:9091`；
- **原生 App 遥控接管**：
  1. 打开手机/电脑上的 BiteClash 客户端；
  2. 进入【设置】->【网络与核心】->【核心运行模式】；
  3. 切换至【远程接管模式 (Remote Hub)】；
  4. 填写中枢 IP（如 `192.168.31.2`）与端口 `9090`，点击【测试并启用】。

### 4. 局域网全设备配置

在主路由器后台（或单个受控设备的网络设置中）：
- **默认网关 (Gateway)**：修改为 BiteClash 宿主机 IP（例如 `192.168.31.2`）；
- **首选 DNS 服务器 (DNS)**：修改为 BiteClash 宿主机 IP（例如 `192.168.31.2`）。

无需在 Apple TV、PlayStation 5 或 Switch 上做任何额外配置，即可享受极致低延迟全球加速。
