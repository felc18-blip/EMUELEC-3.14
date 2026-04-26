# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="emuelec"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_SECTION="emuelec"
PKG_LONGDESC="EmuELEC Meta Package"
PKG_TOOLCHAIN="manual"

# ---------------------------------------------------------------------------
# Listas de pacotes
# ---------------------------------------------------------------------------

PKG_EXPERIMENTAL="nestopiaCV flycast2021-lr skyemu-lr mesen tic-80 panda3ds-lr \
                  dolphin dosbox-core quicknes mesen-s easyrpg smsplus-gx wasm4 \
                  snes9x2005_plus snes9x2005 race ecwolf fileman portmaster \
                  quasi88 xmil np2kai hypseus-singe ikemen-go viceSA \
                  doublecherrygb play mupen64plus-sa flycast \
                  flycast-dojo same_cdi daedalusx64-sa"
# yabasanshiro variants tirados temporariamente — outro terminal mexendo neles

PKG_EMUS="${LIBRETRO_CORES} beetle-saturn pico-8 drastic-advanced vircon32 mu \
          mojozork gametank-lr gametank32-lr emuscv duckstation-lr duckstation \
          crocods bsneshd b2 drastic-sa mame2003-xtreme-lr mame2015 \
          mame2003-midway-lr opera bsnes-mercury-performance-lr \
          bsnes-mercury-accuracy-lr mupen64plus-nx-lr bsnes-mercury-balanced-lr \
          mupen64plus-lr morpheuscast-xtreme32-lr pcsx_rearmed-lr \
          fbalpha2019-lr ludicrousn64-xtreme32-lr ludicrousn64-xtreme-lr \
          beetle-psx desmume-2015 ppsspp ppssppsa PPSSPPSDL PPSSPPSA desmume \
          melonds advancemame amiberry amiberry-lite hatarisa openbor \
          dosbox-staging mupen64plus-nx mupen64plus-nx-alt scummvmsa stellasa \
          solarus dosbox-pure pcsx_rearmed potator freej2me flycastsa \
          fmsx-libretro jzintv xroar x16 simcoupe ti99sim oricutron eka2l1 \
          touchhle-sa atari800sa dosbox-sdl2 fbneoSA mesen2 \
          picodrivesa vector06sdl sundog melonds-sa nanoboyadvance-sa \
          yabasanshiroSA_1_11"

PKG_COMPRESS="gzip minizip idtech lynx yamlcpp textviewer rapidxml libcroco \
              pugixml pyFDT cifs-utils libzip xash3d SDL3 love re3 reVC"

# ---------------------------------------------------------------------------
# Dependencias base (todos os devices)
# ---------------------------------------------------------------------------

PKG_DEPENDS_TARGET="toolchain ${OPENGLES} emuelec-emulationstation retroarch \
                    emuelec-tools ${PKG_EMUS} ${PKG_EXPERIMENTAL} ${PKG_COMPRESS}"

# ---------------------------------------------------------------------------
# Ajustes por DEVICE
# ---------------------------------------------------------------------------

# Devices potentes: cores S922x extras
if [ "${DEVICE}" = "Amlogic-ng" ] || [ "${DEVICE}" = "Amlogic-no" ] || \
   [ "${DEVICE}" = "RK356x" ]    || [ "${DEVICE}" = "OdroidM1" ]; then
  PKG_DEPENDS_TARGET+=" ${LIBRETRO_S922X_CORES}"
fi

# Handhelds (OGA / GameForce): kmscon + utilitarios; tira cores que rodam mal
if [ "${DEVICE}" = "OdroidGoAdvance" ] || [ "${DEVICE}" = "GameForce" ]; then
  PKG_DEPENDS_TARGET+=" kmscon odroidgoa-utils"
  for discore in duckstation mesen-s virtualjaguar quicknes MC; do
    PKG_DEPENDS_TARGET=$(echo " ${PKG_DEPENDS_TARGET} " | sed "s| ${discore} | |g")
  done
  # yabasanshiro tirado temporariamente — outro terminal mexendo
else
  PKG_DEPENDS_TARGET+=" fbterm"
fi

# ---------------------------------------------------------------------------
# Ajustes por ARCH (aarch64 = libs 32-bit, swanstation, etc.)
# ---------------------------------------------------------------------------

if [ "${ARCH}" = "aarch64" ]; then
  # Cores que nao sao necessarios em aarch64. Word boundary evita pcsx_rearmed
  # corromper pcsx_rearmed-lr / pcsx_rearmed_libretro etc.
  for discore in quicknes parallel-n64 pcsx_rearmed; do
    PKG_DEPENDS_TARGET=$(echo " ${PKG_DEPENDS_TARGET} " | sed "s| ${discore} | |g")
  done

  PKG_DEPENDS_TARGET+=" swanstation \
                        lib32-essential \
                        lib32-retroarch \
                        emuelec-32bit-info \
                        lib32-mupen64plus \
                        lib32-pcsx_rearmed \
                        lib32-uae4arm \
                        lib32-desmume \
                        lib32-pcsx_rearmed-lr \
                        lib32-parallel-n64 \
                        lib32-bennugd-monolithic \
                        lib32-droidports \
                        lib32-box86 \
                        lib32-libxcrypt \
                        lib32-libusb"
fi

# Dolphin standalone — devices potentes + Amlogic-old (testes do Felipe)
if [ "${DEVICE}" = "Amlogic-ng" ] || [ "${DEVICE}" = "Amlogic-no" ] || \
   [ "${DEVICE}" = "RK356x" ]    || [ "${DEVICE}" = "OdroidM1" ]   || \
   [ "${DEVICE}" = "Amlogic-old" ]; then
  PKG_DEPENDS_TARGET+=" dolphinSA"
fi

# MAME — devices que aguentam (inclui Amlogic-old)
case "${DEVICE}" in
  Amlogic-ng|Amlogic-no|RK356x|OdroidM1|Amlogic-old)
    PKG_DEPENDS_TARGET+=" mame"
    ;;
esac

# Amlogic-old: yabasanshiroSA_1_11 funciona (4 fixes do VIDSoft em 2026-04-25).
# Outras variantes Saturn ficam fora — muito pesado/redundante. fceumm-mod
# tambem fica fora (usamos versao base).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  for discore in yabasanshiroSA_1_5 yabasanshiro-libretro yabasanshiro-sa \
                 fceumm-mod yabasanshiro; do
    PKG_DEPENDS_TARGET=$(echo " ${PKG_DEPENDS_TARGET} " | sed "s| ${discore} | |g")
  done
fi

# RK356x / OdroidM1: flycast-dojo nao compila
if [ "${DEVICE}" = "RK356x" ] || [ "${DEVICE}" = "OdroidM1" ]; then
  for discore in flycast-dojo; do
    PKG_DEPENDS_TARGET=$(echo " ${PKG_DEPENDS_TARGET} " | sed "s| ${discore} | |g")
  done
fi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

makeinstall_target() {
  # binarios e configs base
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/bin ${INSTALL}/usr

  mkdir -p ${INSTALL}/usr/config/
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/

  # symlinks que codigo legado espera
  ln -sf /storage/.config/emuelec ${INSTALL}/emuelec
  ln -sf /storage/roms ${INSTALL}/roms
  ln -sf /storage/roms/ports/PortMaster ${INSTALL}/PortMaster

  # placeholder p/ ports (PortMaster cria o resto em runtime)
  mkdir -p ${INSTALL}/usr/bin/ports
  touch ${INSTALL}/usr/bin/ports/.ports_here

  # garante exec em todos os arquivos sob /usr/config/emuelec
  find ${INSTALL}/usr/config/emuelec/ -type f -exec chmod o+x {} \;

  # logs do EmuELEC apontam pro journal do systemd
  mkdir -p ${INSTALL}/usr/config/emuelec/logs
  ln -sf /var/log ${INSTALL}/usr/config/emuelec/logs/var-log

  # marker de hardware (codigo legado verifica /ee_s905)
  if [ "${DEVICE}" = "Amlogic-old" ]; then
    echo "s905" > ${INSTALL}/ee_s905
  fi
  echo "${DEVICE}" > ${INSTALL}/ee_arch

  # overlays + shaders + libretro-database
  mkdir -p ${INSTALL}/usr/share/retroarch-overlays
  cp -r ${PKG_DIR}/overlay/* ${INSTALL}/usr/share/retroarch-overlays

  mkdir -p ${INSTALL}/usr/share/common-shaders
  cp -r ${PKG_DIR}/shaders/* ${INSTALL}/usr/share/common-shaders

  mkdir -p ${INSTALL}/usr/share/libretro-database
  touch ${INSTALL}/usr/share/libretro-database/dummy
}

post_install() {
  # Limpa overlays nao usados (ficam ~50MB pesados senao)
  for i in borders effects gamepads ipad keyboards misc; do
    rm -rf "${INSTALL}/usr/share/retroarch-overlays/${i}"
  done

  # Joypad autoconfig do retroarch
  mkdir -p ${INSTALL}/etc/retroarch-joypad-autoconfig
  cp -r ${PKG_DIR}/gamepads/* ${INSTALL}/etc/retroarch-joypad-autoconfig

  # Boot direto no EmuELEC (em vez do default systemd target)
  ln -sf emuelec.target ${INSTALL}/usr/lib/systemd/system/default.target
  enable_service emuelec-autostart.service
  enable_service emuelec-disable_small_cores.service
  enable_service emuelec-reboot.service
  enable_service emuelec-shutdown.service

  # Handhelds: tira scripts de setup que nao fazem sentido (wifi, scrapers)
  if [ "${DEVICE}" = "OdroidGoAdvance" ] || [ "${DEVICE}" = "GameForce" ]; then
    for i in wifi sselphs_scraper skyscraper system_info; do
      xmlstarlet ed -L -P -d "/gameList/game[name='${i}']" \
        ${INSTALL}/usr/bin/scripts/setup/gamelist.xml
      rm "${INSTALL}/usr/bin/scripts/setup/${i}.sh"
    done
  fi

  # Auto-update usa essa data como version-stamp
  date +"%m%d%Y" > ${INSTALL}/usr/buildate

  ln -sf /storage/roms ${INSTALL}/roms

  # Garante exec em todos os scripts
  find ${INSTALL}/usr/bin -type f -exec chmod +x {} \;
}
