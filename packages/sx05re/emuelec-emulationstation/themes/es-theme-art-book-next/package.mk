# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020 Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2020 351ELEC team (https://github.com/fewtarius/351ELEC)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
#
PKG_NAME="es-theme-art-book-next"
# NextOS fork: branch 'nextos' adiciona 33 artwork-noir + 30 logos ausentes
# do upstream (castlevania, crashbandicoot, freej2me, gbabr, mariohack,
# pokemon, sonic, streetfighter, zelda etc). Atualizar PKG_VERSION pra
# pegar novos commits do fork.
PKG_VERSION="c32333af2a44a4149e095b658294637068d9f720"
PKG_LICENSE="CUSTOM"
PKG_SITE="https://github.com/felc18-blip/art-book-next-es-nextos"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="Art Book Next (NextOS fork — extra system art)"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/emulationstation/themes/art-book-next
  cp -rf * ${INSTALL}/usr/config/emulationstation/themes/art-book-next
}

