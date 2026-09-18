# BiteClash for OpenWrt (原生 .ipk 插件)

全场景超级网络枢纽（All-Scenario Super Network Hub）的 OpenWrt / ImmortalWrt 原生路由器插件包。

---

## 架构优势

与传统繁重的 LuCI 插件不同，BiteClash 采用了轻量化且高可靠的现代架构：
1. **纯净原生 Procd 服务**：不侵入 OpenWrt 系统原有网络架构，守护进程崩溃自动拉起；
2. **nftables 透明代理**：支持硬件加速与原生 TProxy 转发，性能强悍，CPU 占用极低；
3. **极速赛博朋克 Web 控制台**：通过路由器 `http://192.168.1.1:9091` 随时打开现代化控制面板；
4. **原生 App 协同遥控**：手机/电脑端 BiteClash 开启【远程接管模式】，自动识别与托管软路由。

---

## 编译与安装

### 1. 添加至 OpenWrt 源码树

在 OpenWrt 源码目录或 SDK 根目录中执行：
```bash
# 复制或软链接 openwrt 目录到 package/biteclash
cp -r /path/to/BiteClash/openwrt package/biteclash

# 更新 feeds 并配置
make menuconfig
```
在 `menuconfig` 中勾选：
```text
Network  --->
    Web Servers/Proxies  --->
        <*> biteclash ..... BiteClash All-Scenario Super Network Hub
```

### 2. 单独编译 Package

```bash
make package/biteclash/compile V=s
```
编译产物位于 `bin/packages/<arch>/base/biteclash_1.0.0-1_<arch>.ipk`。

### 3. 在路由器上安装并启用

将 `.ipk` 上传至软路由后执行：
```bash
opkg install biteclash_1.0.0-1_*.ipk

# 启用服务并启动
uci set biteclash.main.enabled=1
uci commit biteclash
/etc/init.d/biteclash enable
/etc/init.d/biteclash start
```

### 4. 访问控制台

- **Web 控制台**：浏览器访问 `http://<路由器LAN_IP>:9091`；
- **RESTful API**：监听在 `http://<路由器LAN_IP>:9090`，可直接在手机/电脑 BiteClash App 的【远程接管模式】中接入。
