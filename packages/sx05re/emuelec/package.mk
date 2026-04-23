# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="emuelec"
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} emuelec-emulationstation retroarch"
PKG_SECTION="emuelec"
PKG_LONGDESC="EmuELEC Meta Package"
PKG_TOOLCHAIN="manual"

PKG_EXPERIMENTAL="nestopiaCV flycast2021-lr skyemu-lr mesen tic-80 panda3ds-lr dolphin dosbox-core quicknes mesen-s easyrpg smsplus-gx wasm4 snes9x2005_plus snes9x2005 race ecwolf fileman portmaster quasi88 xmil np2kai hypseus-singe ikemen-go viceSA doublecherrygb play yabasanshiro mupen64plus-sa flycast flycast-dojo same_cdi"
PKG_EMUS="${LIBRETRO_CORES} beetle-saturn pico-8 drastic-advanced vircon32 mu mojozork gametank-lr gametank32-lr emuscv duckstation-lr crocods bsneshd b2 drastic-sa mame2003-xtreme-lr mame2015 mame2003-midway-lr opera bsnes-mercury-performance-lr bsnes-mercury-accuracy-lr mupen64plus-nx-lr bsnes-mercury-balanced-lr mupen64plus-lr morpheuscast-xtreme32-lr pcsx_rearmed-lr fbalpha2019-lr ludicrousn64-xtreme32-lr ludicrousn64-xtreme-lr beetle-psx desmume-2015 ppsspp ppssppsa PPSSPPSDL PPSSPPSA desmume melonds advancemame amiberry amiberry-lite hatarisa openbor dosbox-staging mupen64plus-nx mupen64plus-nx-alt scummvmsa stellasa solarus dosbox-pure pcsx_rearmed potator freej2me flycastsa fmsx-libretro jzintv xroar x16 simcoupe ti99sim oricutron"
PKG_COMPRESS="gzip minizip idtech lynx yamlcpp textviewer rapidxml libcroco pugixml pyFDT cifs-utils libzip xash3d SDL3 love re3 reVC"
PKG_DEPENDS_TARGET+=" emuelec-tools ${PKG_EMUS} ${PKG_EXPERIMENTAL} ${PKG_COMPRESS}"

# These packages are only meant for S922x, S905x2 and A311D devices as they run poorly on S905" 
if [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
	PKG_DEPENDS_TARGET+=" ${LIBRETRO_S922X_CORES}"
fi

if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	PKG_DEPENDS_TARGET+=" kmscon odroidgoa-utils"
    
  #we disable some cores that are not working or work poorly on OGA
	for discore in duckstation mesen-s virtualjaguar quicknes MC; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore} | |")
	done
	PKG_DEPENDS_TARGET+=" yabasanshiro"
else
	PKG_DEPENDS_TARGET+=" fbterm"
fi

# These cores do not work, or are not needed on aarch64, this package needs cleanup :) 
if [ "${ARCH}" == "aarch64" ]; then
  for discore in quicknes parallel-n64 pcsx_rearmed; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore}| |")
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

# Bloco Unificado para Dispositivos Potentes
if [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
    PKG_DEPENDS_TARGET+=" dolphinSA"
    # Se o MAME também for só para eles, ele entra aqui
fi

# Bloco para o MAME (Incluindo o seu Amlogic-old)
if [[ "${DEVICE}" =~ ^(Amlogic-ng|Amlogic-no|RK356x|OdroidM1|Amlogic-old)$ ]]; then
    PKG_DEPENDS_TARGET+=" mame"
fi

if [ "${DEVICE}" == "Amlogic-old" ]; then
    # Removemos APENAS o duckstation original para usar o seu novo -sa
    # O resto (Saturn/Yabasanshiro e CDI) deixamos passar para a build
for discore in yabasanshiro fceumm-mod yabasanshiroSA_1_5 yabasanshiro-libretro; do
  PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore}| |g")
done
    
    # ADICIONAMOS os novos e garantimos que os de Saturn estejam na lista
    PKG_DEPENDS_TARGET+=" dolphinSA"
    
    # Dica: O ee_s905 ajuda o sistema a identificar que é um hardware antigo
    echo "s905" > ${INSTALL}/ee_s905
  fi
fi


# These packages do not yet compile for OdroidM1
if [ "${DEVICE}" == "RK356x" ] || [ "${DEVICE}" == "OdroidM1" ]; then
 for discore in flycast-dojo; do
		PKG_DEPENDS_TARGET=$(echo ${PKG_DEPENDS_TARGET} | sed "s|${discore}| |")
	done
fi

makeinstall_target() {

	mkdir -p ${INSTALL}/usr/bin
	cp -rf ${PKG_DIR}/bin ${INSTALL}/usr

	mkdir -p ${INSTALL}/usr/config/
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/
  ln -sf /storage/.config/emuelec ${INSTALL}/emuelec

  # Added for compatibility with portmaster
  ln -sf /storage/roms ${INSTALL}/roms
  ln -sf /storage/roms/ports/PortMaster ${INSTALL}/PortMaster
  mkdir -p ${INSTALL}/usr/bin/ports
  touch ${INSTALL}/usr/bin/ports/.ports_here

  find ${INSTALL}/usr/config/emuelec/ -type f -exec chmod o+x {} \;

	mkdir -p ${INSTALL}/usr/config/emuelec/logs
	ln -sf /var/log ${INSTALL}/usr/config/emuelec/logs/var-log

  # leave for compatibility
  if [ "${DEVICE}" == "Amlogic-old" ]; then
    echo "s905" > ${INSTALL}/ee_s905
  fi


  echo "${DEVICE}" > ${INSTALL}/ee_arch
  
  mkdir -p ${INSTALL}/usr/share/retroarch-overlays
  cp -r ${PKG_DIR}/overlay/* ${INSTALL}/usr/share/retroarch-overlays
  
  mkdir -p ${INSTALL}/usr/share/common-shaders
  cp -r ${PKG_DIR}/shaders/* ${INSTALL}/usr/share/common-shaders
    
  mkdir -p ${INSTALL}/usr/share/libretro-database
  touch ${INSTALL}/usr/share/libretro-database/dummy
}

post_install() {
  for i in borders effects gamepads ipad keyboards misc; do
    rm -rf "${INSTALL}/usr/share/retroarch-overlays/${i}"
  done

  mkdir -p ${INSTALL}/etc/retroarch-joypad-autoconfig
  cp -r ${PKG_DIR}/gamepads/* ${INSTALL}/etc/retroarch-joypad-autoconfig

  # link default.target to emuelec.target
  ln -sf emuelec.target ${INSTALL}/usr/lib/systemd/system/default.target
  enable_service emuelec-autostart.service
  enable_service emuelec-disable_small_cores.service
  enable_service emuelec-reboot.service
  enable_service emuelec-shutdown.service


  # Remove scripts from OdroidGoAdvance build
  if [[ ${DEVICE} == "OdroidGoAdvance" || "${DEVICE}" == "GameForce" ]]; then 
    for i in "wifi" "sselphs_scraper" "skyscraper" "system_info"; do 
    xmlstarlet ed -L -P -d "/gameList/game[name='${i}']" ${INSTALL}/usr/bin/scripts/setup/gamelist.xml
    rm "${INSTALL}/usr/bin/scripts/setup/${i}.sh"
    done
  fi 

  # For automatic updates we use the buildate
	date +"%m%d%Y" > ${INSTALL}/usr/buildate
	
	ln -sf /storage/roms ${INSTALL}/roms
	
  # We make sure all files in /usr/bin are executables
	find ${INSTALL}/usr/bin -type f -exec chmod +x {} \;
} 
