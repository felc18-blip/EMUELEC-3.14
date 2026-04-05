# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="vlc"
PKG_VERSION="3.0.23"
PKG_LICENSE="GPL"
PKG_SITE="http://www.videolan.org"
PKG_URL="https://mirror.netcologne.de/videolan.org/${PKG_NAME}/${PKG_VERSION}/$PKG_NAME-${PKG_VERSION}.tar.xz"

PKG_DEPENDS_TARGET="toolchain libdvbpsi gnutls ffmpeg libmpeg2 zlib flac libvorbis libxml2 pulseaudio mpg123-compat x264 ca-certificates"

PKG_TOOLCHAIN="autotools"

pre_configure_target() {

  # compat FFmpeg moderno
  export CFLAGS+=" -Wno-error"
  export CXXFLAGS+=" -Wno-error"

  ENABLED_FEATURES="--enable-silent-rules \
    --enable-run-as-root \
    --enable-sout \
    --enable-vlm \
    --enable-v4l2 \
    --enable-mpc \
    --enable-avcodec \
    --enable-avformat \
    --enable-swscale \
    --enable-postproc \
    --enable-aa \
    --enable-libmpeg2 \
    --enable-png \
    --enable-jpeg \
    --enable-libxml2 \
    --enable-alsa \
    --enable-udev \
    --enable-vlc \
    --enable-neon \
    --enable-x264 \
    --enable-gles2"

  DISABLED_FEATURES="--disable-dependency-tracking \
    --without-contrib \
    --disable-nls \
    --disable-rpath \
    --disable-dbus \
    --disable-gprof \
    --disable-cprof \
    --disable-debug \
    --disable-coverage \
    --disable-lua \
    --disable-notify \
    --disable-taglib \
    --disable-live555 \
    --disable-dc1394 \
    --disable-dvdread \
    --disable-dvdnav \
    --disable-opencv \
    --disable-decklink \
    --disable-sftp \
    --disable-vcd \
    --disable-libcddb \
    --disable-screen \
    --disable-ogg \
    --disable-shout \
    --disable-mod \
    --disable-gme \
    --disable-mad \
    --disable-faad \
    --disable-twolame \
    --disable-realrtsp \
    --disable-libtar \
    --disable-a52 \
    --disable-dca \
    --disable-vorbis \
    --disable-theora \
    --disable-libass \
    --disable-kate \
    --disable-libva \
    --disable-vdpau \
    --without-x \
    --disable-xcb \
    --disable-xvideo \
    --disable-sdl-image \
    --disable-freetype \
    --disable-fontconfig \
    --disable-svg \
    --disable-oss \
    --disable-jack \
    --disable-upnp \
    --disable-skins2 \
    --disable-ncurses \
    --disable-projectm \
    --disable-lirc \
    --disable-update-check \
    --disable-bluray \
    --disable-dav1d \
    --disable-qt \
    --disable-chromecast"

  if [ "${DEVICE}" == "Amlogic-old" ]; then
    ENABLED_FEATURES+=" --enable-pulse"
  else
    DISABLED_FEATURES+=" --disable-pulse"
  fi

  PKG_CONFIGURE_OPTS_TARGET="${ENABLED_FEATURES} ${DISABLED_FEATURES}"

  export LDFLAGS+=" -lresolv -fopenmp"
}

# FIX AUTOTOOLS
pre_make_target() {
  mkdir -p ${PKG_BUILD}/fakebin

  for tool in aclocal-1.16 automake-1.16 autoconf; do
    echo -e '#!/bin/sh\nexit 0' > ${PKG_BUILD}/fakebin/$tool
    chmod +x ${PKG_BUILD}/fakebin/$tool
  done

  export PATH="${PKG_BUILD}/fakebin:$PATH"
}

post_configure_target() {
  # Hack para evitar que o libtool tente fazer o relink dos plugins durante o make install
  # Isso evita o erro "mv: cannot stat 'libxxx_plugin.so'" no cross-compiling
  if [ -f "${PKG_BUILD}/.${TARGET_NAME}/libtool" ]; then
    sed -i 's/need_relink=yes/need_relink=no/g' ${PKG_BUILD}/.${TARGET_NAME}/libtool
  else
    find ${PKG_BUILD} -name "libtool" -exec sed -i 's/need_relink=yes/need_relink=no/g' {} +
  fi
}

post_makeinstall_target() {

  # -------------------------------
  # CERTIFICADOS (LOCAL AO VLC)
  # -------------------------------
  mkdir -p ${INSTALL}/usr/lib/vlc/certs

  cp ${SYSROOT_PREFIX}/etc/ssl/certs/ca-certificates.crt \
    ${INSTALL}/usr/lib/vlc/certs/ca-certificates.crt 2>/dev/null || true

  # -------------------------------
  # LIMPEZA PADRÃO
  # -------------------------------
  rm -rf ${INSTALL}/usr/share/applications
  rm -rf ${INSTALL}/usr/share/icons
  rm -rf ${INSTALL}/usr/share/kde4
  rm -f ${INSTALL}/usr/bin/rvlc
  rm -f ${INSTALL}/usr/bin/vlc-wrapper

  # -------------------------------
  # WRAPPER VLC (FORÇA CERT)
  # -------------------------------
  if [ -f ${INSTALL}/usr/bin/vlc ]; then
    mv ${INSTALL}/usr/bin/vlc ${INSTALL}/usr/bin/.vlc-bin
  fi

  cat << 'EOF' > ${INSTALL}/usr/bin/vlc
#!/bin/sh
export SSL_CERT_FILE=/usr/lib/vlc/certs/ca-certificates.crt
exec /usr/bin/.vlc-bin "$@"
EOF

  chmod +x ${INSTALL}/usr/bin/vlc

  # -------------------------------
  # CONFIG PERSISTENTE (EMUelec)
  # -------------------------------
  mkdir -p ${INSTALL}/usr/config
  mv ${INSTALL}/usr/lib/vlc ${INSTALL}/usr/config
  ln -sf /storage/.config/vlc ${INSTALL}/usr/lib/vlc
}
