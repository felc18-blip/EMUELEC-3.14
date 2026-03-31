# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-ffmpeg"
PKG_VERSION="$(get_pkg_version ffmpeg)"
PKG_NEED_UNPACK="$(get_pkg_directory ffmpeg)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL-3.0-only"
PKG_SITE="https://ffmpeg.org"
PKG_URL=""
# ELITE: Dependências sincronizadas para o ambiente 32-bit
PKG_DEPENDS_TARGET="lib32-toolchain lib32-zlib lib32-bzip2 lib32-openssl lib32-SDL2 lib32-libxml2 lib32-libdrm lib32-systemd-libs"
PKG_LONGDESC="FFmpeg is a complete, cross-platform solution to record, convert and stream audio and video."
PKG_BUILD_FLAGS="lib32 -gold"

FF_DIRECTORY="$(get_pkg_directory ffmpeg)"
PKG_PATCH_DIRS+=" ${FF_DIRECTORY}/patches/postproc \
                  ${FF_DIRECTORY}/patches/libreelec \
                  ${FF_DIRECTORY}/patches/v4l2-request \
                  ${FF_DIRECTORY}/patches/v4l2-drmprime" 

get_graphicdrivers

# ELITE: Ativação segura para lib32 (M2M e Udev ativos, Request em OFF para evitar erros de headers)
PKG_FFMPEG_V4L2="--enable-libudev --enable-libdrm"

unpack() {
  ${SCRIPTS}/get ffmpeg
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/ffmpeg/ffmpeg-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
  if [ "${DISTRO}" = "EmuELEC" ]; then
    sed -i "s|int hide_banner = 0|int hide_banner = 1|" ${PKG_BUILD}/fftools/cmdutils.c
    sed -i "s|SDL2_CONFIG=\"\${cross_prefix}sdl2-config\"|SDL2_CONFIG=\"${SYSROOT_PREFIX}/usr/bin/sdl2-config\"|" ${PKG_BUILD}/configure
  fi

  # ELITE: Garante que o compilador use os caminhos de 32-bit do SYSROOT
  export EXTRA_CFLAGS="-I${SYSROOT_PREFIX}/usr/include"
  export EXTRA_LDFLAGS="-L${SYSROOT_PREFIX}/usr/lib"
}

configure_target() {
  ./configure --prefix="/usr" \
              --cpu="${LIB32_TARGET_CPU}" \
              --arch=arm \
              --enable-cross-compile \
              --cross-prefix="${TARGET_PREFIX}" \
              --sysroot="${SYSROOT_PREFIX}" \
              --sysinclude="${SYSROOT_PREFIX}/usr/include" \
              --target-os="linux" \
              --nm="${NM}" \
              --ar="${AR}" \
              --as="${CC}" \
              --cc="${CC}" \
              --ld="${CC}" \
              --host-cc="${HOST_CC}" \
              --host-cflags="${HOST_CFLAGS}" \
              --host-ldflags="${HOST_LDFLAGS}" \
              --extra-cflags="${CFLAGS} ${EXTRA_CFLAGS}" \
              --extra-ldflags="${LDFLAGS} ${EXTRA_LDFLAGS}" \
              --extra-libs="${PKG_FFMPEG_LIBS}" \
              --disable-static \
              --enable-shared \
              --enable-gpl \
              --enable-version3 \
              --enable-logging \
              --disable-doc \
              --disable-debug \
              --enable-stripping \
              --enable-pic \
              --pkg-config="${TOOLCHAIN}/bin/pkg-config" \
              --enable-optimizations \
              --disable-extra-warnings \
              --enable-avdevice \
              --enable-avcodec \
              --enable-avformat \
              --enable-swscale \
              --enable-postproc \
              --enable-avfilter \
              --enable-pthreads \
              --enable-network \
              --disable-gnutls \
              --enable-openssl \
              --disable-gray \
              --enable-swscale-alpha \
              --disable-small \
              ${PKG_FFMPEG_V4L2} \
              --disable-vaapi \
              --disable-vdpau \
              --enable-runtime-cpudetect \
              --disable-hardcoded-tables \
              --disable-encoders \
              --enable-encoder=ac3 \
              --enable-encoder=aac \
              --enable-encoder=wmav2 \
              --enable-encoder=mjpeg \
              --enable-encoder=png \
              --enable-encoder=mpeg4 \
              --enable-encoder=libx264 \
              --enable-hwaccels \
              --disable-muxers \
              --enable-muxer=spdif \
              --enable-muxer=adts \
              --enable-muxer=asf \
              --enable-muxer=ipod \
              --enable-muxer=mpegts \
              --enable-demuxers \
              --enable-parsers \
              --enable-bsfs \
              --enable-protocol=http \
              --enable-filters \
              --disable-avisynth \
              --enable-bzlib \
              --disable-lzma \
              --disable-alsa \
              --disable-frei0r \
              --disable-libopencore-amrnb \
              --disable-libopencore-amrwb \
              --disable-libopencv \
              --disable-libdc1394 \
              --disable-libfreetype \
              --disable-libgsm \
              --disable-libmp3lame \
              --disable-libopenjpeg \
              --disable-librtmp \
              --disable-libspeex \
              --disable-libtheora \
              --disable-libvo-amrwbenc \
              --disable-libvorbis \
              --disable-libvpx \
              --disable-libx264 \
              --disable-libxavs \
              --enable-libxml2 \
              --disable-libxvid \
              --enable-zlib \
              --enable-asm \
              --disable-altivec \
              --enable-neon \
              --disable-symver \
              --enable-ffmpeg \
              --enable-ffplay \
              --disable-ffprobe
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/bin
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share

  # ELITE: Marreta para garantir libpostproc 32-bit (antes de mover para lib32)
  echo "Instalando libpostproc 32-bit manualmente..."
  cp -P ${PKG_BUILD}/libpostproc/libpostproc.so* ${INSTALL}/usr/lib/ 2>/dev/null || true
  mkdir -p ${INSTALL}/usr/lib/pkgconfig
  cp ${PKG_BUILD}/libpostproc/libpostproc.pc ${INSTALL}/usr/lib/pkgconfig/ 2>/dev/null || true

  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}