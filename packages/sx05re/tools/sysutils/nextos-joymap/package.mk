# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS Elite Edition

PKG_NAME="nextos-joymap"
PKG_VERSION="0.1.0"
PKG_ARCH="any"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://github.com/felc18-blip/NextOS-Elite-Edition"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="evdev → uinput remapper for legacy USB gamepads (BTN_TRIGGER 288-299 → BTN_GAMEPAD 304+). Used by ports whose engines listen for modern gamepad codes only (e.g. GTA SA mobile loader)."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  ${CC} -O2 -o nextos-joymap ${PKG_DIR}/sources/nextos-joymap.c
  mkdir -p ${INSTALL}/usr/bin
  cp nextos-joymap ${INSTALL}/usr/bin/nextos-joymap
  chmod 0755 ${INSTALL}/usr/bin/nextos-joymap
}
