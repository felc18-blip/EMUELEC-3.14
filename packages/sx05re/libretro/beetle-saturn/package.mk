# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present Team EmuELEC (https://emuelec.org)

PKG_NAME="beetle-saturn"
PKG_VERSION="b4df47a9f0f30d09eb95b07a4435d0f435a2e95d"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-saturn-libretro"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="libretro"
PKG_SHORTDESC="Beetle Saturn libretro, a fork from mednafen"
PKG_TOOLCHAIN="make"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

makeinstall_target() {
  mkdir -p $INSTALL/usr/lib/libretro
  cp mednafen_saturn_*.so $INSTALL/usr/lib/libretro/
}
