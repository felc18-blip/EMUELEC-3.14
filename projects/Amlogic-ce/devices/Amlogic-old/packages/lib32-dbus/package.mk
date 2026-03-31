# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-dbus"
PKG_VERSION="$(get_pkg_version dbus)"
PKG_NEED_UNPACK="$(get_pkg_directory dbus)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://dbus.freedesktop.org"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-expat lib32-systemd-libs"
PKG_PATCH_DIRS+=" $(get_pkg_directory dbus)/patches"
PKG_LONGDESC="D-Bus is a message bus, used for sending messages between applications."

# ✔ MUDANÇA ESSENCIAL: Meson em vez de Configure
PKG_TOOLCHAIN="meson"
PKG_BUILD_FLAGS="lib32"

# ✔ Tradução das flags antigas para o formato Meson (-Doption=enabled/disabled)
PKG_MESON_OPTS_TARGET="--libexecdir=/usr/lib/dbus \
                       -Dverbose_mode=false \
                       -Dapparmor=disabled \
                       -Dasserts=false \
                       -Dchecks=true \
                       -Dintrusive_tests=false \
                       -Dinstalled_tests=false \
                       -Dmodular_tests=disabled \
                       -Dxml_docs=disabled \
                       -Ddoxygen_docs=disabled \
                       -Dducktype_docs=disabled \
                       -Dx11_autolaunch=disabled \
                       -Dselinux=disabled \
                       -Dlibaudit=disabled \
                       -Dsystemd=enabled \
                       -Duser_session=false \
                       -Dinotify=enabled \
                       -Dvalgrind=disabled \
                       -Ddbus_user=dbus \
                       -Druntime_dir=/run \
                       -Dsystem_socket=/run/dbus/system_bus_socket"

unpack() {
  ${SCRIPTS}/get dbus
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/dbus/dbus-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

post_makeinstall_target() {
  # Limpeza de pastas que já existem na versão 64-bit
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/bin
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share

  # ✔ Garante que as libs de 32 bits fiquem na pasta lib32 correta
  if [ -d "${INSTALL}/usr/lib" ]; then
    mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
  fi
}