# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# NextOS Elite Edition - Otimizado para Kernel 3.14

PKG_NAME="udevil"
PKG_VERSION="0.4.4"
PKG_SHA256="ce8c51fd4d589cda7be56e75b42188deeb258c66fc911a9b3a70a3945c157739"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/IgnorantGuru/udevil"
PKG_URL="https://github.com/IgnorantGuru/udevil/raw/pkg/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain systemd glib"
PKG_LONGDESC="Montagem automatica robusta com suporte total a escrita para NextOS."

PKG_CONFIGURE_OPTS_TARGET="--disable-systemd \
                           --with-mount-prog=/usr/bin/mount \
                           --with-umount-prog=/usr/bin/umount \
                           --with-losetup-prog=/usr/sbin/losetup \
                           --with-setfacl-prog=/usr/bin/setfacl"

makeinstall_target() {
 : # nothing to install
}

post_makeinstall_target() {
  mkdir -p ${INSTALL}/etc/udevil
    cp ${PKG_DIR}/config/udevil.conf ${INSTALL}/etc/udevil
    ln -sf /storage/.config/udevil.conf ${INSTALL}/etc/udevil/udevil-user-root.conf

  mkdir -p ${INSTALL}/usr/bin
    cp -PR src/udevil ${INSTALL}/usr/bin

  # 🔥 AJUSTE DE PRODUÇÃO:
  # Alterado de 'ntfs3' (que não existe no 3.14) para 'ntfs-3g'.
  # Isso garante suporte total a escrita (saves, capas e deletar arquivos).
  mkdir -p ${INSTALL}/usr/sbin
  echo -e '#!/bin/sh\nexec /usr/bin/mount -t ntfs-3g "$@"' >${INSTALL}/usr/sbin/mount.ntfs
  chmod 755 ${INSTALL}/usr/sbin/mount.ntfs
}

post_install() {
  enable_service udevil-mount@.service
}