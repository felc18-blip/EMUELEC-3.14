# SPDX-License-Identifier: GPL-2.0-or-later
PKG_NAME="SDL3"
PKG_VERSION="ee9e9ad5c"
PKG_LICENSE="Zlib"
PKG_SITE="https://libsdl.org/"
PKG_URL="https://github.com/felc18-blip/SDL3-mali-fbdev/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib systemd dbus ${OPENGLES} pulseaudio"
PKG_LONGDESC="SDL3 with Mali FBDEV driver for NextOS"
PKG_DEPENDS_HOST="toolchain:host distutilscross:host"

PKG_CMAKE_OPTS_HOST="-DSDL_MALI=OFF \
                     -DSDL_KMSDRM=OFF \
                     -DSDL_X11=OFF \
                     -DSDL_TESTS=OFF \
                     -DSDL_EXAMPLES=OFF \
                     -DSDL_UNIX_CONSOLE_BUILD=ON"

PKG_CMAKE_OPTS_TARGET="-DSDL_STATIC=OFF \
                       -DSDL_SHARED=ON \
                       -DSDL_LIBC=ON \
                       -DSDL_GCC_ATOMICS=ON \
                       -DSDL_ALTIVEC=OFF \
                       -DSDL_OSS=OFF \
                       -DSDL_ALSA=ON \
                       -DSDL_ALSA_SHARED=ON \
                       -DSDL_JACK=OFF \
                       -DSDL_JACK_SHARED=OFF \
                       -DSDL_SNDIO=OFF \
                       -DSDL_DISKAUDIO=OFF \
                       -DSDL_DUMMYAUDIO=OFF \
                       -DSDL_DUMMYVIDEO=OFF \
                       -DSDL_WAYLAND=OFF \
                       -DSDL_COCOA=OFF \
                       -DSDL_VIVANTE=OFF \
                       -DSDL_PTHREADS=ON \
                       -DSDL_PTHREADS_SEM=ON \
                       -DSDL_CLOCK_GETTIME=OFF \
                       -DSDL_RPATH=OFF \
                       -DSDL_RENDER=ON \
                       -DSDL_X11=OFF \
                       -DSDL_OPENGL=OFF \
                       -DSDL_OPENGLES=ON \
                       -DSDL_VULKAN=OFF \
                       -DSDL_PULSEAUDIO=ON \
                       -DSDL_HIDAPI_JOYSTICK=OFF \
                       -DSDL_TESTS=OFF \
                       -DSDL_EXAMPLES=OFF \
                       -DSDL_UNIX_CONSOLE_BUILD=ON"

case "${DEVICE}" in
  'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=ON -DSDL_KMSDRM=OFF"
  ;;
  'OdroidGoAdvance'|'GameForce'|'RK356x'|'OdroidM1')
    PKG_PATCH_DIRS="Rockchip"
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=OFF -DSDL_KMSDRM=ON"
    PKG_DEPENDS_TARGET+=" libdrm mali-bifrost"
    if [ "${DEVICE}" = "OdroidGoAdvance" ]; then
      PKG_PATCH_DIRS+=" OdroidGoAdvance"
      PKG_DEPENDS_TARGET+=" librga"
    fi
  ;;
  *)
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=OFF -DSDL_KMSDRM=OFF"
  ;;
esac

pre_configure_target() {
  case "${DEVICE}" in
    'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')
      export CFLAGS="${CFLAGS} -DSDL_VIDEO_DRIVER_MALI=1"
    ;;
  esac
}

pre_make_target() {
  case "${DEVICE}" in
    'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')
      # Injetar o define no SDL_build_config.h gerado pelo cmake
      BUILD_CONFIG=$(find ${PKG_BUILD} -name "SDL_build_config.h" | head -1)
      if [ -n "${BUILD_CONFIG}" ]; then
        echo ">>> Injetando SDL_VIDEO_DRIVER_MALI em ${BUILD_CONFIG}"
        grep -q "SDL_VIDEO_DRIVER_MALI" "${BUILD_CONFIG}" || \
          echo "#define SDL_VIDEO_DRIVER_MALI 1" >> "${BUILD_CONFIG}"
        # Forçar recompilação do SDL_video.c
        touch ${PKG_BUILD}/src/video/SDL_video.c
      fi
      # Fix IsVirtualJoystick
      sed -i 's/IsVirtualJoystick(inpid.vendor, inpid.product, inpid.version, name)/0/g' \
        ${PKG_BUILD}/src/joystick/linux/SDL_sysjoystick.c || true
    ;;
    'OdroidGoAdvance')
      if ! grep -rnw "${PKG_BUILD}/CMakeLists.txt" -e '-lrga'; then
        sed -i "s|--no-undefined|--no-undefined -lrga|" ${PKG_BUILD}/CMakeLists.txt
      fi
    ;;
  esac
}

pre_make_host() {
  case "${DEVICE}" in
    'OdroidGoAdvance')
      sed -i "s| -lrga||g" ${PKG_BUILD}/CMakeLists.txt
    ;;
  esac
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/share
}
