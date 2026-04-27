# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mesen2"
PKG_VERSION="fabc9a62174f8734a113df6d244f5539ef6b8fcf"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/SourMesen/Mesen2"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_mixer SDL2_net"
PKG_LONGDESC="ECWolf is a port of the Wolfenstein 3D engine based of Wolf4SDL. It combines the original Wolfenstein 3D engine with the user experience of ZDoom to create the most user and mod author friendly Wolf3D source port."
PKG_TOOLCHAIN="make"

pre_make_target() {
# NextOS: kernel 3.14 input-event-codes.h nao tem KEY_KBDINPUTASSIST_* nem
# INPUT_PROP_ACCELEROMETER (introduzidos em 3.18). Copia versao moderna do
# host se sysroot nao tiver. Salva backup pra restaurar em post_make.
for h in input.h input-event-codes.h; do
  SYSROOT_HDR="${SYSROOT_PREFIX}/usr/include/linux/${h}"
  HOST_HDR="/usr/include/linux/${h}"
  if [ -f "$HOST_HDR" ]; then
    [ -f "$SYSROOT_HDR" ] && cp -f "$SYSROOT_HDR" "${SYSROOT_HDR}.nextos-bak"
    cp -f "$HOST_HDR" "$SYSROOT_HDR"
  fi
done
}

make_target() {
# NextOS: target `all` chama `ui` (.NET/dotnet) que nao temos no toolchain.
# Buildamos apenas `core` -> MesenCore.so (utilizavel como libretro core).
# Override CC/CXX/HOST_* como argumentos posicionais (`make VAR=val`)
# pra sobrescrever `:=` no Makefile.
#
# STATICLINK=false: o cross-toolchain LibreELEC nao tem libstdc++.a, so .so.
# upstream default e -static-libstdc++ que falha com "cannot find -lstdc++".
# FSLIB="": <filesystem> ja esta dentro de libstdc++.so desde GCC 9, nao
# precisamos de -lstdc++fs separado (e a lib nem existe no sysroot).
make core USE_GCC=true MESENPLATFORM=linux-arm64 MACHINE=aarch64 \
  STATICLINK=false FSLIB="" \
  CC="${CC}" CXX="${CXX}" AR="${AR}" \
  HOST_CC="${CC}" HOST_CXX="${CXX}"
}

post_make_target() {
# Restaura headers originais do sysroot. Pattern `[ -f X ] && mv` morre com
# set -e quando o backup nao existe (sysroot nao tinha o header original);
# usa if/then/fi pra ser tolerante a esse caso.
for h in input.h input-event-codes.h; do
  SYSROOT_HDR="${SYSROOT_PREFIX}/usr/include/linux/${h}"
  if [ -f "${SYSROOT_HDR}.nextos-bak" ]; then
    mv -f "${SYSROOT_HDR}.nextos-bak" "$SYSROOT_HDR"
  fi
done
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  # MesenCore.so vai como libretro core (mesen2 sem UI roda assim no NextOS).
  # MESENPLATFORM=linux-arm64 -> obj.linux-arm64. Tenta varios paths possiveis.
  for src in \
    ${PKG_BUILD}/InteropDLL/obj.linux-arm64/MesenCore.so \
    ${PKG_BUILD}/bin/linux-arm64/Release/MesenCore.so \
    ${PKG_BUILD}/InteropDLL/obj.linux-x64/MesenCore.so \
    ${PKG_BUILD}/bin/linux-x64/Release/MesenCore.so; do
    if [ -f "$src" ]; then
      cp -f "$src" ${INSTALL}/usr/lib/libretro/mesen2_libretro.so
      break
    fi
  done

  # Info file pra retroarch listar o core
  cat > ${INSTALL}/usr/lib/libretro/mesen2_libretro.info <<'INFOEND'
display_name = "Multi (Mesen2)"
authors = "Sour"
supported_extensions = "nes|fds|unf|unif|sfc|smc|swc|fig|bs|st|spc|gb|gbc|gba|pce|sgx|cue|chd|ws|wsc|sms|gg"
corename = "Mesen2"
license = "GPLv3"
permissions = ""
display_version = "0.16+"
categories = "Emulator"
systemname = "Multi (NES/SNES/GB/GBA/PCE/WS/SMS)"
manufacturer = "Various"
INFOEND
}
