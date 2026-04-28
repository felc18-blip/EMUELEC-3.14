# NextOS-Retro-Elite-Edition

**Performance moderna pra hardware legacy Amlogic S905/S905X/S905W**

Distribuição Linux de emulação retrô que combina kernel 3.14 vendor (única opção compatível com a GPU Mali-450 Utgard sem driver mainline) com toolchain e userspace de 2026 — `glibc 2.43`, `Python 3.14.4`, `GCC 15`, `systemd 257`, `u-boot 2026.04`, `SDL3 nativo`, `connman 2.0`. Roda emuladores standalone modernos (DuckStation-SA, Dolphin SA, touchhle-sa, melonDS) que **nunca rodaram nesse hardware** em distros oficiais.

[![Última release](https://img.shields.io/github/v/release/felc18-blip/NextOS-Elite-Edition?label=release&style=flat-square)](https://github.com/felc18-blip/NextOS-Elite-Edition/releases/latest)
[![Discord](https://img.shields.io/discord/?logo=discord&logoColor=white&label=Discord&style=flat-square)](https://discord.gg/vQH2ahS29)

---

## Hardware suportado

Foco principal: **Amlogic-old** (kernel 3.14 vendor + Mali-450 Utgard).

| Imagem (build target) | Compatível com |
|---|---|
| **Generic** | TV boxes genéricas S905, S905X, S905W |
| **LePotato** | Libre Computer AML-S905X-CC |
| **Odroid C2** | Hardkernel Odroid C2 |

Arquitetura **aarch64 (64-bit)** exclusivamente. Build híbrido carrega libs lib32 sob demand pra emuladores 32-bit.

---

## ⚡ Highlights da release atual

### Migração SDL3 NATIVA — completa

Driver Mali fbdev pra SDL3 desenvolvido in-tree (Mali Utgard não tem suporte upstream sem DRM — solução exclusiva NextOS):

- **EmulationStation** migrada pra SDL3 (`sdl3-clean` branch) — UI mais responsiva, input mais fluído
- **RetroArch** fork próprio: [`felc18-blip/RetroArch-nextos-sdl3`](https://github.com/felc18-blip/RetroArch-nextos-sdl3) (PR #18833 + 11 patches NextOS + 2 fixes específicos)
- **PPSSPPSA** + **SDL3_ttf** + **bennugd-monolithic** em SDL3 nativo
- **SDL3_mixer** 3.2.0 + **lib32-SDL3** + **lib32-SDL3_mixer**
- **sdl2-compat** mantém ABI SDL2 sobre SDL3 (apps antigos continuam rodando)
- `input_joypad_driver=sdl3` default no retroarch — latência menor que udev
- Auto-detect display resolution (SDL3 patch + check_res.sh EDID fallback)
- Patch ES3→ES2 fallback (cores libretro modernos rodam GLES2)

### Toolchain ~3 anos à frente do EmuELEC oficial

| Componente | NextOS | EmuELEC oficial |
|---|---|---|
| `glibc` | **2.43** | 2.32 |
| `Python` | **3.14.4** | 3.10 |
| `glib` | **2.88.0** | 2.74 |
| `GCC` | **15.x** | 12 |
| `systemd` | **257.13** | 250 |
| `u-boot` | **2026.04 mainline** | 2017 vendor |
| `ffmpeg` | **8.x** + postproc + x264 + x265 | 5.x |
| `connman` | **2.0** + patch transition mode | 1.42 |
| `wpa_supplicant` | **2.11** + SAE/SAE_PK/OWE/DPP | 2.10 |
| `SDL` | **SDL3 nativo** + sdl2-compat | SDL2 only |
| `kernel` | 3.14.29 (vendor — único Mali Utgard) | mesmo |

44+ pacotes upstream bumpados: samba 4.24.1, openssh 10.3p1, bluez 5.86, openvpn 2.7.2, cmake 4.3.2, libpng 1.6.58, harfbuzz 14.2.0, nss 3.123, libgcrypt 1.12.2, fluidsynth 2.5.4, pulseaudio 17.0, mesa, cairo, pixman, gstreamer, VLC, Kodi, etc.

---

## 🎮 Emuladores standalone exclusivos no Amlogic-old

Coisas que **NUNCA EXISTIRAM** em build EmuELEC oficial pra esse hardware:

| Emulador | Sistema | Status |
|---|---|---|
| **touchhle-sa** | iPhone OS / iOS | ✅ Port nosso do zero — Super Monkey Ball roda 30fps |
| **DuckStation-SA** | PSX | ✅ Primeira vez nesse hardware + settings.ini Amlogic-old |
| **Dolphin SA** | GameCube / Wii | ✅ GLES2 fallback + tighten Amlogic-old defaults |
| **melonDS SA** | NDS / DSi | ✅ Qt5 eglfs + software 3D (NSMB / Bomberman jogáveis) |
| **NanoBoyAdvance SA** | GBA cycle-accurate | ✅ Port pra Mali-450 |
| **DaedalusX64-SA** | N64 | ✅ Mali-450 GLES2 |
| **Yabasanshiro 1.5 + 1.11** | Saturn | ✅ 4 fixes VIDSoft + frame-skip CPU budget |
| **mednafen 1.32.1** | 24 sistemas retro | ✅ Hotkey Start+Select via gptokeyb (EXCLUSIVO NextOS) |
| **mupen64plussa** | N64 | ✅ Modernizado + GLideN64 funcional |
| **PPSSPPSA** | PSP | ✅ Migrado pra SDL3 nativo |
| **amiberry / amiberry-lite** | Amiga | ✅ |
| **eka2l1** (Symbian) | — | ⚠️ WIP, ainda não funciona |
| **ikemen-go** (M.U.G.E.N) | — | ⚠️ WIP, abre mas tela preta |

Plus 159 cores libretro instalados (NES, SNES, GB/GBC/GBA, MD, MS/GG, PCE, Atari, Lynx, NGP, WS, Coleco, Vectrex, Intellivision, Neo Geo, PSX, N64, Saturn, MAME, etc).

---

## 🎮 Ports nativos rodando em Mali-450

- **Ship of Harkinian** — Zelda OoT/MM PC port com gl4es shader hack pra ImGui em ES3
- **GTA III** (re3) com Mali 450 ES 2.0 rendering fixes
- **GTA Vice City** (reVC) usando nosro1/librw + re3 patches
- **GTA San Andreas** (Yavuz wrapper) rodando perfeito + libgles3-shim + nextos-joymap + ETC1 texdb
- **Dead Cells** com `libglsl-shim.so` (GLSL 310→100 + ASTC decode CPU)
- **LÖVE 11.5** com Mali 400-series fix
- **Plants vs Zombies ND** via gmloader-next
- **PortMaster** completo com hooks NextOS (alias EmuELEC, bgdi system swap, autoconfig gamepad)

---

## 🌐 Network

- **connman 2.0** + patch in-tree `connman-06-prefer-psk-over-sae-transition.patch` — reordena `key_mgmt = "WPA-PSK WPA-PSK-SHA256 SAE"` (PSK primeiro, SAE fallback). Resolve "invalid-key" loop em routers TP-Link/Mercusys/ASUS modernos com WPA2/WPA3 transition mode
- **wpa_supplicant 2.11** com `CONFIG_SAE`, `CONFIG_SAE_PK`, `CONFIG_OWE`, `CONFIG_DPP`, `CONFIG_IEEE80211W` habilitados
- **Bluetooth bluez 5.86** funcional + `emuelec-bluetooth` rewrite Python 3.14+ (scan_async, fix "no controller found")
- **wait-time-sync** com timeout limitado (fix tela bugando offline)

---

## 🎵 Audio

- **PulseAudio 17.0** restaurado em SDL3 stack (aarch64 + lib32)
- **HW detect fix** — `system.pa` adiciona `module-udev-detect` + HDMI default sink
- **openal-soft** com PulseAudio backend
- `audio_driver=pulse` default no retroarch (alsathread quebrava som + acelerava jogos)

---

## 🛠️ Engenharia kernel 3.14

O kernel original Amlogic-old é vendor antigo com limitações severas pra cargas modernas. NextOS aplica patches in-tree:

- **Suporte SquashFS XZ** — necessário pra montagem nativa de ports modernos do PortMaster (Celeste, Stardew Valley)
- **Otimização CPU/GPU governor** — destrava throttling térmico, sustenta frequências altas
- **Backports drivers** — Mali userland 32-bit + libMali execstack fix
- **Sysctl `debug.exception-trace=0`** — silencia register-dumps de syscalls modernos (statx, rseq, pidfd_open, close_range, faccessat2). Reduz ~99% do spam do journal
- **ext4 features** ajustadas pra compat (`-O ^orphan_file,^metadata_csum_seed`)

### Resoluções suportadas (HDMI auto-detect)

| Resolução | Foco |
|---|---|
| **480p** | Performance bruta (jogos pesados, displays CRT) |
| **720p** | Equilíbrio (recomendado) |
| **1080i / 1080p** | Alta definição com estabilidade |

---

## 🎬 EmulationStation

- Black Retro Scraper integrado (Skyscraper + ScreenScraper + IA PT-BR)
- Tema **art-book-next** atualizado
- ROM dirs adicionados: `3ds`, `gamecube`, `ngage`, `palm`, `ps2`, `vircon32`, `wii`, `mplayer`
- 142 sistemas configurados em `es_systems.cfg`

---

## 📥 Download

[Releases na GitHub](https://github.com/felc18-blip/NextOS-Elite-Edition/releases/latest) — imagens .img.gz (~1.5GB) com SHA256.

⚠️ Última release foi testada **apenas na imagem Generic** (S905 TV box). LePotato e Odroid C2 são compilados mas não testados fisicamente — reportem se rodarem.

---

## 🛠️ Desenvolvimento e compilação

Build environment otimizado pra **Arch Linux** (rolling release pra ter toolchain mais nova).

### Pré-requisitos (Arch Linux)

```bash
sudo pacman -Syu --needed base-devel git wget unzip xz sdl2 sdl2_mixer \
  freeimage freetype2 curl rapidjson alsa-lib mesa boost cmake \
  vlc texinfo go openssl patchelf xmlstarlet jre-openjdk \
  libxslt libvpx rdfind lzop python sshpass
```

### Clonar e buildar

```bash
git clone https://github.com/felc18-blip/NextOS-Elite-Edition.git
cd NextOS-Elite-Edition
PROJECT=Amlogic-ce DEVICE=Amlogic-old ARCH=aarch64 make image
```

Output em `target/NextOS-Retro-Elite-Edition-Amlogic-old.aarch64-VERSION-{Generic,LePotato,Odroid_C2}.img.gz`.

### Build de pacote único

```bash
PROJECT=Amlogic-ce DEVICE=Amlogic-old ARCH=aarch64 ./scripts/clean <package>
PROJECT=Amlogic-ce DEVICE=Amlogic-old ARCH=aarch64 ./scripts/build <package>
```

---

## 🔗 Links

- 📦 **Releases**: https://github.com/felc18-blip/NextOS-Elite-Edition/releases
- 🐛 **Issues**: https://github.com/felc18-blip/NextOS-Elite-Edition/issues
- 💬 **Discord**: https://discord.gg/vQH2ahS29
- 🍴 **RetroArch fork SDL3**: https://github.com/felc18-blip/RetroArch-nextos-sdl3

---

## 📜 Independência do projeto

**NextOS-Retro-Elite-Edition** é um projeto **independente** baseado em EmuELEC e LibreELEC, mas **não tem vínculo oficial** com nenhum dos dois projetos, suas equipes ou organizações.

Todo o desenvolvimento, patches e ports são realizados pela comunidade NextOS de forma independente. Este repositório não representa o EmuELEC oficial.

Créditos pela base original: [EmuELEC](https://github.com/EmuELEC/EmuELEC), [LibreELEC](https://github.com/LibreELEC/LibreELEC.tv), [CoreELEC](https://github.com/CoreELEC/CoreELEC).

---

## 🐛 Encontrou bug?

Estamos levando essa plataforma legacy ao **máximo possível** — bugs ao mudar tantos componentes ao mesmo tempo são esperados. Quanto mais reports a gente recebe, melhor a próxima release fica.

Abre [issue no GitHub](https://github.com/felc18-blip/NextOS-Elite-Edition/issues) ou entra no [Discord](https://discord.gg/vQH2ahS29).

**Você é parte desse projeto. 💚**
