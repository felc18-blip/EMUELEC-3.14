# NextOS-Elite-Edition — LÖVE 2D rodando em Mali 450

**Data:** 22/04/2026
**Device alvo:** Amlogic S905 (Cortex-A53) + Mali 450 + NextOS-Elite-Edition

## Conquista principal

**LÖVE 11.5 agora funciona nativamente em GPUs Mali 400-series.** Isso significa que **Balatro e qualquer outro jogo feito em LÖVE 2D** (Mari0, Mindustry, Moonring, etc) rodam no nosso S905.

Até onde pesquisei, **não existe outro fork público de EmuELEC/CoreELEC rodando Balatro em Mali 450**. O problema do Mali 400-series com shaders do LÖVE é conhecido há anos sem solução documentada.

---

## Mudanças no buildsystem

### 1. Novo package: `love` (LÖVE 11.5)

**Local:** `packages/sx05re/emuelec-ports/love/`

- `package.mk` — compila LÖVE com `--enable-gles2` (GLES 2.0 nativo, sem gl4es intermediando)
- `patches/001-mali-force-highp.patch` — patch crítico pra Mali funcionar

Dependências: `toolchain SDL2 luajit openal-soft libvorbis libmodplug freetype harfbuzz libpng zlib`

### 2. Patch `001-mali-force-highp.patch` (o coração da correção)

**Arquivo afetado:** `src/modules/graphics/wrap_GraphicsShader.lua`

**O problema técnico:**
- Mali 400-series aceita sintaxe `highp` no fragment shader, mas **não define** `GL_FRAGMENT_PRECISION_HIGH`
- O LÖVE usa esse símbolo pra decidir: se definido, usa `highp`; senão usa `mediump`
- Resultado no Mali: vertex shader pega `highp`, fragment pega `mediump`
- O uniform `love_ScreenSize` fica com precisões diferentes entre vertex e fragment
- Link dos programas **falha** com `L0010 Uniform 'love_ScreenSize' differ on precision`

**A solução:**
```diff
Candidatos naturais pra portar: **Mari0**, **Mindustry Classic**, **Moonring**, **Cotton Candy Rhapsody**, **NaN Industries**, **Gravity Guy**, e muitos outros da comunidade LÖVE.

---

## Créditos

- **NextOS-Elite-Edition** fork por @felipe — integração, build, testes
- Comunidade **LÖVE 2D** (slime e outros) — framework + documentação de internals
- **PortMaster** — script base do Balatro + método de patching on-the-fly no `.love`
- **Peter Harris / ARM** — documentação sobre limitações do Mali-400 series
- **LocalThunk** — Balatro (jogo maravilhoso)
