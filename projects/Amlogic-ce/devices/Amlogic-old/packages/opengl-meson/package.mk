# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC
# NextOS-Elite-Edition: Script Completo - Multilib Total (Corrigido para Sysroot/Toolchain)

PKG_NAME="opengl-meson"
PKG_VERSION="7bddce621a0c1e0cc12cfc8b707e93eb37fc0f82"
PKG_SHA256="15400e78b918b15743b815c195be472899d4243143e405a7b50d5be1cd07ffd1"
PKG_LICENSE="nonfree"
PKG_SITE="http://openlinux.amlogic.com:8000/download/ARM/filesystem/"
PKG_URL="https://github.com/CoreELEC/opengl-meson/archive/${PKG_VERSION}.tar.gz"

PKG_DEPENDS_TARGET="toolchain opentee_linuxdriver"

PKG_LONGDESC="OpenGL ES pre-compiled libraries for Mali GPUs found in Amlogic Meson SoCs."

PKG_TOOLCHAIN="manual"

makeinstall_target() {
  # =========================================================
  # 1. CRIAÇÃO DE DIRETÓRIOS (INSTALL = Sistema, SYSROOT = Compilador)
  # =========================================================
  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${INSTALL}/usr/lib32
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
  mkdir -p ${SYSROOT_PREFIX}/usr/lib32
  mkdir -p ${SYSROOT_PREFIX}/usr/include
  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig

  # =========================================================
  # 2. INSTALAÇÃO 64-BIT (Primária)
  # =========================================================
  # Garante compatibilidade caso a build não seja aarch64
  if [[ "${ARCH}" == "arm" ]]; then
    LIB_DIR="lib/eabihf"
  else
    LIB_DIR="lib/arm64"
  fi

  cp -p ${LIB_DIR}/gondul/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.gondul.so
  cp -p ${LIB_DIR}/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.dvalin.so
  cp -p ${LIB_DIR}/m450/r7p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.m450.so

  # Define m450 como principal e copia para o Toolchain
  ln -sf libMali.m450.so ${INSTALL}/usr/lib/libMali.so
  cp -p ${LIB_DIR}/m450/r7p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib/libMali.so

  # Cria symlinks tanto pro sistema quanto pro compilador cruzado
  for dir in "${INSTALL}/usr/lib" "${SYSROOT_PREFIX}/usr/lib"; do
    cd ${dir}
    ln -sf libMali.so libmali.so
    ln -sf libMali.so libmali.so.0
    ln -sf libMali.so libEGL.so
    ln -sf libMali.so libEGL.so.1
    ln -sf libMali.so libEGL.so.1.0.0
    ln -sf libMali.so libGLES_CM.so.1
    ln -sf libMali.so libGLESv1_CM.so
    ln -sf libMali.so libGLESv1_CM.so.1
    ln -sf libMali.so libGLESv2.so
    ln -sf libMali.so libGLESv2.so.2
    ln -sf libMali.so libGLESv2.so.2.0
    ln -sf libMali.so libGLESv3.so
    ln -sf libMali.so libGLESv3.so.3
    cd - > /dev/null
  done

  # =========================================================
  # 3. INSTALAÇÃO 32-BIT (Multilib Secundário)
  # =========================================================
  if [[ "${ARCH}" == "aarch64" ]]; then
    cp -p lib/eabihf/gondul/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.gondul.so
    cp -p lib/eabihf/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.so
    cp -p lib/eabihf/m450/r7p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.m450.so

    # Define m450 como principal 32b e copia para o Toolchain
    ln -sf libMali.m450.so ${INSTALL}/usr/lib32/libMali.so
    cp -p lib/eabihf/m450/r7p0/fbdev/libMali.so ${SYSROOT_PREFIX}/usr/lib32/libMali.so

    # Cria symlinks 32-bit no sistema e no compilador
    for dir in "${INSTALL}/usr/lib32" "${SYSROOT_PREFIX}/usr/lib32"; do
      cd ${dir}
      ln -sf libMali.so libmali.so
      ln -sf libMali.so libEGL.so
      ln -sf libMali.so libEGL.so.1
      ln -sf libMali.so libGLES_CM.so.1
      ln -sf libMali.so libGLESv1_CM.so
      ln -sf libMali.so libGLESv2.so
      ln -sf libMali.so libGLESv2.so.2
      ln -sf libMali.so libGLESv3.so
      cd - > /dev/null
    done
  fi

  # =========================================================
  # 4. INCLUDES / PKGCONFIG (Crucial para compilar emuladores)
  # =========================================================
  cp -rf ${PKG_BUILD}/include/* ${SYSROOT_PREFIX}/usr/include
  cp -rf ${PKG_BUILD}/pkgconfig/* ${SYSROOT_PREFIX}/usr/lib/pkgconfig

  # A linha salva-vidas do script original: coloca o eglplatform.h no lugar certo
  cp ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_fbdev/* ${SYSROOT_PREFIX}/usr/include/EGL/ 2>/dev/null || true
  rm -rf ${SYSROOT_PREFIX}/usr/include/EGL_platform

  # =========================================================
  # 5. OVERLAY & SCRIPTS DO NEXTOS-ELITE-EDITION
  # =========================================================
  mkdir -p ${INSTALL}/usr/sbin
  if [ -f "${PKG_DIR}/scripts/libmali-overlay-setup" ]; then
    cp ${PKG_DIR}/scripts/libmali-overlay-setup ${INSTALL}/usr/sbin
  fi

  ln -sf /var/lib/libMali.so ${INSTALL}/usr/lib/libmali-overlay.so

  if [[ "${ARCH}" == "aarch64" ]]; then
    mkdir -p ${INSTALL}/var/lib32
    ln -sf /usr/lib32/libMali.so ${INSTALL}/var/lib32/libMali.so
  fi

  # Hook placeholder
  mkdir -p ${INSTALL}/usr/bin

  # =========================================================
  # 6. FIX EXECSTACK — libMali vem com PT_GNU_STACK = RWX (0x7),
  #    o que o kernel bloqueia em dlopen() runtime com
  #    "cannot enable executable stack as shared object requires".
  #    LD_PRELOAD ainda funciona, mas dlopen() (usado pelo SDL3
  #    pra carregar EGL/GLES) falha. Limpamos o bit X do GNU_STACK
  #    em todos os libMali.*so instalados pra destravar dlopen.
  # =========================================================
  python3 - <<'PYSCRIPT'
import os, struct, glob
PT_GNU_STACK = 0x6474e551
for pattern in ["${INSTALL}/usr/lib/libMali*.so", "${INSTALL}/usr/lib32/libMali*.so",
                "${SYSROOT_PREFIX}/usr/lib/libMali.so", "${SYSROOT_PREFIX}/usr/lib32/libMali.so"]:
    for path in glob.glob(pattern):
        if os.path.islink(path):
            continue
        with open(path, "rb") as f:
            data = f.read()
        # ELF32 vs ELF64 — both Mali variants (eabihf=32, arm64=64) are shipped
        ei_class = data[4]
        if ei_class == 1:  # ELF32
            e_phoff   = struct.unpack("<I", data[28:32])[0]
            e_phentsize = struct.unpack("<H", data[42:44])[0]
            e_phnum   = struct.unpack("<H", data[44:46])[0]
            flags_field_offset_in_phdr = 24
            fmt_phdr = "<8I"
        else:  # ELF64
            e_phoff   = struct.unpack("<Q", data[32:40])[0]
            e_phentsize = struct.unpack("<H", data[54:56])[0]
            e_phnum   = struct.unpack("<H", data[56:58])[0]
            flags_field_offset_in_phdr = 4  # Phdr64: type, flags, offset, vaddr, paddr, ...
            fmt_phdr = None
        patched = False
        for i in range(e_phnum):
            ph_off = e_phoff + i*e_phentsize
            ph_type = struct.unpack("<I", data[ph_off:ph_off+4])[0]
            if ph_type == PT_GNU_STACK:
                fo = ph_off + flags_field_offset_in_phdr
                old = struct.unpack("<I", data[fo:fo+4])[0]
                if old & 1:  # X bit set
                    new = old & ~1
                    data = data[:fo] + struct.pack("<I", new) + data[fo+4:]
                    patched = True
                    print(f"  fixed EXECSTACK on {path}: 0x{old:x} -> 0x{new:x}")
                break
        if patched:
            with open(path, "wb") as f:
                f.write(data)
PYSCRIPT
}

post_install() {
  enable_service unbind-console.service
  enable_service libmali.service
}
