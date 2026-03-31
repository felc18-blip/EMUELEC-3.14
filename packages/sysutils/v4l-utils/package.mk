# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

# with 1.0.0 repeat delay is broken. test on upgrade

PKG_NAME="v4l-utils"
PKG_VERSION="1.30.1"
PKG_SHA256="c1cf549c2ec3cf39eb5ec7bf15731349e61b26a21b5e963922db422333bae197"
PKG_LICENSE="GPL"
PKG_SITE="https://linuxtv.org/"
PKG_URL="https://linuxtv.org/downloads/v4l-utils/${PKG_NAME}-${PKG_VERSION}.tar.xz"

[[ "${DEVICE}" != "Amlogic-old" ]] && PKG_DEPENDS_TARGET="libbpf"
PKG_DEPENDS_TARGET="toolchain alsa-lib elfutils gcc-bpf:host ${PKG_DEPENDS_TARGET} systemd zlib"

PKG_LONGDESC="Linux V4L2 and DVB API utilities and v4l libraries (libv4l)."
PKG_STAMP_VAR="$IR_REMOTE_KEYMAPS"
PKG_TOOLCHAIN="meson"

# Flags traduzidas para manter o comportamento do 1.24.1
PKG_MESON_OPTS_TARGET="-Djpeg=disabled \
                       -Dgconv=disabled \
                       -Dqvidcap=disabled \
                       -Dqv4l2=disabled \
                       -Ddoxygen-doc=disabled \
                       -Dbpf=$(if [ "${DEVICE}" = "Amlogic-old" ]; then echo "disabled"; else echo "enabled"; fi) \
                       -Dudevdir=/usr/lib/udev"

# Deixamos o EmuELEC gerenciar a pasta de build do Meson automaticamente
# para evitar o erro de FileNotFoundError.

create_multi_keymap() {
  local f name map
  name="${1}"
  shift 1
  (
    for f in "$@"; do
      map="${INSTALL}/usr/lib/udev/rc_keymaps/${f}.toml"
      [ -e "${map}" ] && cat "${map}"
    done
  ) > ${INSTALL}/usr/lib/udev/rc_keymaps/${name}.toml
}

post_makeinstall_target() {
  local f keymap

  # Lógica original: Remove compliance se não for devel
  if [ ! "${LIBREELEC_VERSION}" == "devel" ]; then
    rm -f ${INSTALL}/usr/bin/v4l2-compliance
  fi

  # Estrutura de links simbólicos original
  rm -rf ${INSTALL}/etc/rc_keymaps
    ln -sf /storage/.config/rc_keymaps ${INSTALL}/etc/rc_keymaps

  mkdir -p ${INSTALL}/usr/config
    cp -PR ${PKG_DIR}/config/* ${INSTALL}/usr/config

  rm -rf ${INSTALL}/usr/lib/udev/rules.d
    mkdir -p ${INSTALL}/usr/lib/udev/rules.d
    cp -PR ${PKG_DIR}/udev.d/*.rules ${INSTALL}/usr/lib/udev/rules.d

  # install additional keymaps without overwriting upstream maps
  (
    set -C
    for f in ${PKG_DIR}/keymaps/*; do
      if [ -e ${f} ]; then
        keymap=$(basename ${f})
        cat ${f} > ${INSTALL}/usr/lib/udev/rc_keymaps/${keymap}
      fi
    done
  )

  # create multi keymap to support several remotes OOTB
  if [ -n "${IR_REMOTE_KEYMAPS}" ]; then
    create_multi_keymap libreelec_multi ${IR_REMOTE_KEYMAPS}

    # use multi-keymap em vez do padrão
    sed -i '/^\*\s*rc-rc6-mce\s*rc6_mce/d' ${INSTALL}/etc/rc_maps.cfg

    cat << EOF >> ${INSTALL}/etc/rc_maps.cfg
#
# Custom LibreELEC configuration starts here
#
# use combined multi-table on MCE receivers
# *		rc-rc6-mce	rc6_mce.toml
*		rc-rc6-mce	libreelec_multi.toml
# multi-table for amlogic devices
meson-ir	rc-empty	libreelec_multi.toml
EOF
  fi

  # Copia o contrib script (Lógica original)
  cp ${PKG_BUILD}/contrib/lircd2toml.py ${INSTALL}/usr/bin/

  # Limpeza NextOS (Mantendo o sistema Elite leve)
  rm -rf ${INSTALL}/usr/include
  rm -rf ${INSTALL}/usr/lib/pkgconfig
}