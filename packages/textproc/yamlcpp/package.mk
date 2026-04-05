# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="yamlcpp"
PKG_VERSION="c7639e81d5f00a5b47a2c9bd668f10d74b949071" # 0.8.0
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/jbeder/yaml-cpp"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A C++ library for YAML."
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="+pic"

pre_configure_target() {
  # Entra na pasta onde o código foi baixado
  cd ${PKG_BUILD}

  # 🔥 A CORREÇÃO: Injeta o include que o GCC 15 exige no topo do arquivo problemático
  sed -i '1i #include <cstdint>' src/emitterutils.cpp
}
