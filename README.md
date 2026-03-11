# EmuELEC (Modificado - 3.14 + 4.8 Old Edition) 🚀

Emulação retrô para dispositivos Amlogic.
Baseado no [CoreELEC](https://github.com/CoreELEC/CoreELEC) e [Lakka](https://github.com/libretro/Lakka-LibreELEC) com elementos do [Batocera](https://github.com/batocera-linux/batocera.linux). Esta versão combina a estabilidade do **EmuELEC 3.14** com scripts e emuladores da versão **4.8 Nexus**, otimizada especificamente para chipsets **S905L** (Kernel 3.14 Legacy).

---
[![GitHub Release](https://img.shields.io/github/release/EmuELEC/EmuELEC.svg)](https://github.com/EmuELEC/EmuELEC/releases/latest)
[![GPL-2.0 Licensed](https://shields.io/badge/license-GPL2-blue)](https://github.com/EmuELEC/EmuELEC/blob/master/licenses/GPL2.txt)
[![Discord](https://img.shields.io/badge/chat-on%20discord-7289da.svg?logo=discord)](https://discord.gg/jQWCFwTn5T)

### ⚠️ **IMPORTANTE** ⚠️
#### O EmuELEC agora é apenas **aarch64**. A compilação e o uso da versão ARM (32 bits) após a versão 3.9 não são mais suportados. Por favor, consulte a branch `master_32bit` se desejar compilar a versão de 32 bits.

---

## 🧠 O Projeto: Kernel 3.14 Modificado
Este projeto nasceu da necessidade de manter hardware "Legacy" (Amlogic S905L) rodando tecnologias modernas. 

**Para que serve este Kernel?**
O Kernel 3.14 original da Amlogic possui drivers de vídeo estáveis, mas é tecnicamente limitado para padrões atuais. Nossa versão modificada serve como uma "ponte tecnológica":
* **Suporte Nativo a SquashFS XZ:** Modificamos as entranhas do Kernel para que ele entenda a compressão XZ. Sem isso, jogos modernos do **PortMaster** (como *Stardew Valley* e *Celeste*) simplesmente não montam e dão erro de "Invalid Argument".
* **Controle Total de Framebuffer:** Diferente dos Kernels mais novos (4.9+), este permite a troca dinâmica de resolução para 720p ou 480p, garantindo que a GPU Mali-450 não sofra com 1080p forçado.

**🚀 Compromisso de Atualização:**
Este repositório será mantido **mais atualizado que o EmuELEC oficial** no que diz respeito ao suporte para dispositivos antigos. Enquanto o projeto principal foca em novos chips, aqui faremos o *backport* de novos emuladores, scripts de otimização e correções de segurança especificamente para a arquitetura "Old Edition".

---

## ✨ Destaques Técnicos

* **PortMaster Fix:** Montagem de arquivos `.squashfs` funcionando perfeitamente.
* **Particionamento Inteligente:** * **Sistema (BOOT):** Travado em **2GB**.
    * **Dados (STORAGE):** Travado em **2GB**.
    * **ROMS (EEROMS):** Alocação automática de todo o restante do cartão SD.
* **Performance:** Scripts de CPU Governor configurados para extrair o máximo do Cortex-A53.

---

## 🛠️ Desenvolvimento

### Pré-requisitos de compilação
Estas instruções são destinadas apenas a sistemas baseados em Debian/Ubuntu.

```bash
sudo apt install gcc make git unzip wget xz-utils libsdl2-dev libsdl2-mixer-dev libfreeimage-dev libfreetype6-dev libcurl4-openssl-dev rapidjson-dev libasound2-dev libgl1-mesa-dev build-essential libboost-all-dev cmake fonts-droid-fallback libvlc-dev libvlccore-dev vlc-bin texinfo premake4 golang libssl-dev curl patchelf xmlstarlet default-jre xsltproc libvpx-dev rdfind tzdata xfonts-utils lzop

# Clone o repositório
git clone [https://github.com/felc18-blip/EMUELEC-3.14.git](https://github.com/felc18-blip/EMUELEC-3.14.git)
cd EMUELEC-3.14

# Para compilar a imagem otimizada para S905L (Amlogic-old):
PROJECT=Amlogic-ce DEVICE=Amlogic-old ARCH=aarch64 make image