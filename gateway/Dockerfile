# BiteClash All-Scenario Super Network Hub Dockerfile
FROM alpine:3.20

ARG TARGETARCH

# Install essential runtime tools
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    iptables \
    nftables \
    iproute2 \
    tzdata \
    python3

# Install Mihomo Meta Core for specified architecture
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ARCH='linux-amd64-compatible' ;; \
        arm64) ARCH='linux-arm64' ;; \
        arm/v7) ARCH='linux-armv7' ;; \
        *) ARCH='linux-amd64-compatible' ;; \
    esac; \
    echo "Downloading Mihomo Core for architecture: ${ARCH}..."; \
    MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.18.9/mihomo-${ARCH}-v1.18.9.gz"; \
    curl -sSL "${MIHOMO_URL}" -o /tmp/mihomo.gz || \
    curl -sSL "https://ghproxy.com/${MIHOMO_URL}" -o /tmp/mihomo.gz || \
    curl -sSL "https://mirror.ghproxy.com/${MIHOMO_URL}" -o /tmp/mihomo.gz; \
    gzip -d /tmp/mihomo.gz; \
    mv /tmp/mihomo /usr/local/bin/mihomo; \
    chmod +x /usr/local/bin/mihomo; \
    /usr/local/bin/mihomo -v

# Copy rootfs files and configurations
COPY rootfs/ /
COPY web/ /usr/share/biteclash/web/

# Set script executable permissions
RUN chmod +x /usr/local/bin/entrypoint.sh

# Persist configuration directory
VOLUME ["/etc/biteclash"]

# Expose proxy, DNS, API and Web Console ports
EXPOSE 7890 12345/tcp 12345/udp 1053/udp 9090 9091

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
