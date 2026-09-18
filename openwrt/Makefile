include $(TOPDIR)/rules.mk

PKG_NAME:=biteclash
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Bitkoala Team <contact@bitkoala.io>
PKG_LICENSE:=GPL-3.0-only

include $(INCLUDE_DIR)/package.mk

define Package/biteclash
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=BiteClash All-Scenario Super Network Hub
  URL:=https://github.com/Bitkoala/BiteClash
  DEPENDS:=+kmod-nft-tproxy +kmod-tun +ca-bundle +nftables +curl
endef

define Package/biteclash/description
  BiteClash All-Scenario Super Network Hub client daemon and transparent gateway for OpenWrt.
  Features automated TProxy redirection, Fake-IP DNS integration, and an embedded Cyberpunk Web Console.
endef

define Package/biteclash/conffiles
/etc/config/biteclash
/etc/biteclash/config.yaml
endef

define Build/Compile
endef

define Package/biteclash/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/biteclash $(1)/etc/init.d/biteclash

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/biteclash $(1)/etc/config/biteclash

	$(INSTALL_DIR) $(1)/etc/biteclash
	$(INSTALL_DATA) ../gateway/rootfs/etc/biteclash/config.yaml.template $(1)/etc/biteclash/config.yaml.template

	$(INSTALL_DIR) $(1)/usr/share/biteclash/web
	$(INSTALL_DATA) ../gateway/web/index.html $(1)/usr/share/biteclash/web/index.html
endef

$(eval $(call BuildPackage,biteclash))
