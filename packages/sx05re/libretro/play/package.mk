# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition - Play! (PS2) - Fix Full Headers & Arch

PKG_NAME="play"
PKG_VERSION="b3be9d4840ab947448aedf2228496510257726ac"
PKG_LICENSE="BSDv2"
PKG_SITE="https://github.com/jpd002/Play-"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libevdev zstd"
PKG_LONGDESC="Play! PlayStation 2 emulator libretro core."
PKG_TOOLCHAIN="cmake"

if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu"
fi

if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

# Ajuste de Arquitetura para ARM64
case ${ARCH} in
  aarch64)
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_GLEW=off \
                             -DUSE_GLES=on \
                             -DPLAY_ARCH=AARCH64 \
                             -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
                             -DTARGET_PLATFORM_UNIX_AARCH64=yes"
  ;;
esac

PKG_CMAKE_OPTS_TARGET+=" -DBUILD_LIBRETRO_CORE=yes \
                         -DBUILD_PLAY=off \
                         -DBUILD_TESTS=no \
                         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                         -DENABLE_AMAZON_S3=no \
                         -DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  # FIX GCC 15: Procura todos os headers (.h) nas dependências e injeta o cstdint
  # Isso resolve o erro de 'uintptr_t' em qualquer arquivo que aparecer
  find ${PKG_BUILD}/deps/CodeGen -name "*.h" -exec sed -i '1i #include <cstdint>' {} \;
  find ${PKG_BUILD}/deps/Framework -name "*.h" -exec sed -i '1i #include <cstdint>' {} \;
}

pre_make_target() {
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
     cp ${PKG_BUILD}/.${TARGET_NAME}/Source/ui_libretro/play_libretro.so ${INSTALL}/usr/lib/libretro/
}
