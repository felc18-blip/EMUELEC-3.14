# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="pipewire"
PKG_VERSION="1.6.3"
PKG_SHA256="93db72dc06768db548d48ae2b8e96e7c299c89a47f5c4426f152221aa90b0f2d"
PKG_LICENSE="LGPL"
PKG_SITE="https://pipewire.org"
PKG_URL="https://github.com/PipeWire/pipewire/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib dbus glib libpthread-stubs libsndfile libusb ncurses systemd"
PKG_LONGDESC="PipeWire is a server and user space API to deal with multimedia pipeline"

# --- VACINA KERNEL 3.14: Desativando Bluetooth BlueZ5 ---
# O código do BlueZ5 do Pipewire usa headers de latência (net_tstamp.h) que não existem no seu kernel antigo.
PKG_PIPEWIRE_BLUETOOTH="-Dbluez5=disabled"

# 🔥 Corrigido o missing '\' no jack-devel e desativadas dependências de kernel moderno (ALSA plugins, AVB)
PKG_MESON_OPTS_TARGET="-Ddocs=disabled \
                       -Dexamples=disabled \
                       -Dman=disabled \
                       -Dtests=disabled \
                       -Dinstalled_tests=disabled \
                       -Dgstreamer=disabled \
                       -Dgstreamer-device-provider=disabled \
                       -Dlibsystemd=enabled \
                       -Dsystemd-system-service=enabled \
                       -Dsystemd-user-service=disabled \
                       -Dpipewire-alsa=enabled \
                       -Dpipewire-jack=disabled \
                       -Dpipewire-v4l2=disabled \
                       -Djack-devel=false \
                       -Dspa-plugins=enabled \
                       -Dalsa=enabled \
                       -Daudiomixer=enabled \
                       -Daudioconvert=enabled \
                       ${PKG_PIPEWIRE_BLUETOOTH} \
                       -Dcontrol=enabled \
                       -Daudiotestsrc=disabled \
                       -Dffmpeg=disabled \
                       -Djack=disabled \
                       -Dsupport=enabled \
                       -Devl=disabled \
                       -Dtest=disabled \
                       -Dv4l2=disabled \
                       -Ddbus=enabled \
                       -Dlibcamera=disabled \
                       -Dvideoconvert=disabled \
                       -Dvideotestsrc=disabled \
                       -Dvolume=enabled \
                       -Dvulkan=disabled \
                       -Dpw-cat=enabled \
                       -Dudev=enabled \
                       -Dudevrulesdir=/usr/lib/udev/rules.d \
                       -Dsdl2=disabled \
                       -Dsndfile=enabled \
                       -Dlibpulse=enabled \
                       -Droc=disabled \
                       -Davahi=disabled \
                       -Decho-cancel-webrtc=disabled \
                       -Dlibusb=enabled \
                       -Dsession-managers=[] \
                       -Draop=disabled \
                       -Dlv2=disabled \
                       -Dx11=disabled \
                       -Dx11-xfixes=disabled \
                       -Dlibcanberra=disabled \
                       -Dlegacy-rtkit=false \
                       -Davb=disabled \
                       -Dcompress-offload=disabled"

pre_configure_target() {
  # --- VACINA GCC 15 ---
  export CFLAGS="${CFLAGS} -Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types -Wno-error=int-conversion -Wno-int-conversion -Wno-implicit-function-declaration -Wno-return-type"
}

post_makeinstall_target() {
  # connect to the system bus
  sed '/^\[Service\]/a Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket' -i ${INSTALL}/usr/lib/systemd/system/pipewire.service
}

post_install() {
  add_user pipewire x 982 980 "pipewire-daemon" "/var/run/pipewire" "/bin/sh"
  add_group pipewire 980
  # note that the pipewire user is added to the audio and video groups in systemd/package.mk
  # todo: maybe there is a better way to add users to groups in the future?

  enable_service pipewire.socket
  enable_service pipewire.service
}
