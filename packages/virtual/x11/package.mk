# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue

PKG_NAME="x11"
PKG_VERSION=""
PKG_LICENSE="OSS"
PKG_SITE="http://www.X.org"
PKG_URL=""
PKG_SECTION="virtual"
PKG_LONGDESC="X11 is the Windowing system"

PKG_DEPENDS_TARGET="toolchain xorg-server"

# Fonts
PKG_DEPENDS_TARGET+=" encodings font-xfree86-type1 font-bitstream-type1 font-misc-misc"

# Server
PKG_DEPENDS_TARGET+=" xkeyboard-config xkbcomp"

# Tools
PKG_DEPENDS_TARGET+=" xrandr setxkbmap"

# Window manager (seguro contra vazio/none)
if [ -n "${WINDOWMANAGER}" ] && [ "${WINDOWMANAGER}" != "no" ] && [ "${WINDOWMANAGER}" != "none" ]; then
  PKG_DEPENDS_TARGET+=" ${WINDOWMANAGER}"
fi

# Detecta drivers automaticamente
get_graphicdrivers

# Input drivers
if [ -n "${LIBINPUT}" ] && [ "${LIBINPUT}" != "none" ]; then
  PKG_DEPENDS_TARGET+=" xf86-input-libinput"
else
  PKG_DEPENDS_TARGET+=" xf86-input-evdev xf86-input-synaptics"
fi

# Video drivers (seguro)
if [ -n "${XORG_DRIVERS}" ]; then
  for drv in ${XORG_DRIVERS}; do
    [ -z "${drv}" ] && continue
    [ "${drv}" = "none" ] && continue

    if [ -d "${PKG_DIR}/../driver/xf86-video-${drv}" ]; then
      PKG_DEPENDS_TARGET+=" xf86-video-${drv}"
    fi
  done
fi

# Limpeza final (remove "none" e espaços duplicados)
PKG_DEPENDS_TARGET="$(echo ${PKG_DEPENDS_TARGET} | tr -s ' ' | sed 's/\bnone\b//g')"
