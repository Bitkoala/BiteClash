#!/bin/bash
set -e

CONFIG_DIR="/etc/biteclash"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
TEMPLATE_FILE="${CONFIG_DIR}/config.yaml.template"

echo "[BiteClash Gateway] Initializing All-Scenario Super Network Hub..."

# Ensure config directory and config file
mkdir -p "${CONFIG_DIR}"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "[BiteClash Gateway] No config.yaml found, creating from template..."
    if [ -f "${TEMPLATE_FILE}" ]; then
        cp "${TEMPLATE_FILE}" "${CONFIG_FILE}"
    else
        echo "[BiteClash Gateway] Warning: Template file not found!"
    fi
fi

# 1. Enable Linux IP forwarding
echo "[BiteClash Gateway] Checking IPv4 forwarding..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" != "1" ]; then
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || \
    sysctl -w net.ipv4.ip_forward=1 2>/dev/null || \
    echo "[BiteClash Gateway] Notice: Unable to set net.ipv4.ip_forward directly. Please ensure host has IP forwarding enabled."
fi

# 2. Setup Policy Routing for TProxy (Table 100, fwmark 1)
echo "[BiteClash Gateway] Setting up routing policy..."
ip rule del fwmark 1 table 100 2>/dev/null || true
ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null || true

ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100

# 3. Apply nftables rules
if [ -f /etc/nftables.conf ] && command -v nft >/dev/null 2>&1; then
    echo "[BiteClash Gateway] Applying nftables transparent proxy rules..."
    nft -f /etc/nftables.conf || echo "[BiteClash Gateway] Warning: nftables rule application returned non-zero code."
fi

# Cleanup handler on exit
cleanup() {
    echo "[BiteClash Gateway] Shutting down services and cleaning up routing..."
    if [ -n "$WEB_PID" ]; then
        kill "$WEB_PID" 2>/dev/null || true
    fi
    if [ -n "$CORE_PID" ]; then
        kill "$CORE_PID" 2>/dev/null || true
    fi
    # Remove nftables table
    nft delete table inet biteclash 2>/dev/null || true
    # Remove ip rules
    ip rule del fwmark 1 table 100 2>/dev/null || true
    ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null || true
    echo "[BiteClash Gateway] Cleanup complete. Goodbye."
    exit 0
}

trap cleanup SIGINT SIGTERM

# 4. Start Web Console on port 9091
if [ -d "/usr/share/biteclash/web" ]; then
    echo "[BiteClash Gateway] Launching BiteClash Web Console on port 9091..."
    python3 -m http.server 9091 --directory /usr/share/biteclash/web >/dev/null 2>&1 &
    WEB_PID=$!
fi

# 5. Start Core process
echo "[BiteClash Gateway] Launching BiteClash / Mihomo Core on port 9090..."
if [ -x "/usr/local/bin/mihomo" ]; then
    /usr/local/bin/mihomo -d "${CONFIG_DIR}" &
    CORE_PID=$!
elif [ -x "/usr/local/bin/biteclash-core" ]; then
    /usr/local/bin/biteclash-core -d "${CONFIG_DIR}" &
    CORE_PID=$!
else
    echo "[BiteClash Gateway] Error: No core binary found in /usr/local/bin/!"
    exit 1
fi

echo "[BiteClash Gateway] Super Network Hub running."
echo "  -> RESTful Controller: http://0.0.0.0:9090"
echo "  -> Web Console:        http://0.0.0.0:9091"
echo "  -> TProxy Port:        12345"

# Wait for core process
wait "$CORE_PID"
