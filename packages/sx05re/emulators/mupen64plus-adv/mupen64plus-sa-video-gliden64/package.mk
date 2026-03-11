# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="mupen64plus-sa-video-gliden64"
PKG_VERSION="85bdd452d7090f78a0f76d02121fa59ad079b7f6"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/gonetz/GLideN64"
PKG_URL="${PKG_SITE}.git"

PKG_DEPENDS_TARGET="toolchain boost libpng SDL2 SDL2_net zlib freetype nasm:host mupen64plus-sa-core"

PKG_SHORTDESC="mupen64plus-video-gliden64"
PKG_LONGDESC="Mupen64Plus Standalone GLideN64 Video Driver"
PKG_TOOLCHAIN="manual"


case ${DEVICE} in
  AMD64|RK3588|S922X|RK3399)
    PKG_DEPENDS_TARGET+=" mupen64plus-sa-simplecore"
  ;;
esac


case ${DEVICE} in
  AMD64)
    PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
    export USE_GLES=0
  ;;
  *)
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
    export USE_GLES=1
  ;;
esac


make_target() {

  export HOST_CPU=${TARGET_ARCH}
  export V=1
  export VC=0

  export BINUTILS="$(get_build_dir binutils)/.${TARGET_NAME}"
  export APIDIR=$(get_build_dir mupen64plus-sa-core)/src/api

  export SDL_CFLAGS="-I${SYSROOT_PREFIX}/usr/include/SDL2 -pthread -D_REENTRANT"
  export SDL_LDLIBS="-lSDL2_net -lSDL2"

  export CROSS_COMPILE="${TARGET_PREFIX}"


  case ${TARGET_ARCH} in
    arm|aarch64)
      export CFLAGS="${CFLAGS} -Ofast -mcpu=cortex-a53 -ftree-vectorize -fomit-frame-pointer -ffast-math -flto"
      export CXXFLAGS="${CXXFLAGS} -Ofast -mcpu=cortex-a53 -ftree-vectorize -fomit-frame-pointer -ffast-math -flto"
    ;;
  esac


  ./src/getRevision.sh


  cmake \
    -DAPIDIR=${APIDIR} \
    -DMUPENPLUSAPI=ON \
    -DUSE_GLES=ON \
    -DGLES2=ON \
    -DEGL=ON \
    -DGLX=OFF \
    -DNOHQ=ON \
    -DNEON_OPT=ON \
    -DGLIDEN64_BUILD_TYPE=Release \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="-lGLESv2 -lEGL" \
    -DCMAKE_SHARED_LINKER_FLAGS="-lGLESv2 -lEGL" \
    -S src -B projects/cmake


  make -C projects/cmake clean
  make -C projects/cmake


  cp projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so \
  projects/cmake/plugin/Release/mupen64plus-video-GLideN64-base.so


  if [ -d "$(get_build_dir mupen64plus-sa-simplecore)" ]; then

    export APIDIR=$(get_build_dir mupen64plus-sa-simplecore)/src/api

    cmake \
      -DAPIDIR=${APIDIR} \
      -DMUPENPLUSAPI=ON \
      -DUSE_GLES=ON \
      -DGLES2=ON \
      -DEGL=ON \
      -DGLX=OFF \
      -DNOHQ=ON \
      -DNEON_OPT=ON \
      -DGLIDEN64_BUILD_TYPE=Release \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER="${CC}" \
      -DCMAKE_CXX_COMPILER="${CXX}" \
      -DCMAKE_C_FLAGS="${CFLAGS}" \
      -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
      -DCMAKE_EXE_LINKER_FLAGS="-lGLESv2 -lEGL" \
      -DCMAKE_SHARED_LINKER_FLAGS="-lGLESv2 -lEGL" \
      -S src -B projects/cmake

    make -C projects/cmake

    cp projects/cmake/plugin/Release/mupen64plus-video-GLideN64.so \
    projects/cmake/plugin/Release/mupen64plus-video-GLideN64-simple.so

  fi
}



makeinstall_target() {

  UPREFIX=${INSTALL}/usr/local
  ULIBDIR=${UPREFIX}/lib/mupen64plus-adv
  USHAREDIR=${UPREFIX}/share/mupen64plus-adv

  mkdir -p ${ULIBDIR}

  cp projects/cmake/plugin/Release/mupen64plus-video-GLideN64-base.so \
   ${ULIBDIR}/mupen64plus-video-GLideN64.so
   
  chmod 0644 ${ULIBDIR}/mupen64plus-video-GLideN64.so


  if [ -f "projects/cmake/plugin/Release/mupen64plus-video-GLideN64-simple.so" ]; then

    cp projects/cmake/plugin/Release/mupen64plus-video-GLideN64-simple.so \
      ${ULIBDIR}

    chmod 0644 ${ULIBDIR}/mupen64plus-video-GLideN64-simple.so

  fi


  mkdir -p ${USHAREDIR}

  cp ini/GLideN64.ini ${USHAREDIR}/GLideN64.ini

  chmod 0644 ${USHAREDIR}/GLideN64.ini

}