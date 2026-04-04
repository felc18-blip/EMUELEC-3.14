# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 Felipe Elite Edition

PKG_NAME="gme"
PKG_VERSION="1.0-dummy"
PKG_LICENSE="GPL"
PKG_SITE="local"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="GME Dummy Package - Skipped to save sanity"
PKG_LONGDESC="Este pacote nao compila nada. Serve apenas para satisfazer dependencias de outros pacotes."

# 👻 Mágica: ferramenta 'manual' não tenta rodar make/cmake
PKG_TOOLCHAIN="manual"

# Funções vazias que apenas retornam 'sucesso'
build_target() {
  true
}

make_target() {
  true
}

makeinstall_target() {
  # Criamos apenas a pasta para o sistema nao reclamar,
  # mas sem copiar nenhum arquivo .so real.
  mkdir -p ${INSTALL}/usr/lib/libretro
  touch ${INSTALL}/usr/lib/libretro/gme_libretro.so.dummy
}
