# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition - PCSX ReARMed (Fixed Naming & Platform)

PKG_NAME="pcsx_rearmed-lr"
PKG_VERSION="c1e885c71f24204a919e3bc40735497ccf541f0d"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/pcsx_rearmed"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ARM optimized PCSX fork - NextOS Elite Edition"
PKG_TOOLCHAIN="manual"

pre_configure_target() {
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile
  export CFLAGS="${CFLAGS} -flto -fipa-pta"
  export CXXFLAGS="${CXXFLAGS} -flto -fipa-pta"
  export LDFLAGS="${LDFLAGS} -flto -fipa-pta"
}

make_target() {
  cd ${PKG_BUILD}
  # FIX DA PLATAFORMA: Trocamos ${DEVICE} por unix para ele parar de achar que é Windows
  make -f Makefile.libretro GIT_VERSION=${PKG_VERSION:0:7} platform=unix
}

makeinstall_target32() {
  # Esta função busca o binário compilado na etapa de 32 bits (arm)
  if [ "${ENABLE_32BIT}" == "true" ]; then
    cp -vP ${ROOT}/build.${DISTRO}-${DEVICE}.arm/install_pkg/${PKG_NAME}-*/usr/lib/libretro/pcsx_rearmed_new_32b_libretro.so ${INSTALL}/usr/lib/libretro/
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro

  if [ "${ARCH}" == "arm" ]; then
    # Build de 32 bits gera este nome:
    cp pcsx_rearmed_libretro.so ${INSTALL}/usr/lib/libretro/pcsx_rearmed_new_32b_libretro.so
  else
    # Build de 64 bits gera este nome:
    cp pcsx_rearmed_libretro.so ${INSTALL}/usr/lib/libretro/pcsx_rearmed_new_libretro.so

    case ${TARGET_ARCH} in
      aarch64)
        # Traz o 32b para a pasta final de 64 bits
        makeinstall_target32
      ;;
    esac
  fi
}
