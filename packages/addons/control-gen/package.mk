# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)
# Adaptado para EmuELEC 3.14 - Felipe

PKG_NAME="control-gen"
PKG_VERSION="75ade0f0344d2338968313ff346412fe5b1e4df0"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SECTION="tools"
PKG_SHORTDESC="Generates control.txt for gptokeyb"
PKG_TOOLCHAIN="manual"

make_target() {
  mkdir -p ${PKG_BUILD}

  cp -f ${PKG_DIR}/control-gen.cpp ${PKG_BUILD}

  ${CXX} ${CXXFLAGS} ${LDFLAGS} \
         -I${SYSROOT_PREFIX}/usr/include/SDL2 \
         ${PKG_BUILD}/control-gen.cpp \
         -o ${PKG_BUILD}/control-gen \
         -lSDL2 -D_REENTRANT
}

makeinstall_target() {
  # instalar control-gen
  mkdir -p ${INSTALL}/usr/bin
  install -m 0755 ${PKG_BUILD}/control-gen ${INSTALL}/usr/bin/

  # instalar scripts extras
  if [ -d "${PKG_DIR}/scripts" ]; then
    cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/
  fi

  chmod 0755 ${INSTALL}/usr/bin/* 2>/dev/null

  # estrutura do gptokeyb
  mkdir -p ${INSTALL}/storage/.config/emuelec/configs/gptokeyb

  # wrapper para redirecionar gptokeyb → gptokeyb2
  cat > ${INSTALL}/usr/bin/gptokeyb << 'EOF'
#!/bin/sh
CONTROLFOLDER="/roms/ports/PortMaster"

if [ -f "$CONTROLFOLDER/libinterpose.aarch64.so" ]; then
  LIB="$CONTROLFOLDER/libinterpose.aarch64.so"
elif [ -f "$CONTROLFOLDER/libinterpose.armhf.so" ]; then
  LIB="$CONTROLFOLDER/libinterpose.armhf.so"
else
  exec "$CONTROLFOLDER/gptokeyb2" "$@"
fi

exec env LD_PRELOAD=$LIB "$CONTROLFOLDER/gptokeyb2" "$@"
EOF

  chmod 0755 ${INSTALL}/usr/bin/gptokeyb
}