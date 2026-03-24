PKG_NAME="ecwolf"
PKG_VERSION="c57ad894d5942740b4896511e8554c9a776b04a6"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/ecwolf"
PKG_URL="${PKG_SITE}.git"

PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_mixer SDL2_net libjpeg-turbo bzip2"
PKG_SHORTDESC="ECWolf Libretro"
PKG_TOOLCHAIN="make"

# 🔥 só baixa o necessário
GIT_SUBMODULES="src/libretro/libretro-common"

PKG_MAKE_OPTS_TARGET="-C src/libretro"

pre_configure_target() {
  cd ${PKG_BUILD}

  # remove submodules problemáticos do controle do git
  sed -i '/deps\/SDL/d' .gitmodules
  sed -i '/deps\/SDL_mixer/d' .gitmodules
  sed -i '/deps\/SDL_net/d' .gitmodules

  # remove pastas
  rm -rf deps/SDL deps/SDL_mixer deps/SDL_net

  # garante libretro-common
  git submodule update --init src/libretro/libretro-common
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp src/libretro/ecwolf_libretro.so ${INSTALL}/usr/lib/libretro/
}