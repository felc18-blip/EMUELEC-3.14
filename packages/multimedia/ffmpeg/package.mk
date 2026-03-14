# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="ffmpeg"
PKG_LICENSE="LGPLv2.1+"
PKG_SITE="https://ffmpeg.org"
PKG_DEPENDS_TARGET="toolchain zlib bzip2 SDL2 openssl speex"
PKG_LONGDESC="FFmpeg is a complete, cross-platform solution to record, convert and stream audio and video."

PKG_VERSION="6.0"
PKG_URL="http://ffmpeg.org/releases/ffmpeg-${PKG_VERSION}.tar.xz"
PKG_PATCH_DIRS="unofficialos"
PKG_PATCH_DIRS+=" v4l2-request v4l2-drmprime" # Patches adicionais necessários para EmuELEC

post_unpack() {
  # Fix FFmpeg version
  if [ "${PROJECT}" = "Amlogic" ]; then
    echo "${PKG_FFMPEG_BRANCH}-${PKG_VERSION:0:7}" > ${PKG_BUILD}/VERSION
  else
    echo "${PKG_VERSION}" > ${PKG_BUILD}/RELEASE
  fi
}

# Dependencies
get_graphicdrivers

PKG_FFMPEG_HWACCEL="--enable-hwaccels"

case ${DEVICE} in
  RK3588*)
    V4L2_SUPPORT=no
  ;;
  *)
    case ${PROJECT} in
      Rockchip)
        PKG_PATCH_DIRS+=" vf-deinterlace-v4l2m2m"
      ;;
    esac
  ;;
esac

# Forçamos a ativação do V4L2 se for Amlogic ou se o suporte geral estiver ligado
if [ "${V4L2_SUPPORT}" = "yes" ] || [ "${PROJECT}" = "Amlogic" ]; then
  PKG_DEPENDS_TARGET+=" libdrm"
  PKG_NEED_UNPACK+=" $(get_pkg_directory libdrm)"
  PKG_FFMPEG_V4L2="--enable-v4l2_m2m --enable-libdrm"

  case ${PROJECT} in
    Amlogic|PC|Rockchip)
      PKG_V4L2_REQUEST="yes"
    ;;
    *)
      PKG_V4L2_REQUEST="no"
    ;;
  esac

  if [ "${PKG_V4L2_REQUEST}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" systemd"
    PKG_NEED_UNPACK+=" $(get_pkg_directory systemd)"
    PKG_FFMPEG_V4L2+=" --enable-libudev --enable-v4l2-request"
  else
    PKG_FFMPEG_V4L2+=" --disable-libudev --disable-v4l2-request"
  fi
else
  PKG_FFMPEG_V4L2="--disable-v4l2_m2m --disable-libudev --disable-v4l2-request"
fi

if [ "${VAAPI_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" libva"
  PKG_NEED_UNPACK+=" $(get_pkg_directory libva)"
  PKG_FFMPEG_VAAPI="--enable-vaapi"
else
  PKG_FFMPEG_VAAPI="--disable-vaapi"
fi

if [ "${DISPLAYSERVER}" != "wl" ]; then
  PKG_DEPENDS_TARGET+=" libdrm"
  PKG_NEED_UNPACK+=" $(get_pkg_directory libdrm)"
  PKG_FFMPEG_VAAPI=" --enable-libdrm"
fi

if [ "${VDPAU_SUPPORT}" = "yes" -a "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" libvdpau"
  PKG_NEED_UNPACK+=" $(get_pkg_directory libvdpau)"
  PKG_FFMPEG_VDPAU="--enable-vdpau"
else
  PKG_FFMPEG_VDPAU="--disable-vdpau"
fi

if build_with_debug; then
  PKG_FFMPEG_DEBUG="--enable-debug --disable-stripping"
else
  PKG_FFMPEG_DEBUG="--disable-debug --enable-stripping"
fi

if target_has_feature neon; then
  PKG_FFMPEG_FPU="--enable-neon"
else
  PKG_FFMPEG_FPU="--disable-neon"
fi

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" nasm:host"
fi

case ${PROJECT} in
  Rockchip)
    PKG_DEPENDS_TARGET+=" rkmpp"
  ;;
esac

if target_has_feature "(neon|sse)"; then
  PKG_DEPENDS_TARGET+=" dav1d"
  PKG_NEED_UNPACK+=" $(get_pkg_directory dav1d)"
  PKG_FFMPEG_AV1="--enable-libdav1d"
else
  PKG_FFMPEG_AV1="--disable-libdav1d"
fi

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
}

if [ "${FFMPEG_TESTING}" = "yes" ]; then
  # Modo teste: Habilita ffmpeg e ffplay + ferramentas de debug
  PKG_FFMPEG_TESTING="--enable-ffmpeg --enable-ffplay --enable-encoder=wrapped_avframe --enable-muxer=null"
  if [ "${PROJECT}" = "RPi" ]; then
    PKG_FFMPEG_TESTING+=" --enable-vout-drm --enable-outdev=vout_drm"
  fi
else
  # Modo padrão: Habilita o conversor (ffmpeg) e o player (ffplay)
  # Mantemos o ffprobe desativado para economizar espaço
  PKG_FFMPEG_TESTING="--enable-ffmpeg --enable-ffplay --disable-ffprobe"
fi

configure_target() {
  # Correção vital para o EmuELEC encontrar o SDL2 e esconder o banner
  if [ "${DISTRO}" = "EmuELEC" ]; then
    sed -i "s|int hide_banner = 0|int hide_banner = 1|" ${PKG_BUILD}/fftools/cmdutils.c
    sed -i "s|SDL2_CONFIG=\"\${cross_prefix}sdl2-config\"|SDL2_CONFIG=\"${SYSROOT_PREFIX}/usr/bin/sdl2-config\"|" ${PKG_BUILD}/configure
  fi

  ./configure --prefix="/usr" \
              --cpu="${TARGET_CPU}" \
              --arch="${TARGET_ARCH}" \
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
              --extra-cflags="${CFLAGS}" \
              --extra-ldflags="${LDFLAGS}" \
              --extra-libs="${PKG_FFMPEG_LIBS}" \
              --disable-static \
              --enable-shared \
              --enable-version3 \
              --enable-logging \
              --disable-doc \
              ${PKG_FFMPEG_DEBUG} \
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
              --disable-devices \
              --enable-pthreads \
              --enable-network \
              --disable-gnutls --enable-openssl \
              --disable-gray \
              --enable-swscale-alpha \
              --disable-small \
              --enable-dct \
              --enable-fft \
              --enable-mdct \
              --enable-rdft \
              --disable-crystalhd \
              ${PKG_FFMPEG_V4L2} \
              ${PKG_FFMPEG_VAAPI} \
              ${PKG_FFMPEG_VDPAU} \
              ${PKG_FFMPEG_HWACCEL} \
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
              --disable-muxers \
			  --enable-gpl \
              --enable-muxer=spdif \
              --enable-muxer=adts \
              --enable-muxer=asf \
              --enable-muxer=ipod \
              --enable-muxer=mpegts \
              --enable-demuxers \
              --enable-parsers \
              --enable-bsfs \
              --enable-protocol=http \
              --disable-indevs \
              --disable-outdevs \
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
              ${PKG_FFMPEG_AV1} \
              --enable-libspeex \
              --disable-libtheora \
              --disable-libvo-amrwbenc \
              --disable-libvorbis \
              --disable-libvpx \
              --disable-libx264 \
              --disable-libxavs \
              --disable-libxvid \
              --enable-zlib \
              --enable-asm \
              --disable-altivec \
              ${PKG_FFMPEG_FPU} \
              --disable-symver \
              ${PKG_FFMPEG_TESTING}
}

post_makeinstall_target() {
  # Limpeza de exemplos (já existia)
  rm -rf ${INSTALL}/usr/share/ffmpeg/examples

  # --- MARRETA PARA INSTALAR LIBPOSTPROC ---
  echo "Instalando libpostproc manualmente..."
  mkdir -p ${INSTALL}/usr/lib/pkgconfig
  mkdir -p ${INSTALL}/usr/include/libpostproc

  # Copia as bibliotecas (.so e .so.57)
  cp -P ${PKG_BUILD}/libpostproc/libpostproc.so* ${INSTALL}/usr/lib/

  # Copia o header (necessário para compilar o PPSSPP)
  cp ${PKG_BUILD}/libpostproc/postprocess.h ${INSTALL}/usr/include/libpostproc/

  # Copia o arquivo .pc (essencial para o CMake/pkg-config achar a lib)
  cp ${PKG_BUILD}/libpostproc/libpostproc.pc ${INSTALL}/usr/lib/pkgconfig/
}