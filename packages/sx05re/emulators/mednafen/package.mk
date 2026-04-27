# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# NextOS-Elite-Edition: adapted for Amlogic-old (S905X/W, Cortex-A53, Mali-450)

PKG_NAME="mednafen"
PKG_VERSION="1.32.1"
PKG_LICENSE="mixed"
PKG_SITE="https://mednafen.github.io/"
# Fork with CHD additions
PKG_URL="https://github.com/sydarn/mednafen/archive/refs/tags/1.32.1-chd.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 flac zstd zlib gptokeyb"
PKG_TOOLCHAIN="configure"

case ${DEVICE} in
  H700|SM8*|Amlogic-old)
    # SDL2 input only (avoids Linux joystick API path) — same need as low-end ARM
    PKG_PATCH_DIRS+=" sdl-input"
  ;;
esac

pre_configure_target() {

# NextOS Amlogic-old: A53 tuning + LTO for performance
if [ "${DEVICE}" == "Amlogic-old" ]; then
  export CFLAGS="${CFLAGS} -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops -flto -fipa-pta"
  export CXXFLAGS="${CXXFLAGS} -mcpu=cortex-a53 -mtune=cortex-a53 -ftree-vectorize -funroll-loops -flto -fipa-pta"
  export LDFLAGS="${LDFLAGS} -flto -fipa-pta"
else
  export CFLAGS="${CFLAGS} -flto -fipa-pta"
  export CXXFLAGS="${CXXFLAGS} -flto -fipa-pta"
  export LDFLAGS="${LDFLAGS} -flto -fipa-pta"
fi

# unsupported modules
DISABLED_MODULES+=" --disable-apple2 \
                    --disable-sasplay \
                    --disable-ssfplay"

case ${DEVICE} in
  RK3326|RK3566*|H700)
    DISABLED_MODULES+=" --disable-snes \
                        --disable-ss \
                        --disable-psx"
  ;;
  Amlogic-old)
    # NextOS Mali-450: ALL cores enabled (Cortex-A53 + GL hw via gl4es).
    # ss (Sega Saturn) is heavy and likely slow, but available for testing.
  ;;
  RK3399)
    DISABLED_MODULES+=" --disable-snes \
                        --disable-ss"
  ;;
  RK3588*)
    DISABLED_MODULES+=" --disable-snes"
  ;;
esac

PKG_CONFIGURE_OPTS_TARGET="${DISABLED_MODULES}"
# Need to update automake files
  (
    cd ..
    sh autogen.sh
  )
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/src/mednafen ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/start_mednafen.sh
  chmod +x ${INSTALL}/usr/bin/mednafen_gen_config.sh

  mkdir -p ${INSTALL}/usr/config/${PKG_NAME}
  cp ${PKG_DIR}/config/common/* ${INSTALL}/usr/config/${PKG_NAME}
  # mednafen.gptk lives in config/common/ above; explicit chmod just to keep
  # the parser happy if the file lands without execute bits stripped.
  chmod 0644 ${INSTALL}/usr/config/${PKG_NAME}/mednafen.gptk 2>/dev/null || true
}
