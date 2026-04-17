################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="a5200"
PKG_VERSION="c4f9dbcb19b3592849f589cee34cce3cb20abb1e"
PKG_SHA256="8d3648e173acdaed9a05367c1e10f0246bff31116b17dca4ab49e65067f80b41"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/a5200"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Port of Atari 5200 emulator for GCW0 "
PKG_TOOLCHAIN="auto"

PKG_MAKE_OPTS_TARGET="platform=rpi4"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp a5200_libretro.so ${INSTALL}/usr/lib/libretro/
}
