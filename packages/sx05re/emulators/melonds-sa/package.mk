# SPDX-License-Identifier: GPL-2.0-or-later
#
# NextOS Elite Edition — melonDS standalone NDS / DSi emulator.
#
# Source: felc18-blip/melonDS-nextos (fork of melonDS-emu/melonDS at
# the JELOS pin ca7fb4f55e8fdad53993ba279b073f97f453c13c). NextOS
# tweaks live as proper commits in the fork's `nextos` branch:
#
#   * qt_sdl: drop Qt::Multimedia from find_package (unused; keeping it
#     would force qt-everywhere to build qtmultimedia + a media backend)
#   * main: force ScreenPanelNative + software 3D path always — the
#     Mali-450 + libmali blob can't run melonDS' GL frontend (#version
#     140 shaders) or its GPU3D OpenGL renderer (UBO / glMapBuffer)
#   * Platform: hard-code EmuELEC config paths under
#     /storage/.config/emuelec/configs/melonds/
#
# Performance expectation on Cortex-A53 @ 1.5 GHz: simple 2D titles
# (Picross, Phoenix Wright, Tetris DS) should be playable; demanding
# 3D titles (Pokemon BW, Mario Kart DS, NSMB) will be slow because
# the 3D rasterizer runs entirely on CPU.

PKG_NAME="melonds-sa"
PKG_VERSION="ff42de9a9f23af6cf8fdf5ffbd5ed97aa76562d7"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/melonDS-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
PKG_DEPENDS_TARGET="toolchain SDL2 qt-everywhere libslirp libarchive zstd libpcap"
PKG_LONGDESC="melonDS — Nintendo DS / DSi emulator (NextOS, Qt frontend, software 3D for Mali-450)"
PKG_TOOLCHAIN="cmake"
PKG_SECTION="emuelec/emulators"

# Amlogic-old (kernel 3.14, Cortex-A53). Same flag pack we use on
# duckstation / nanoboyadvance / touchhle: ARMv8 syscall wrappers,
# no stack protector, A53 tuning. -ftree-vectorize / -funroll-loops
# help the software 3D rasterizer hot loops (same trick dolphinSA
# uses for its software path).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  TARGET_CFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops -D__LINUX_ARM_ARCH__=8"
  TARGET_CXXFLAGS+=" -D_GNU_SOURCE -fno-stack-protector -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops -D__LINUX_ARM_ARCH__=8"
fi

PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                         -DCMAKE_INSTALL_PREFIX=/usr \
                         -DBUILD_SHARED_LIBS=OFF \
                         -DUSE_QT6=OFF \
                         -DENABLE_WAYLAND=OFF \
                         -DENABLE_JIT=ON \
                         -DENABLE_OGLRENDERER=ON \
                         -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/melonDS ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/*

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/melonds
  if [ -f ${PKG_DIR}/config/melonDS.ini ]; then
    cp -rf ${PKG_DIR}/config/melonDS.ini ${INSTALL}/usr/config/emuelec/configs/melonds/
  fi
}
