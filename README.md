# NextOS Elite Edition
**Performance Moderna para Hardware Legacy (Amlogic S905L)**

O **NextOS Elite Edition** é uma distribuição Linux de emulação retrô altamente otimizada para extrair o máximo de desempenho de dispositivos Amlogic antigos. Combinando a extrema estabilidade do kernel 3.14 com melhorias arquiteturais modernas da base Nexus (4.8), o sistema atua como uma ponte entre hardware legado e softwares atuais.

Projetado especificamente para dispositivos com o chipset **Amlogic S905L**.

---

## ⚠️ Importante: Arquitetura Exclusiva
O sistema é **exclusivamente aarch64 (64-bit)**. 
Versões ARM 32-bit não são suportadas nesta base para garantir a integridade de binários modernos. Para compatibilidade com builds muito antigos, utilize versões legacy específicas.

---

## 🎯 O Projeto e Visão Geral

Enquanto as distribuições *mainline* abandonam chipsets antigos, o NextOS tem o objetivo de manter a sobrevida e a funcionalidade do S905L através de uma reestruturação profunda do sistema base. Não se trata apenas de ajustes superficiais, mas de modernizar o núcleo do sistema operacional para rodar tecnologias de 2026 em hardware legacy.

Os pilares deste projeto incluem:
- **Toolchain de Última Geração:** Todo o sistema foi construído utilizando a toolchain mais moderna existente, garantindo compilação otimizada, código limpo e máxima compatibilidade.
- **Base Sólida 2026:** Mais de 200 pacotes do sistema foram completamente atualizados para suas versões mais recentes, criando um ambiente robusto, seguro e preparado para o futuro.
- **Backports Extremos:** Trazendo versões modernas de emuladores e da stack de software que normalmente exigiriam kernels muito mais recentes.
- **Otimizações Cirúrgicas:** Ajustes específicos para as limitações térmicas e de processamento do hardware antigo.

---

## 📦 Stack Tecnológico Exclusivo (Base Nexus 4.8)

A integração de softwares atuais no kernel 3.14 exigiu um trabalho pesado de engenharia e a criação de patches customizados. Esse esforço resultou em recursos avançados que, atualmente, são exclusivos do NextOS para este hardware:

- **Systemd 257.13 (Exclusividade):** Totalmente refeito do zero para o projeto. Garante um gerenciamento de serviços de inicialização incrivelmente rápido e eficiente, com padrões de 2026.
- **BlueZ 5.86:** Pilha de Bluetooth atualizada para a última versão, garantindo suporte e pareamento perfeito com os controles e gamepads mais modernos do mercado.
- **Samba 4.24.0:** Compartilhamento de rede de ponta. A integração deste pacote exigiu patches de alta complexidade para contornar as limitações do kernel 3.14, oferecendo transferências de rede rápidas e seguras.
- **SDL GLES 4:** Implementação avançada da camada SDL com suporte a OpenGL ES 4, otimizando drasticamente a comunicação entre os emuladores modernos e a GPU.

---

## ⚙️ Engenharia e Modificações do Kernel 3.14

O kernel original da Amlogic oferece uma base de hardware extremamente estável, mas impõe limitações técnicas severas para cargas de trabalho modernas. Para superar essa barreira, o kernel do **NextOS Elite Edition** foi profundamente reestruturado com uma série de patches customizados, correções de configuração e a introdução de novas funções:

### 1. Suporte a SquashFS XZ (PortMaster)
Implementação de suporte nativo à compressão **XZ** no kernel. Essa adição é o motor que permite a montagem e execução de aplicações modernas empacotadas em `.squashfs`. É um requisito absoluto para que o sistema consiga rodar nativamente títulos pesados do PortMaster, como *Celeste* e *Stardew Valley*.

### 2. Otimização de Frequência e Desempenho
Aplicamos correções rigorosas nas configurações internas do kernel (`defconfig`) para destravar o verdadeiro potencial do chip. Os ajustes finos no controle de frequência (CPU/GPU) e no gerenciamento de energia garantem o máximo de performance sustentada, evitando gargalos ou quedas bruscas de frames durante o uso de emuladores exigentes.

### 3. Patches Customizados e Backports
A base de código recebeu diversas melhorias e novas funções que ativam recursos antes indisponíveis no projeto original da Amlogic. Isso inclui a correção de drivers essenciais e a preparação do sistema para lidar com bibliotecas mais recentes com total estabilidade.

### 4. Controle Dinâmico e Estabilidade de Framebuffer
Sistema inteligente de gerenciamento de resolução, otimizado para extrair o máximo da GPU Mali-450 sem gerar gargalos térmicos:

- **480p:** Foco total em desempenho bruto (ideal para jogos pesados ou displays CRT).
- **720p:** Modo de equilíbrio (excelente balanço entre performance e qualidade visual).
- **1080i / 1080p:** Alta definição com estabilidade absoluta.

> *Graças às otimizações profundas aplicadas no kernel, foi possível superar as limitações térmicas originais do hardware. O sistema agora entrega uma experiência Full HD (1080p/1080i) totalmente estável, mantendo o overhead da GPU sob controle rigoroso.*

---

## 🚀 Destaques e Performance Absoluta

A sinergia entre a toolchain de ponta (GCC 15, glibc 2.43), o novo Systemd 257.13 e o kernel 3.14 profundamente patcheado eleva o **NextOS Elite Edition** a um patamar de desempenho inalcançável pela base do EmuELEC original. O sistema entrega tempos de inicialização drasticamente menores, estabilidade de framerate em emuladores pesados e uma fluidez de navegação que extrai o limite físico do hardware S905L.

- **Controle Gen (Autoconfiguração Dinâmica):** Implementação de um gerador de mapeamento inteligente. Ao plugar qualquer gamepad, o sistema cria automaticamente o perfil de controle. Isso garante que todos os jogos do PortMaster (que dependem das pontes gptokeyb e gptokeyb2) já saiam mapeados com o atalho universal "Select + Start" para encerrar a aplicação, eliminando a necessidade de configurações manuais tediosas.
- **Ecossistema PortMaster Atualizado:** Integração com a versão mais recente do PortMaster, usufruindo da montagem nativa em SquashFS XZ para garantir carregamento instantâneo e execução correta dos runtimes modernos.
- **Gerenciamento Térmico e de CPU:** O *governor* do processador foi otimizado para sustentar frequências altas em cargas pesadas, bloqueando o *throttling* térmico que costumava derrubar a performance no sistema original durante sessões longas.
- **Eficiência de RAM e I/O:** Melhorias agressivas no alocamento de memória e na leitura de disco. O sistema operacional base consome uma fração dos recursos originais, deixando praticamente toda a RAM livre e dedicada exclusivamente para a emulação e processos do SDL GLES 4.

---

## Desenvolvimento e Compilação

O ambiente de build foi totalmente migrado e otimizado para **Arch Linux**. A adoção de um sistema base *rolling release* permitiu a integração da toolchain mais moderna disponível atualmente, incluindo **GCC 15**, **glibc 2.43** e **glib2 2.88.0**.

Essa arquitetura de compilação garante um processo de build significativamente mais rápido e limpo, gerando binários altamente otimizados que traduzem em um sistema operacional notavelmente mais fluido e responsivo.

### 1. Pré-requisitos (Arch Linux)
Para preparar o ambiente host de compilação, instale os pré-requisitos utilizando o comando abaixo:

```bash
sudo pacman -Syu --needed base-devel git wget unzip xz sdl2 sdl2_mixer \
freeimage freetype2 curl rapidjson alsa-lib mesa boost cmake \
vlc texinfo go openssl patchelf xmlstarlet jre-openjdk \
libxslt libvpx rdfind lzop

## Projeto e Independência

NextOS Elite Edition é um projeto independente baseado no EmuELEC.

Este sistema não faz parte do projeto oficial EmuELEC e não possui qualquer vínculo com sua equipe, organização ou desenvolvimento.

Todo o desenvolvimento deste projeto é realizado de forma independente.

Este repositório não representa o EmuELEC oficial.
