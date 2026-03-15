################################################################################
# OpenELEC / EmuELEC
################################################################################

PKG_NAME="yabasanshiro"
PKG_VERSION="7ae0de7abc378f6077aff0fd365ab25cff58b055"
PKG_GIT_CLONE_BRANCH="yabasanshiro"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"

PKG_SITE="https://github.com/libretro/yabause"
PKG_URL="$PKG_SITE.git"

PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"

PKG_SHORTDESC="YabaSanshiro libretro core"
PKG_LONGDESC="Sega Saturn emulator"

PKG_TOOLCHAIN="make"
GET_HANDLER_SUPPORT="git"

pre_configure_target() {

  SRC=$PKG_BUILD/yabause/src
  MK=$SRC/libretro/Makefile

  # remover renderer OpenGL
  rm -f $SRC/vidogl.c
  rm -f $SRC/ygl*

  # remover sistemas GL
  rm -rf $SRC/libretro-common/glsm
  rm -rf $SRC/libretro-common/glsym

  # remover vidogl das listas de compilação
  sed -i 's/vidogl.c//g' $MK
  sed -i 's/vidogl.c.o//g' $MK

  # substituir renderer
  sed -i 's/vidogl/vidsoft/g' $MK

  # remover módulos GL
  sed -i '/ygl/d' $MK
  sed -i '/glsm/d' $MK
  sed -i '/glsym/d' $MK
  sed -i '/rglgen/d' $MK

  # remover includes OpenGL
  find $SRC -name "*.c" -exec sed -i '/ygl.h/d' {} \;
  find $SRC -name "*.cpp" -exec sed -i '/ygl.h/d' {} \;

  # remover flags x86
  sed -i 's/-mfpmath=sse//g' $MK

  # remover flag OGL3
  sed -i 's/-D_OGL3_//g' $MK
}

make_target() {

  make -C yabause/src/libretro \
       platform=unix \
       HAVE_OPENGL=0 \
       HAVE_OPENGLES=0 \
       HAVE_OPENGLES3=0 \
       HAVE_GLSM=0 \
       HAVE_VULKAN=0 \
       HAVE_LIBGL=0 \
       FORCE_GLES=0
}

makeinstall_target() {

  mkdir -p $INSTALL/usr/lib/libretro
  cp yabause/src/libretro/yabasanshiro_libretro.so \
     $INSTALL/usr/lib/libretro/
}