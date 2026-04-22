# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Adapted for NextOS Elite Edition

PKG_NAME="pico-8"
PKG_VERSION="95cb4d4f28e1743c6a7f3c0266049f68b2134b60"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="PICO-8 Fantasy Console"
PKG_TOOLCHAIN="manual"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

makeinstall_target() {
  # Launcher script
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/start_pico8.sh ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/start_pico8.sh

  # Autostart (if present)
  if [ -d "${PKG_DIR}/sources/autostart/common" ]; then
    mkdir -p ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/sources/autostart/common/* ${INSTALL}/usr/lib/autostart/common
    chmod 0755 ${INSTALL}/usr/lib/autostart/common/*
  fi

  # Official PICO-8 binaries (Lexaloffle - proprietary, user-provided)
  # Will be copied to /storage/roms/pico-8/ at first boot via autostart
  if [ -d "${PKG_DIR}/sources/pico-8" ]; then
    echo "PICO-8: Official binaries found - will be installed at runtime"
    mkdir -p ${INSTALL}/usr/share/pico-8
    # Copy binaries based on target architecture
    if [ "${TARGET_ARCH}" = "aarch64" ]; then
      [ -f "${PKG_DIR}/sources/pico-8/pico8_64" ] && \
        cp ${PKG_DIR}/sources/pico-8/pico8_64 ${INSTALL}/usr/share/pico-8/
    else
      [ -f "${PKG_DIR}/sources/pico-8/pico8_dyn" ] && \
        cp ${PKG_DIR}/sources/pico-8/pico8_dyn ${INSTALL}/usr/share/pico-8/
      [ -f "${PKG_DIR}/sources/pico-8/pico8" ] && \
        cp ${PKG_DIR}/sources/pico-8/pico8 ${INSTALL}/usr/share/pico-8/
    fi
    # pico8.dat is architecture-independent
    [ -f "${PKG_DIR}/sources/pico-8/pico8.dat" ] && \
      cp ${PKG_DIR}/sources/pico-8/pico8.dat ${INSTALL}/usr/share/pico-8/
    chmod 0755 ${INSTALL}/usr/share/pico-8/pico8* 2>/dev/null || true
  else
    echo "PICO-8: No official binaries provided - only fake08 libretro will work"
  fi
}
