#!/bin/bash

# 1. Carregar o perfil do sistema para garantir que os caminhos das bibliotecas estão OK
. /etc/profile

# 2. Definir o local dos ficheiros de configuração (onde o teu post_install colocou)
export MOONLIGHT_CONF="/usr/config/moonlight/moonlight.conf"

# 3. Mapear o comando de fechar (função padrão do EmuELEC)
set_kill set "moonlight"

# 4. Executar o Moonlight Embedded
# Usamos -platform sdl porque compilaste com suporte SDL2 e GLES
# Ajustei para 720p 60fps, que é o limite estável do S905L
moonlight stream -720 -fps 60 -bitrate 10000 -platform sdl

# 5. Limpeza ao sair
set_kill unset "moonlight"