# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-opengl-meson"
PKG_VERSION="$(get_pkg_version opengl-meson)"
PKG_NEED_UNPACK="$(get_pkg_directory opengl-meson)"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="http://openlinux.amlogic.com:8000/download/ARM/filesystem/"
PKG_URL=""
PKG_DEPENDS_TARGET="lib32-toolchain opengl-meson"
PKG_LONGDESC="OpenGL ES pre-compiled libraries for Mali GPUs found in Amlogic Meson SoCs."
PKG_PATCH_DIRS+=" $(get_pkg_directory opengl-meson)/patches"
PKG_TOOLCHAIN="manual"
PKG_BUILD_FLAGS="lib32"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib32
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
  local DIR_MESON="$(get_build_dir opengl-meson)"
  local DIR_ARM=${DIR_MESON}/lib/eabihf
  local SINGLE_LIBMALI='no'
  case "${DEVICE}" in 
    Amlogic-ng)
      cp -p ${DIR_ARM}/gondul/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.gondul.so
      cp -p ${DIR_ARM}/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.so
      cp -p ${DIR_ARM}/m450/r7p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.m450.so
      cp -p ${DIR_ARM}/gondul/r12p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib/
    ;;
    Amlogic-old)
      cp -p ${DIR_ARM}/m450/r7p0/fbdev/libMali.so ${INSTALL}/usr/lib32/
      cp -p ${DIR_ARM}/m450/r7p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib/
      SINGLE_LIBMALI='yes'
    ;;
    Amlogic-ne)
      cp -p ${DIR_ARM}/gondul/r25p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.gondul.so
      cp -p ${DIR_ARM}/dvalin/r25p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.so
      cp -p ${DIR_ARM}/gondul/r25p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib/
    ;;
   Amlogic-no)
      cp -p "${DIR_ARM}/gondul/r25p0/fbdev/libMali-r1p0.so" "${INSTALL}/usr/lib32/libMali.gondul.so"
      cp -p ${DIR_ARM}/dvalin/r25p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.so
      cp -p ${DIR_ARM}/valhall/r41p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.valhall.so
      cp -p ${DIR_ARM}/gondul/r25p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib/
    ;;
    *)
      echo "${PKG_NAME}: Trying to install for device ${DEVICE} when only Amlogic-ng, Amlogic-no, Amlogic-old and Amlogic-ne are supported" 1>&2
      return 1
    ;;
  esac

  if [[ "${SINGLE_LIBMALI}" == 'no' ]]; then
    ln -sf /var/lib32/libMali.so ${INSTALL}/usr/lib32/libMali.so
  fi

  local LINK_LIST="libmali.so \
                   libmali.so.0 \
                   libEGL.so \
                   libEGL.so.1 \
                   libEGL.so.1.0.0 \
                   libGLES_CM.so.1 \
                   libGLESv1_CM.so \
                   libGLESv1_CM.so.1 \
                   libGLESv1_CM.so.1.0.1 \
                   libGLESv1_CM.so.1.1 \
                   libGLESv2.so \
                   libGLESv2.so.2 \
                   libGLESv2.so.2.0 \
                   libGLESv2.so.2.0.0 \
                   libGLESv3.so \
                   libGLESv3.so.3 \
                   libGLESv3.so.3.0 \
                   libGLESv3.so.3.0.0"
  local LINK_NAME
  for LINK_NAME in ${LINK_LIST}; do
    ln -sf libMali.so ${INSTALL}/usr/lib32/${LINK_NAME}
    ln -sf libMali.so ${SYSROOT_PREFIX}/usr/lib/${LINK_NAME}
  done

  # FIX: glibc 2.41+ rejeita dlopen() de libs com PT_GNU_STACK = RWE.
  # libMali.so vem do blob da Amlogic com stack executavel marcado,
  # entao ports 32-bit que dao dlopen() de libGLESv2/libEGL falham
  # com "cannot enable executable stack as shared object requires" —
  # forcando o usuario a rodar com LD_PRELOAD=/usr/lib32/libMali.so.
  # Patch in-place clearing PF_X (bit 0) do flags do PT_GNU_STACK
  # program header via Python, deixa todos os ports rodando out of
  # the box. Aplicado em todas as variantes (m450/dvalin/gondul/
  # valhall) presentes no INSTALL e SYSROOT.
  for MALI in ${INSTALL}/usr/lib32/libMali*.so ${SYSROOT_PREFIX}/usr/lib/libMali.so; do
    [ -f "${MALI}" ] || continue
    [ -L "${MALI}" ] && continue
    python3 - "${MALI}" <<'PYSCRIPT'
import struct, sys
path = sys.argv[1]
with open(path, "r+b") as f:
    e_ident = f.read(16)
    if e_ident[:4] != b"\x7fELF":
        sys.exit(0)
    little = e_ident[5] == 1
    is64 = e_ident[4] == 2
    endian = "<" if little else ">"
    if is64:
        f.seek(32); e_phoff = struct.unpack(endian + "Q", f.read(8))[0]
        f.seek(54); e_phentsize, e_phnum = struct.unpack(endian + "HH", f.read(4))
    else:
        f.seek(28); e_phoff = struct.unpack(endian + "I", f.read(4))[0]
        f.seek(42); e_phentsize, e_phnum = struct.unpack(endian + "HH", f.read(4))
    PT_GNU_STACK = 0x6474e551
    PF_X = 1
    patched = 0
    for i in range(e_phnum):
        ph_off = e_phoff + i * e_phentsize
        if is64:
            f.seek(ph_off); p_type, p_flags = struct.unpack(endian + "II", f.read(8))
            flags_off = ph_off + 4
        else:
            f.seek(ph_off); p_type = struct.unpack(endian + "I", f.read(4))[0]
            f.seek(ph_off + 24); p_flags = struct.unpack(endian + "I", f.read(4))[0]
            flags_off = ph_off + 24
        if p_type != PT_GNU_STACK or not (p_flags & PF_X):
            continue
        f.seek(flags_off); f.write(struct.pack(endian + "I", p_flags & ~PF_X))
        patched += 1
    sys.stderr.write("[opengl-meson] cleared PT_GNU_STACK PF_X in %s (patched=%d)\n" % (path, patched))
PYSCRIPT
  done

# install headers and libraries to TOOLCHAIN
  cp -rf ${DIR_MESON}/include/* ${SYSROOT_PREFIX}/usr/include
  cp -rf "$(get_build_dir opengl-meson)/lib/pkgconfig/"* ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  cp ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_fbdev/* ${SYSROOT_PREFIX}/usr/include/EGL
  rm -rf ${SYSROOT_PREFIX}/usr/include/EGL_platform
}
