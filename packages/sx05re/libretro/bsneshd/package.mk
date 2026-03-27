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

PKG_NAME="bsneshd"
PKG_VERSION="0bb7b8645e22ea2476cabd58f32e987b14686601"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/DerKoun/bsnes-hd"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="bsnes-hd is a fork of bsnes that adds HD video features such as widescreen, HD Mode 7 and true color"

PKG_TOOLCHAIN="make"

PKG_MAKE_OPTS_TARGET+=" -C bsnes target=libretro compiler=${TARGET_NAME}-g++"

pre_configure_target() {
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/bsnes/GNUmakefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp bsnes/out/bsnes_hd_beta_libretro.so ${INSTALL}/usr/lib/libretro/
}

