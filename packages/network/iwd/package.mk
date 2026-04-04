# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="iwd"
PKG_VERSION="3.12"
PKG_SHA256="d89a5e45c7180170e19be828f9e944a768c593758094fc57a358d0e7c4cb1a49"
PKG_LICENSE="GPL"
PKG_SITE="https://git.kernel.org/cgit/network/wireless/iwd.git/about/"
PKG_URL="https://www.kernel.org/pub/linux/network/wireless/iwd-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="autotools:host gcc:host readline dbus"
PKG_LONGDESC="Wireless daemon for Linux"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-client \
                           --enable-monitor \
                           --enable-systemd-service \
                           --enable-dbus-policy \
                           --disable-manual-pages"

pre_configure_target() {
  # Entra na pasta do código fonte do iwd antes de injetar a vacina
  cd ${PKG_BUILD}

  # 🔥 O "Combo Elite" de Headers do Kernel Moderno (5.15)
  echo "info: Injetando headers de rede modernos no toolchain..."

  # 1. rtnetlink.h
  wget -qO ${SYSROOT_PREFIX}/usr/include/linux/rtnetlink.h https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/rtnetlink.h || \
  curl -sL https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/rtnetlink.h -o ${SYSROOT_PREFIX}/usr/include/linux/rtnetlink.h

  # 2. if_link.h
  wget -qO ${SYSROOT_PREFIX}/usr/include/linux/if_link.h https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/if_link.h || \
  curl -sL https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/if_link.h -o ${SYSROOT_PREFIX}/usr/include/linux/if_link.h

  # 3. if_addr.h
  wget -qO ${SYSROOT_PREFIX}/usr/include/linux/if_addr.h https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/if_addr.h || \
  curl -sL https://raw.githubusercontent.com/torvalds/linux/v5.15/include/uapi/linux/if_addr.h -o ${SYSROOT_PREFIX}/usr/include/linux/if_addr.h

  # 🔥 VACINA CIRÚRGICA: Resolver o conflito Glibc vs Kernel 3.14 (ifreq e in6_pktinfo)
  # Isso engana o Kernel renomeando as variáveis dele durante o include, evitando choque.
  sed -i '/#include <linux\/ipv6.h>/c\#define in6_pktinfo __kernel_in6_pktinfo\n#include <linux/ipv6.h>\n#undef in6_pktinfo' ell/icmp6.c
  sed -i '/#include <linux\/if_arp.h>/c\#define ifreq __kernel_ifreq\n#define ifconf __kernel_ifconf\n#include <linux/if_arp.h>\n#undef ifreq\n#undef ifconf' ell/netconfig.c

  # Forçar CFLAGS para ignorar erros. (Aviso de _GNU_SOURCE removido para limpar o log!)
  export CFLAGS="${CFLAGS} -Wno-discarded-qualifiers -Wno-unused-variable -Wno-unused-but-set-variable -Wno-error -fcommon"

  export LIBS="-lncurses"
}

post_makeinstall_target() {
  # ProtectSystem et al seems to break the service when systemd isn't built with seccomp.
  # investigate this more as it might be a systemd problem or kernel problem
  sed -e 's|^\(PrivateTmp=.*\)$|#\1|g' \
      -e 's|^\(NoNewPrivileges=.*\)$|#\1|g' \
      -e 's|^\(PrivateDevices=.*\)$|#\1|g' \
      -e 's|^\(ProtectHome=.*\)$|#\1|g' \
      -e 's|^\(ProtectSystem=.*\)$|#\1|g' \
      -e 's|^\(ReadWritePaths=.*\)$|#\1|g' \
      -e 's|^\(ProtectControlGroups=.*\)$|#\1|g' \
      -e 's|^\(ProtectKernelModules=.*\)$|#\1|g' \
      -e 's|^\(ConfigurationDirectory=.*\)$|#\1|g' \
      -i ${INSTALL}/usr/lib/systemd/system/iwd.service
}

post_install() {
  enable_service iwd.service
}
