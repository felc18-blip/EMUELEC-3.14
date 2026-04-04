# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)
PKG_NAME="samba"
PKG_VERSION="4.24.0"
PKG_SHA256="1b1e457fd651a612cd08226cc6efd04e5d01e36d918c8b4c4e470e74e86881ea"
PKG_LICENSE="GPLv3+"
PKG_SITE="https://www.samba.org"
PKG_URL="https://download.samba.org/pub/samba/stable/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="autotools:host gcc:host heimdal:host attr connman e2fsprogs gnutls libaio libunwind popt Python3 readline talloc zlib"
PKG_NEED_UNPACK="$(get_pkg_directory heimdal) $(get_pkg_directory e2fsprogs)"
PKG_LONGDESC="A free SMB / CIFS fileserver and client."


[[ "${DEVICE}" != "Amlogic-old" ]] && PKG_DEPENDS_TARGET+=" wsdd2"

configure_package() {
  #PKG_WAF_VERBOSE="-v"

  if [ "${AVAHI_DAEMON}" = yes ]; then
    PKG_DEPENDS_TARGET+=" avahi"
    SMB_AVAHI="--enable-avahi"
  else
    SMB_AVAHI="--disable-avahi"
  fi


  PKG_CONFIGURE_OPTS="--prefix=/usr \
                      --sysconfdir=/etc \
                      --localstatedir=/var \
                      --with-lockdir=/var/lock-samba \
                      --with-logfilebase=/var/log \
                      --with-piddir=/run/samba \
                      --with-privatedir=/run/samba \
                      --with-modulesdir=/usr/lib \
                      --with-privatelibdir=/usr/lib \
                      --with-sockets-dir=/run/samba \
                      --with-configdir=/run/samba \
                      --with-libiconv=${SYSROOT_PREFIX}/usr \
                      --cross-compile \
                      --cross-answers=${PKG_BUILD}/cache.txt \
                      --hostcc=gcc \
                      --enable-fhs \
                      --without-dmapi \
                      --disable-glusterfs \
                      --disable-rpath \
                      --disable-rpath-install \
                      --disable-rpath-private-install \
                      ${SMB_AVAHI} \
                      ${SMB_AESNI} \
                      --disable-cups \
                      --disable-iprint \
                      --with-relro \
                      --with-sendfile-support \
                      --without-acl-support \
                      --without-ads \
                      --without-ad-dc \
                      --without-automount \
                      --without-cluster-support \
                      --without-fam \
                      --without-gettext \
                      --without-gpgme \
                      --without-iconv \
                      --without-ldap \
                      --without-libarchive \
                      --without-pam \
                      --without-pie \
                      --without-regedit \
                      --without-systemd \
                      --without-utmp \
                      --without-winbind \
                      --enable-auto-reconfigure \
                      --bundled-libraries='ALL,!asn1_compile,!compile_et,!zlib' \
                      --without-quotas \
                      --with-syslog  \
                      --without-json \
                      --without-ldb-lmdb \
                      --nopyc --nopyo"

  PKG_SAMBA_TARGET="smbclient,client/smbclient,smbtree,nmblookup,testparm"

  if [ "${SAMBA_SERVER}" = "yes" ]; then
    PKG_SAMBA_TARGET+=",nmbd,rpcd_classic,rpcd_epmapper,rpcd_winreg,samba-dcerpcd,smbpasswd,smbd/smbd"
  fi
}

pre_configure_target() {
  cd ${PKG_BUILD}

  # --- VACINA SAMBA 4.24.0 vs GLIBC 2.43 & Kernel 3.14 ---

  # 1. Conserta o erro de digitação dos devs no uso do memset_explicit
  if [ -f "lib/replace/replace.c" ]; then
    sed -i 's/memset_explicit(dest, destsz, ch, count)/memset(dest, ch, count)/g' lib/replace/replace.c
  fi

  # 2. Injeta a estrutura FICLONERANGE que não existe no Kernel 3.14 para calar o compilador
  if [ -f "lib/replace/replace.h" ]; then
    cat << 'EOF' >> lib/replace/replace.h

/* Injeção forçada para Kernel antigo (3.14) */
#ifndef FICLONERANGE
#define FICLONERANGE 0x4020940d
struct file_clone_range {
    long long src_fd;
    unsigned long long src_offset;
    unsigned long long dest_offset;
    unsigned long long src_length;
};
#endif
EOF
  fi

  # 3. Proteção padrão GCC 15
  export CFLAGS="${CFLAGS} -Wno-error=incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

  # Work around link issues
  export LDFLAGS="${LDFLAGS} -lreadline -lncurses"

  rm -rf .${TARGET_NAME}

  # Support 64-bit offsets and seeks on 32-bit platforms
  if [ "${TARGET_ARCH}" = "arm" ]; then
    export CFLAGS+=" -D_FILE_OFFSET_BITS=64 -D_OFF_T_DEFINED_ -Doff_t=off64_t -Dlseek=lseek64"
  fi
}

configure_target() {
  # 1. Copia o cache base
  cp ${PKG_DIR}/config/samba4-cache.txt ${PKG_BUILD}/cache.txt
  
  # 2. Injeta as respostas que o Samba 4.20 exige (Blindagem total)
  echo "Checking uname machine type: \"${TARGET_ARCH}\"" >> ${PKG_BUILD}/cache.txt
  echo 'Checking for system libtasn1 (>=3.8): NO' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for declaration of krb5_pac_get_buffer: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for declaration of krb5_pac_get_buffer (as enum): NO' >> ${PKG_BUILD}/cache.txt
  echo 'Checking correct behavior of strtoll: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for C99 vsnprintf: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for HAVE_SHARED_MMAP: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for HAVE_MREMAP: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for HAVE_INCOHERENT_MMAP: NO' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for HAVE_SECURE_MKSTEMP: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for HAVE_IFACE_GETIFADDRS: OK' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for gnutls fips mode support: NO' >> ${PKG_BUILD}/cache.txt
  echo 'Checking for readlink breakage: NO' >> ${PKG_BUILD}/cache.txt
  echo 'Checking whether fcntl supports setting/getting hints: OK' >> ${PKG_BUILD}/cache.txt

  # 3. Ferramentas do Heimdal
  export COMPILE_ET=${TOOLCHAIN}/bin/heimdal_compile_et
  export ASN1_COMPILE=${TOOLCHAIN}/bin/heimdal_asn1_compile

  # 4. Configure
  PYTHON_CONFIG="${SYSROOT_PREFIX}/usr/bin/python3-config" \
  python_LDFLAGS="" python_LIBDIR="" \
  PYTHON=${TOOLCHAIN}/bin/python3 ./configure ${PKG_CONFIGURE_OPTS}
}

# Desativa o ICU manualmente (essencial para evitar erro de linkagem no Amlogic-old)
pre_make_target() {
  local CONFIG_H="bin/default/include/config.h"
  
  if [ -f "${CONFIG_H}" ]; then
    sed -e '/#define HAVE_ICU_I18N 1/d' \
        -e '/#define HAVE_LIBICUI.* 1/d' \
        -i "${CONFIG_H}"
  fi
}

make_target() {
  make ${PKG_SAMBA_TARGET} -j${CONCURRENCY_MAKE_LEVEL}
}

makeinstall_target() {
  PYTHONHASHSEED=1 WAF_MAKE=1 ./buildtools/bin/waf install ${PKG_WAF_VERBOSE} --destdir=${SYSROOT_PREFIX} --targets=smbclient -j${CONCURRENCY_MAKE_LEVEL}
  PYTHONHASHSEED=1 WAF_MAKE=1 ./buildtools/bin/waf install ${PKG_WAF_VERBOSE} --destdir=${INSTALL} --targets=${PKG_SAMBA_TARGET} -j${CONCURRENCY_MAKE_LEVEL}
}

copy_directory_of_links() {
  local _tmp link
  for link in "${1}/"*.so*; do
    if [ -L ${link} ]; then
      _tmp="$(readlink -m "${link}")"
      cp -P ${_tmp} ${2}
      cp -P ${_tmp}.* ${2} 2>/dev/null || true
    else
      cp -P ${link} ${2}
    fi
  done
}

perform_manual_install() {
  mkdir -p ${SYSROOT_PREFIX}/usr/lib
    copy_directory_of_links ${PKG_BUILD}/bin/shared ${SYSROOT_PREFIX}/usr/lib

  mkdir -p ${INSTALL}/usr/lib
    copy_directory_of_links ${PKG_BUILD}/bin/shared ${INSTALL}/usr/lib
    copy_directory_of_links ${PKG_BUILD}/bin/shared/private ${INSTALL}/usr/lib

  if [ "${SAMBA_SERVER}" = "yes" ]; then
    mkdir -p ${INSTALL}/usr/sbin
      cp -L ${PKG_BUILD}/bin/smbd ${INSTALL}/usr/sbin
      cp -L ${PKG_BUILD}/bin/nmbd ${INSTALL}/usr/sbin

    mkdir -p ${INSTALL}/usr/libexec/samba
      cp -PR bin/default/source3/rpc_server/samba-dcerpcd ${INSTALL}/usr/libexec/samba
      cp -PR bin/default/source3/rpc_server/rpcd_classic ${INSTALL}/usr/libexec/samba
      cp -PR bin/default/source3/rpc_server/rpcd_epmapper ${INSTALL}/usr/libexec/samba
      cp -PR bin/default/source3/rpc_server/rpcd_winreg ${INSTALL}/usr/libexec/samba
  fi
}

post_makeinstall_target() {
  perform_manual_install

  rm -rf ${INSTALL}/usr/bin
  rm -rf ${INSTALL}/usr/lib/python*
  rm -rf ${INSTALL}/usr/share/perl*
  rm -rf ${INSTALL}/usr/lib64

  mkdir -p ${INSTALL}/usr/lib/samba
    cp ${PKG_DIR}/scripts/samba-config ${INSTALL}/usr/lib/samba
    cp ${PKG_DIR}/scripts/samba-autoshare ${INSTALL}/usr/lib/samba
    cp ${PKG_DIR}/scripts/smbpasswd ${INSTALL}/usr/lib/samba

  if find_file_path config/smb.conf; then
    mkdir -p ${INSTALL}/etc/samba
      cp ${FOUND_PATH} ${INSTALL}/etc/samba
    mkdir -p ${INSTALL}/usr/config
      cp ${INSTALL}/etc/samba/smb.conf ${INSTALL}/usr/config/samba.conf.sample
  fi

  mkdir -p ${INSTALL}/usr/bin
    cp -PR bin/default/source3/client/smbclient ${INSTALL}/usr/bin
    cp -PR bin/default/source3/utils/smbtree ${INSTALL}/usr/bin
    cp -PR bin/default/source3/utils/nmblookup ${INSTALL}/usr/bin
    cp -PR bin/default/source3/utils/testparm ${INSTALL}/usr/bin

  if [ "${SAMBA_SERVER}" = "yes" ]; then
    mkdir -p ${INSTALL}/usr/bin
      cp -PR bin/default/source3/utils/smbpasswd ${INSTALL}/usr/bin

    mkdir -p ${INSTALL}/usr/lib/systemd/system
      cp ${PKG_DIR}/system.d.opt/* ${INSTALL}/usr/lib/systemd/system

    mkdir -p ${INSTALL}/usr/share/services
      cp -P ${PKG_DIR}/default.d/*.conf ${INSTALL}/usr/share/services
  fi
  
  chmod +x ${INSTALL}/usr/sbin/*
  chmod +x ${INSTALL}/usr/bin/*
  chmod +x ${INSTALL}/usr/sbin/*
  chmod +x ${INSTALL}/usr/lib/samba/*
  chmod +x ${INSTALL}/usr/libexec/samba/*
}

post_install() {
  enable_service samba-config.service

  if [ "${SAMBA_SERVER}" = "yes" ]; then
    enable_service nmbd.service
    enable_service smbd.service
  fi
}
