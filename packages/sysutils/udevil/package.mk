# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="udevil"
PKG_VERSION="666e443c36182751c81f3be3115d0ed9f8f2af58"
PKG_SHA256="55980a67c0fdc25e3dce7a2d70b9528b8ae3de5cb64a35696f22907175a7272f"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/arnie97/udevil-ng"
PKG_URL="https://github.com/arnie97/udevil-ng/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain systemd glib"
PKG_LONGDESC="Mounts and unmounts removable devices and networks without a password."

PKG_TOOLCHAIN="configure"

################################################################################
# CONFIGURAÇÃO (base EmuELEC mantida)
################################################################################

PKG_CONFIGURE_OPTS_TARGET="--disable-systemd \
                          --with-mount-prog=/usr/bin/mount \
                          --with-umount-prog=/usr/bin/umount \
                          --with-losetup-prog=/usr/sbin/losetup \
                          --with-setfacl-prog=/usr/bin/setfacl"

################################################################################
# INSTALL (robusto para fork novo)
################################################################################

makeinstall_target() {
  : # nada automático
}

post_makeinstall_target() {

  # config
  mkdir -p ${INSTALL}/etc/udevil
  cp ${PKG_DIR}/config/udevil.conf ${INSTALL}/etc/udevil
  ln -sf /storage/.config/udevil.conf ${INSTALL}/etc/udevil/udevil-user-root.conf

  # binário (compatível com ambos layouts)
  mkdir -p ${INSTALL}/usr/bin
  if [ -f udevil ]; then
    cp -PR udevil ${INSTALL}/usr/bin
  elif [ -f src/udevil ]; then
    cp -PR src/udevil ${INSTALL}/usr/bin
  fi

  # FIX CRÍTICO KERNEL 3.14 (mantido)
  mkdir -p ${INSTALL}/usr/sbin
  echo -e '#!/bin/sh\nexec /usr/bin/mount -t ntfs-3g "$@"' > ${INSTALL}/usr/sbin/mount.ntfs
  chmod 755 ${INSTALL}/usr/sbin/mount.ntfs
}

################################################################################
# SERVICE (mantido)
################################################################################

post_install() {
  enable_service udevil-mount@.service 2>/dev/null || true
}
