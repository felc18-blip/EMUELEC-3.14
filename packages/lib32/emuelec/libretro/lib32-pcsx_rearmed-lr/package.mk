# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition - PCSX ReARMed (Lib32 Version - New Name)

PKG_NAME="lib32-pcsx_rearmed-lr"
PKG_VERSION="$(get_pkg_version pcsx_rearmed-lr)"
PKG_NEED_UNPACK="$(get_pkg_directory pcsx_rearmed-lr)"
PKG_ARCH="aarch64"
PKG_REV="1"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/pcsx_rearmed"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-alsa-lib"
PKG_PATCH_DIRS+=" $(get_pkg_directory pcsx_rearmed-lr)/patches"
PKG_SHORTDESC="ARM optimized PCSX fork (32-bit optimized for NextOS)"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="lib32 +speed -gold"

unpack() {
  ${SCRIPTS}/get pcsx_rearmed-lr
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/pcsx_rearmed-lr/pcsx_rearmed-lr-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

make_target() {
  cd ${PKG_BUILD}

  # Força o motor de alta performance (Dynarec) para 32 bits
  export ALLOW_LIGHTREC_ON_ARM=1

  # Correção para kernels antigos / HWCAP
  if [ -f deps/libchdr/deps/lzma-24.05/src/CpuArch.c ]; then
    sed -i 's/MY_HWCAP_CHECK_FUNC (CRC32)/\/\/MY_HWCAP_CHECK_FUNC (CRC32)/' deps/libchdr/deps/lzma-24.05/src/CpuArch.c
    sed -i 's/MY_HWCAP_CHECK_FUNC (SHA1)/\/\/MY_HWCAP_CHECK_FUNC (SHA1)/' deps/libchdr/deps/lzma-24.05/src/CpuArch.c
    sed -i 's/MY_HWCAP_CHECK_FUNC (SHA2)/\/\/MY_HWCAP_CHECK_FUNC (SHA2)/' deps/libchdr/deps/lzma-24.05/src/CpuArch.c
    sed -i 's/MY_HWCAP_CHECK_FUNC (AES)/\/\/MY_HWCAP_CHECK_FUNC (AES)/' deps/libchdr/deps/lzma-24.05/src/CpuArch.c
  fi

  # Performance Elite Edition
  sed -i 's/\-O[23]/-Ofast -ffast-math/' Makefile.libretro

  # Para compilar em 32 bits, o rpi3 é o alvo mais otimizado para a Mali-450
  if [ "${DEVICE}" = "Amlogic-old" ]; then
    make -f Makefile.libretro GIT_VERSION=${PKG_VERSION:0:7} platform=rpi3
  else
    make -f Makefile.libretro GIT_VERSION=${PKG_VERSION:0:7} platform=rpi4
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # NOME FINAL EXATO QUE VOCÊ PEDIU:
  cp pcsx_rearmed_libretro.so ${INSTALL}/usr/lib/libretro/pcsx_rearmed_new_32b_libretro.so
}
