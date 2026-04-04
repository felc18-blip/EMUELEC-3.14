PKG_NAME="liblcf"
PKG_VERSION="0.8"
# Hash do commit oficial da tag v0.8
PKG_REV="606288281fe3527353c76065b56e1ebdc0c9baae"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/EasyRPG/liblcf"
# URL via commit: Impossível dar 404 se o repositório existe
PKG_URL="${PKG_SITE}/archive/${PKG_REV}.tar.gz"
PKG_DEPENDS_TARGET="toolchain expat icu"
PKG_LONGDESC="Library to handle RPG Maker 2000/2003 and EasyRPG projects"

PKG_USE_CMAKE="yes"
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  # VACINA GCC 15: Corrige o acesso a membros de templates no arquivo dbbitarray.h
  # Necessário para o compilador de 2026 não travar no swap do template
  if [ -f "${PKG_BUILD}/src/lcf/dbbitarray.h" ]; then
    sed -i 's/std::swap(_proxy._base, o._base);/std::swap(_proxy._base, o._proxy._base);/g' ${PKG_BUILD}/src/lcf/dbbitarray.h
    sed -i 's/std::swap(_proxy._idx, o._idx);/std::swap(_proxy._idx, o._proxy._idx);/g' ${PKG_BUILD}/src/lcf/dbbitarray.h
  fi

  # Relaxa o rigor do GCC 15 para códigos de templates antigos
  export CXXFLAGS="${CXXFLAGS} -fpermissive -Wno-template-body"
}

pre_make_target() {
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}
