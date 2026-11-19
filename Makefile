UNIFI_SOURCE_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-unifi
PKG_VERSION:=$(shell python3 "$(UNIFI_SOURCE_DIR)tools/version.py")
PKG_RELEASE:=1

LUCI_TITLE:=Unifi theme with an OpenWrt-native dashboard
LUCI_DEPENDS:=+luci-base +luci-theme-bootstrap +luci-mod-status +ucode-mod-uloop +iputils-arping
LUCI_PKGARCH:=all
PKG_LICENSE:=Apache-2.0 CC0-1.0 OFL-1.1

define Package/luci-theme-unifi/conffiles
/etc/config/unifi
endef

define Package/luci-theme-unifi/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
[ ! -f /etc/uci-defaults/30_luci-theme-unifi ] || /etc/uci-defaults/30_luci-theme-unifi || exit 1
rm -f /tmp/luci-indexcache.*
rm -rf /tmp/luci-modulecache/
/etc/init.d/rpcd reload >/dev/null 2>&1 || true
/etc/init.d/unifi-activity enable
/etc/init.d/unifi-activity start
/etc/init.d/unifi-presence enable
/etc/init.d/unifi-presence start
exit 0
endef

define Package/luci-theme-unifi/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if [ "$$1" != "upgrade" ] && [ "$$(uci -q get luci.main.mediaurlbase)" = "/luci-static/unifi" ]; then
 uci -q set luci.main.mediaurlbase='/luci-static/bootstrap'
 uci -q commit luci
fi
/etc/init.d/unifi-activity stop >/dev/null 2>&1 || true
/etc/init.d/unifi-activity disable >/dev/null 2>&1 || true
/etc/init.d/unifi-presence stop >/dev/null 2>&1 || true
/etc/init.d/unifi-presence disable >/dev/null 2>&1 || true
exit 0
endef

define Package/luci-theme-unifi/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
[ "$$1" = "upgrade" ] && exit 0
uci -q delete luci.themes.Unifi
uci -q commit luci
rm -f /tmp/luci-indexcache.*
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
