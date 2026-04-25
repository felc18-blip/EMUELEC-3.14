# SPDX-License-Identifier: GPL-2.0-or-later
#
# lib32-SDL3: SDL3 com driver Mali FBDEV em 32-bit (armhf).
# Reusa tarball e patches/source do SDL3 aarch64.
# Necessario para lib32-SDL2 (sdl2-compat 32-bit) funcionar.

PKG_NAME="lib32-SDL3"
PKG_VERSION="$(get_pkg_version SDL3)"
PKG_NEED_UNPACK="$(get_pkg_directory SDL3)"
PKG_ARCH="aarch64"
PKG_LICENSE="Zlib"
PKG_SITE="https://libsdl.org/"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain lib32-libpulse lib32-alsa-lib lib32-systemd-libs lib32-dbus lib32-${OPENGLES}"
PKG_LONGDESC="SDL3 with Mali FBDEV driver (lib32)"
PKG_BUILD_FLAGS="lib32"

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
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=OFF -DSDL_KMSDRM=ON"
    PKG_DEPENDS_TARGET+=" lib32-libdrm lib32-mali-bifrost"
  ;;
  *)
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=OFF -DSDL_KMSDRM=OFF"
  ;;
esac

unpack() {
  ${SCRIPTS}/get SDL3
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/SDL3/SDL3-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

pre_configure_target() {
  # FIX: SDL3 CMakeLists.txt:426 hard-codes _TIME_BITS=64 for 32-bit glibc.
  # On Amlogic-old (kernel 4.9), the evdev compat ABI still writes 16-byte
  # events to 32-bit tasks while glibc's 64-bit time_t makes
  # sizeof(struct input_event) = 24. SDL3's read(fd, events, sizeof(events))
  # asks for 24*32 = 768 bytes; kernel writes 16-byte events; SDL parses
  # them as 24-byte and joystick events disappear silently.
  # Strip the _TIME_BITS=64 directive — y2038 isn't a concern here.
  if [ -f "${PKG_BUILD}/CMakeLists.txt" ]; then
    sed -i '/_TIME_BITS=64/d' "${PKG_BUILD}/CMakeLists.txt"
  fi

  case "${DEVICE}" in
    'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')
      export CFLAGS="${CFLAGS} -DSDL_VIDEO_DRIVER_MALI=1"
      MALIFILE="${PKG_BUILD}/src/video/mali-fbdev/SDL_malivideo.c"
      if [ -f "${MALIFILE}" ] && ! grep -q "MALI_SANITIZE_GL" "${MALIFILE}"; then
        echo ">>> Aplicando sanitize GL para Mali-450 (lib32)"
        python3 - <<PYSCRIPT
malifile = "${MALIFILE}"
with open(malifile, "r") as f:
    content = f.read()
sanitize = """    /* MALI_SANITIZE_GL: forca valores compativeis com Mali-450 MP (ES 2.0 only) */
    if (_this->gl_config.red_size < 5) _this->gl_config.red_size = 5;
    if (_this->gl_config.green_size < 6) _this->gl_config.green_size = 6;
    if (_this->gl_config.blue_size < 5) _this->gl_config.blue_size = 5;
    if (_this->gl_config.major_version > 2) { _this->gl_config.major_version = 2; _this->gl_config.minor_version = 0; }
    if (window->flags & SDL_WINDOW_OPENGL) {"""
old_line = "    if (window->flags & SDL_WINDOW_OPENGL) {"
if "MALI_SANITIZE_GL" not in content:
    content = content.replace(old_line, sanitize, 1)
with open(malifile, "w") as f:
    f.write(content)
print("sanitize ok")
PYSCRIPT
      fi
    ;;
  esac
}

pre_make_target() {
  case "${DEVICE}" in
    'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')
      BUILD_CONFIG=$(find ${PKG_BUILD} -name "SDL_build_config.h" | head -1)
      if [ -n "${BUILD_CONFIG}" ]; then
        echo ">>> Injetando SDL_VIDEO_DRIVER_MALI em ${BUILD_CONFIG} (lib32)"
        grep -q "SDL_VIDEO_DRIVER_MALI" "${BUILD_CONFIG}" || \
          echo "#define SDL_VIDEO_DRIVER_MALI 1" >> "${BUILD_CONFIG}"
        touch ${PKG_BUILD}/src/video/SDL_video.c
      fi
      sed -i 's/IsVirtualJoystick(inpid.vendor, inpid.product, inpid.version, name)/0/g' \
        ${PKG_BUILD}/src/joystick/linux/SDL_sysjoystick.c || true
    ;;
  esac
}

post_makeinstall_target() {
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/share
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
