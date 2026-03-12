#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile

# REMOVIDO o check de weston/sway para o script rodar no EmuELEC puro
# Mantemos a lógica de busca por dispositivo

case "${DEVICE}" in
  # Adicionamos o seu S905L na lógica de "Fixing"
  "Amlogic-old"|"S905"|"S905L")
    # No S905L, precisamos garantir que os ports usem a libmali do sistema
    # Excluímos jogos FNA pois eles costumam vir com libs próprias sensíveis
    for port in /storage/roms/ports/*.sh; do
      if ! grep -q FNA "$port"; then
        # Adaptamos o caminho do JELOS (/usr/lib/egl) para o padrão do EmuELEC (/usr/lib)
        sed -i '/get_controls/c\get_controls && export SDL_VIDEO_GL_DRIVER=/usr/lib/libGLESv2.so SDL_VIDEO_EGL_DRIVER=/usr/lib/libEGL.so' "$port"
        echo "Fixing (S905L): $port";
      fi
    done;
  ;;

  "S922X")
    # Mantemos a lógica original para o N2/S922X caso você use em outra box
    for port in /storage/roms/ports/*.sh; do
      if ! grep -q FNA "$port"; then
        sed -i '/get_controls/c\get_controls && export SDL_VIDEO_GL_DRIVER=/usr/lib/egl/libGL.so.1 SDL_VIDEO_EGL_DRIVER=/usr/lib/egl/libEGL.so.1' "$port"
        echo "Fixing (S922X): $port";
      fi
    done;
  ;;

  *)
    # Lógica "Limpadora" original do JELOS para outros dispositivos
    # Remove gl4es libs em dispositivos que suportam OpenGL nativo
    rm -rf /storage/roms/ports/*/lib*/libEGL*
    rm -rf /storage/roms/ports/*/lib*/libGL*
    
    for port in /storage/roms/ports/*.sh; do
      if grep -q SDL_VIDEO_GL_DRIVER "$port"; then
        sed -i '/^export SDL_VIDEO_GL_DRIVER/c\#export SDL_VIDEO_GL_DRIVER' "$port"
        sed -i '/^export SDL_VIDEO_EGL_DRIVER/c\#export SDL_VIDEO_EGL_DRIVER' "$port"
        echo "Cleaning: $port";
      fi
    done;

    # Remove o fix do S922X se existir
    for port in /storage/roms/ports/*.sh; do
      sed -i '/get_controls && export/c\get_controls' "$port"
    done;
  ;;
esac