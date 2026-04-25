# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="picodrivesa"
PKG_VERSION="95d368025f426e79ebdf86435ef3d378b32d40c0"
PKG_REV="2"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/felc18-blip/picodrive-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_SHORTDESC="PicoDrive Mega Drive / 32X / SegaCD standalone (Mali-friendly)"
PKG_TOOLCHAIN="configure"
GET_HANDLER_SUPPORT="git"

pre_configure_target() {
  TARGET_CONFIGURE_OPTS=" --platform=generic"
  # NextOS: build com SDL 1.2 API (via sdl12-compat shim). in_sdl.c usa
  # SDLK_LAST/WORLD_0/VIDEORESIZE etc que so existem em SDL 1.2.
  # sdl12-compat NAO entrega SDL_JOYBUTTONDOWN events corretamente — workaround
  # via gptokeyb (traduz gamepad p/ teclado, PicoDrive le SDL_KEYDOWN OK).
  # sdl-config do sdl12-compat tem prefix=/usr hardcoded (quebra cross),
  # geramos um wrapper com prefix=sysroot.
  cd ${PKG_BUILD}
  cat > sdl-config-cross <<EOF
#!/bin/sh
prefix=${SYSROOT_PREFIX}/usr
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include
case "\$1" in
  --version) echo "1.2.68";;
  --prefix)  echo "\$prefix";;
  --cflags)  echo "-I\${includedir}/SDL -D_GNU_SOURCE=1 -D_REENTRANT";;
  --libs)    echo "-L\${libdir} -lSDL";;
  *) echo "-I\${includedir}/SDL -D_GNU_SOURCE=1 -D_REENTRANT -L\${libdir} -lSDL";;
esac
EOF
  chmod +x sdl-config-cross
  export SDL_CONFIG="${PKG_BUILD}/sdl-config-cross"
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin/skin
# NextOS: fork emite binario lowercase (picodrive). Aceita ambos os nomes
# pra compat e instala como PicoDrive (caminho que ES + scripts esperam).
if [ -f ${PKG_BUILD}/PicoDrive ]; then
  cp -f ${PKG_BUILD}/PicoDrive ${INSTALL}/usr/bin/PicoDrive
elif [ -f ${PKG_BUILD}/picodrive ]; then
  cp -f ${PKG_BUILD}/picodrive ${INSTALL}/usr/bin/PicoDrive
fi
cp -rf ${PKG_BUILD}/skin/* ${INSTALL}/usr/bin/skin/
# NextOS: launcher script chamado pelo emuelecRunEmu.sh — wrapper p/
# auto-config de joystick + extracao de .zip/.7z.
cp -f ${PKG_DIR}/scripts/picodrive.start ${INSTALL}/usr/bin/picodrive.start
chmod +x ${INSTALL}/usr/bin/picodrive.start

# NextOS: gptokeyb config — traduz gamepad p/ teclado (workaround p/ bug
# do sdl12-compat que descarta SDL_JOYBUTTONDOWN events).
mkdir -p ${INSTALL}/usr/config/emuelec/configs/gptokeyb
cp -f ${PKG_DIR}/config/gptokeyb/picodrive.gptk \
      ${INSTALL}/usr/config/emuelec/configs/gptokeyb/picodrive.gptk
}
