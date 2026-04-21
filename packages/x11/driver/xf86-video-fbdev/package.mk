PKG_NAME="xf86-video-fbdev"
PKG_VERSION="0.5.1"
PKG_SHA256="9c2bc0fb9af092804138e8d5cb5627cabf2919ef60f0d1544a95c4ac2047f387"
PKG_LICENSE="MIT"
PKG_SITE="https://www.x.org/"
# Note a mudança na extensão para .tar.xz abaixo:
PKG_URL="https://www.x.org/releases/individual/driver/xf86-video-fbdev-${PKG_VERSION}.tar.xz"

PKG_DEPENDS_TARGET="toolchain xorg-server xterm liberation-fonts-ttf font-xfree86-type1 font-util font-misc-misc font-cursor-misc font-bitstream-type1 encodings matchbox-window-manager"

PKG_CONFIGURE_OPTS_TARGET="--enable-shared --disable-static"
