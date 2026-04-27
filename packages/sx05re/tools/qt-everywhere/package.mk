# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="qt-everywhere"
PKG_VERSION="5.15.0"
PKG_SHA256="22b63d7a7a45183865cc4141124f12b673e7a17b1fe2b91e433f6547c5d548c3"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://qt-project.org"
PKG_URL="http://download.qt.io/archive/qt/${PKG_VERSION::-2}/${PKG_VERSION}/single/${PKG_NAME}-src-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="pcre2 zlib openssl"
PKG_SOURCE_DIR="${PKG_NAME}-src-${PKG_VERSION}"
PKG_LONGDESC="A cross-platform application and UI framework"

# NextOS: on Amlogic-old (Mali-450 + libmali blob, fbdev) we want a Qt that
# can actually render windows so packages like melonDS-sa can use it.
# Other devices keep the headless / static build (only Skyscraper CLI and
# the NoGUI Dolphin frontend depend on Qt there, and they don't need a
# QPA platform plugin).
if [ "${DEVICE}" = "Amlogic-old" ]; then
  # NextOS: ${OPENGLES} (libmali on Amlogic-old) provides libGLESv2/libEGL
  # which Qt's configure tests for when -opengl es2 -eglfs are enabled.
  PKG_DEPENDS_TARGET+=" ${OPENGLES} freetype libpng libjpeg-turbo libxkbcommon libevdev fontconfig"

  PKG_CONFIGURE_OPTS_TARGET="-prefix /usr
                             -sysroot "${SYSROOT_PREFIX}"
                             -hostprefix "${TOOLCHAIN}"
                             -device linux-libreelec-g++
                             -opensource -confirm-license
                             -release
                             -shared
                             -make libs
                             -force-pkg-config
                             -openssl-linked
                             -no-accessibility
                             -qt-sqlite
                             -no-sql-mysql
                             -system-zlib
                             -no-mtdev
                             -system-libjpeg
                             -system-libpng
                             -no-harfbuzz
                             -no-libproxy
                             -system-pcre
                             -no-glib
                             -silent
                             -no-cups
                             -no-iconv
                             -evdev
                             -no-tslib
                             -no-icu
                             -no-strip
                             -fontconfig
                             -no-dbus
                             -opengl es2
                             -no-libudev
                             -no-libinput
                             -eglfs
                             -system-freetype
                             -no-kms
                             -no-gbm
                             -linuxfb
                             -skip qt3d
                             -skip qtactiveqt
                             -skip qtandroidextras
                             -skip qtcanvas3d
                             -skip qtconnectivity
                             -skip qtdeclarative
                             -skip qtdoc
                             -skip qtgraphicaleffects
                             -skip qtlocation
                             -skip qtmacextras
                             -skip qtquickcontrols
                             -skip qtquickcontrols2
                             -skip qtscript
                             -skip qtsensors
                             -skip qtserialbus
                             -skip qttranslations
                             -skip qtwayland
                             -skip qtwebchannel
                             -skip qtwebengine
                             -skip qtwebsockets
                             -skip qtwebview
                             -skip qtwinextras
                             -skip qtx11extras
                             -skip qtxmlpatterns"
                             # NOTE: qtmultimedia is built so that consumers
                             # like melonDS-sa (which #include's <QCamera>
                             # transitively even when the camera feature is
                             # never used at runtime) can link.
else
  PKG_CONFIGURE_OPTS_TARGET="-prefix /usr
                             -sysroot "${SYSROOT_PREFIX}"
                             -hostprefix "${TOOLCHAIN}"
                             -device linux-libreelec-g++
                             -opensource -confirm-license
                             -release
                             -static
                             -make libs
                             -force-pkg-config
                             -openssl-linked
                             -no-accessibility
                             -qt-sqlite
                             -no-sql-mysql
                             -system-zlib
                             -no-mtdev
                             -qt-libjpeg
                             -qt-libpng
                             -no-harfbuzz
                             -no-libproxy
                             -system-pcre
                             -no-glib
                             -silent
                             -no-cups
                             -no-iconv
                             -no-evdev
                             -no-tslib
                             -no-icu
                             -no-strip
                             -no-fontconfig
                             -no-dbus
                             -no-opengl
                             -no-libudev
                             -no-libinput
                             -no-eglfs
                             -skip qt3d
                             -skip qtactiveqt
                             -skip qtandroidextras
                             -skip qtcanvas3d
                             -skip qtconnectivity
                             -skip qtdeclarative
                             -skip qtdoc
                             -skip qtgraphicaleffects
                             -skip qtimageformats
                             -skip qtlocation
                             -skip qtmacextras
                             -skip qtmultimedia
                             -skip qtquickcontrols
                             -skip qtquickcontrols2
                             -skip qtscript
                             -skip qtsensors
                             -skip qtserialbus
                             -skip qtsvg
                             -skip qttranslations
                             -skip qtwayland
                             -skip qtwebchannel
                             -skip qtwebengine
                             -skip qtwebsockets
                             -skip qtwebview
                             -skip qtwinextras
                             -skip qtx11extras
                             -skip qtxmlpatterns"
fi

configure_target() {
  QMAKE_CONF_DIR="qtbase/mkspecs/devices/linux-libreelec-g++"

  cd ..
  mkdir -p ${QMAKE_CONF_DIR}

  cat >"${QMAKE_CONF_DIR}/qmake.conf" <<EOF
MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental
QMAKE_INCREMENTAL_STYLE = sublib
include(../../common/linux.conf)
include(../../common/gcc-base-unix.conf)
include(../../common/g++-unix.conf)
load(device_config)
QMAKE_CC         = ${CC}
QMAKE_CXX        = ${CXX}
QMAKE_LINK       = ${CXX}
QMAKE_LINK_SHLIB = ${CXX}
QMAKE_AR         = ${AR} cqs
QMAKE_OBJCOPY    = ${OBJCOPY}
QMAKE_NM         = ${NM} -P
QMAKE_STRIP      = ${STRIP}
QMAKE_CFLAGS     = ${CFLAGS}
QMAKE_CXXFLAGS   = ${CXXFLAGS}
QMAKE_LFLAGS     = ${LDFLAGS}
load(qt_config)
EOF

  cat >"${QMAKE_CONF_DIR}/qplatformdefs.h" <<EOF
#include "../../linux-g++/qplatformdefs.h"
EOF

  unset CC CXX LD RANLIB AR AS CPPFLAGS CFLAGS LDFLAGS CXXFLAGS
  ./configure ${PKG_CONFIGURE_OPTS_TARGET}
}

post_makeinstall_target() {
  # Qt installs directly to ${SYSROOT_PREFIX} so don't rely on scripts/build fixing this up
  # PKG_ORIG_SYSROOT_PREFIX will be undefined when performing a legacy build
  sed -e "s:\(['= ]\)/usr:\\1${PKG_ORIG_SYSROOT_PREFIX:-${SYSROOT_PREFIX}}/usr:g" -i "${PKG_ORIG_SYSROOT_PREFIX:-${SYSROOT_PREFIX}}/usr/lib"/libQt*.la
}
