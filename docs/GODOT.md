# Godot — como usar (guia do projeto)

> Godot **4.7.2**, renderizador **Mobile (Vulkan)** com fallback para
> Compatibility (OpenGL 3) desde o P24. Tudo aqui foi **medido
> neste projeto** em 2026-11-20 (o que não foi está marcado "não testado").
> Dúvida de API: `tools/godot-api.sh <Classe> [filtro]` — a referência oficial
> desta versão exata, sem depender de memória. Não "lembre" API do Godot 3:
> muita coisa mudou de nome.

## 1. Onde o Godot roda

| onde | o quê | limite |
|---|---|---|
| celular (proot aarch64) | `~/.local/share/godot/Godot_v4.7.2-stable_linux.arm64`, link `~/.local/bin/godot` — **fora do PATH dos shells do agente**: os scripts caem para `$HOME/.local/bin/godot`; use `$GODOT` para sobrepor | sem GPU: imagem só pelo oráculo em **prévia** (Compatibility/softpipe); Vulkan (lavapipe) **cai com sinal 4** aqui; sem SDK Android |
| CI (ubuntu-24.04 x86_64) | mesmo 4.7.2 (`GODOT_VERSION` no `ci.yml`) | testes, quadros em **Mobile/Vulkan** (lavapipe, `QUADROS_RENDER=vulkan`) e APK |
| operador | o APK no celular; opcionalmente o app oficial "Godot Editor" para Android | editor no Android: não testado neste projeto |

**Versão local e do CI andam juntas.** Subir o Godot = mudar `GODOT_VERSION`,
o binário local, `config/features` do `project.godot` e o nome
`editor_settings-4.7.tres` (em `tools/android/exportar.sh`) no mesmo lote.

**Renderizador** (decisão do operador, 2026-11-25, P24): `mobile` (Vulkan) é o
alvo do celular médio — o APK roda nele. Aparelho sem Vulkan cai para OpenGL 3
(Compatibility) por `rendering/rendering_device/fallback_to_opengl3=true`
(padrão `true` no 4.7.2, explícito no `project.godot`; o texto oficial cita só o
Forward+, mas a chave é do RenderingDevice). O renderizador real em execução é
`RenderingServer.get_current_rendering_method()`, não a configuração. A linha de
comando sobrepõe: `--rendering-method gl_compatibility|mobile|forward_plus` e
`--rendering-driver opengl3|vulkan` — é assim que o oráculo escolhe o modo
([`ORACULO`](ORACULO.md)).

## 2. As ferramentas do projeto (use estas, não o binário cru)

| comando | faz | quando |
|---|---|---|
| `tools/testes.sh` | `--import`, roda `testes/run.gd`, reprova `SCRIPT ERROR`, e passa **todo `.gd`** pelo parser (`--check-only`) | antes de todo commit |
| `tools/verificar.sh [--tudo] [arquivos]` | guardião + só os testes da área (mapa `res://`) + parser dos arquivos tocados; `--tudo` chama a suíte | durante a iteração |
| `tools/quadros.sh [N] [saída]` | grava N quadros PNG da cena principal em modo `--demo` (Xvfb + Mesa) | mudança visível; depois **abrir** os PNG |
| `node tools/quadros-referencia.mjs [--baixar]` | compara os quadros com os da última publicação (o CI chama); `--baixar` só traz a referência para `testes/baseline/` (fora do git) | o CI, sempre; local para olhar a referência |
| `node tools/preview.mjs --site` | monta `_site/` (GIF + quadros) para o Pages; o CI chama e publica o link no resumo do run | ensaio com `--dry` |
| `tools/estado.sh [--ci] [--metricas]` | versão, HEAD, Godot, último CI / taxa de vermelho e mediana | abrir a sessão e fechar o lote |
| `tools/godot-api.sh <Classe> [filtro]` | resume a API oficial 4.7.2 (estrutura do `--doctool` + textos da tag `4.7.2-stable`, em cache `~/.cache/galapago/`) | antes de usar classe/método que não está no projeto |
| `tools/godot-api.sh --buscar <membro>` | quais classes têm aquele membro | "onde fica o normal map?" |
| `tools/android/exportar.sh [build]` | exporta o APK (precisa JDK 17 + SDK: só no CI) | o CI chama; local só com SDK |
| `node tools/baixar-apk.mjs [tag]` | baixa o APK da Release (`dev` por padrão) para `/sdcard/Download/DSH-Go/` | entregar ao operador |
| `node tools/ci-log.mjs [run]` | passos que falharam + fim do log | CI vermelho |

## 3. Linha de comando do Godot (referência, conferida no `--help` 4.7.2)

| opção | uso aqui |
|---|---|
| `--headless` | sem janela nem áudio; obrigatório no celular e no CI |
| `--path .` | o projeto (pasta com `project.godot`) |
| `--import` | importa recursos e sai — rodar antes de testes/exports (gera `.godot/`) |
| `-s res://x.gd` | roda um script que `extends SceneTree` (ou `MainLoop`) — é como `testes/run.gd` funciona |
| `--check-only -s res://x.gd` | só analisa o script; **sai com código 1 em erro de parse** (testado) |
| `--write-movie q.png --fixed-fps 30 --quit-after N` | Movie Maker: grava quadros PNG numerados (precisa de render — ver ORACULO) |
| `--rendering-method gl_compatibility --rendering-driver opengl3` | o oráculo em prévia (local); em `vulkan`: `--rendering-method mobile --rendering-driver vulkan` |
| `--audio-driver Dummy --resolution WxH` | o que o oráculo usa |
| `--export-release "Android" caminho.apk` | export pelo preset de `export_presets.cfg` (`--export-debug` idem, template debug) |
| `--export-pack` / `--export-patch` | só o `.pck` / só o que mudou — não usamos ainda |
| `--doctool <dir>` | despeja a API (1076 classes) — **sem os textos** no binário de distribuição |
| `-- --demo` | argumentos depois de `--` vão para `OS.get_cmdline_user_args()` |

## 4. Arquivos do projeto: o que é cada um e como editar

| arquivo | regra |
|---|---|
| `project.godot` | texto INI; editar à mão é normal. Chaves que **decidimos** (v0.6.0): **720×1280 em retrato** (`window/handheld/orientation=1`), `stretch/mode="canvas_items"`, `aspect="expand"`, filtro `0` (nearest), snap 2D **desligado**, `config/version` + `galapago/build` (o export grava os reais), `rendering_method="mobile"` (também `.mobile`) + `rendering_device/fallback_to_opengl3=true` e `config/features` com `"Mobile"` (P24; era `gl_compatibility`), `emulate_touch_from_mouse`, `import_etc2_astc=true` (**o export Android recusa sem ele**) |
| `*.tscn` / `*.tres` | cena/recurso em texto (`format=3`). Editar à mão: cada `[ext_resource]` com `id` único referenciado por `ExtResource("id")`; nós com `parent="."`/caminho. Cenas grandes: preferir montar em código (`_ready`) a escrever `.tscn` gigantes à mão |
| `*.gd.uid` | id estável do script (Godot ≥ 4.4) — **versionar** |
| `*.import` | configuração de import de cada asset — **versionar** |
| `.godot/` | cache — **nunca** versionar (`.gitignore`) |
| `.gdignore` | pasta que o Godot ignora (usamos em `arte/fonte/`, o bruto da IA) |
| `export_presets.cfg` | presets de export; o `version/code`/`version/name` versionados são de mentira — o `exportar.sh` troca num preset temporário. Vulkan não pede opção no preset Android: a API 4.7.2 do `EditorExportPlatformAndroid` só tem `graphics/opengl_debug` nesse grupo (conferido no P24; o APK em aparelho real **não testado**) |

## 5. GDScript — convenções do projeto

- **Tipos estáticos** sempre (`var x := 0.0`, `func f(a: int) -> Vector2`).
- **Dependência por `preload`** em `const` (`const T := preload("res://sim/x.gd")`),
  não por `class_name`: funciona em `-s` sem cache de classes e no CI.
- **`sim/` é puro** ([`ARQUITETURA`](ARQUITETURA.md)): `extends RefCounted`,
  funções `static` ou objetos de dados; nada de `Node`, `Input`, `_process`.
- **Sorteio com semente:** `RandomNumberGenerator` com `seed` explícito,
  passado como argumento. Nunca `randf()`/`randi()` globais na `sim/`.
- **Teste:** `testes/test_<sistema>.gd`, `extends "res://testes/caso.gd"`,
  funções `test_*`, asserts `checar`, `igual`, `perto`, `perto_v`.
- Erro de script em GDScript **não lança exceção** — imprime e segue. Por isso o
  `testes.sh` reprova a saída com `SCRIPT ERROR` e faz o `--check-only` geral.

## 6. Pixel art no Godot

- **Mundo 3D + Pixel Pass** (P24, decisão do operador, 2026-11-25): o mundo é
  3D (`jogo/mundo3d/`), com câmera ortográfica orbital (`sim/camera3d.gd`) e o
  pixel art como **pós desligável** (`vista.pixel_pass`, botão PIXEL ART da
  HUD). **Padrão: desligado (3D liso)** desde a S5a; `--pixel` começa ligado
  (`--liso` é aceito e não muda nada). **Ligado:** SubViewport com altura
  `pixel_pass.altura_interna` (640) + 2 px de margem, sem MSAA, ampliado
  *nearest*; `pixel_pass.gdshader` quantiza (níveis por canal; LUT de paleta
  opcional, era do P6, descartado em 2026-11-26) e aplica Bayer 4×4 ancorado no mundo por
  `celula_trama`. **Snap:** a Camera3D vai para o foco arredondado no grid de
  texel (eixos direita/cima da câmera) e a imagem ampliada é deslocada de
  −`resto_px` × fator — cenário estável no deslocamento, movimento liso. No
  **giro** o tremor de pixel é inevitável (some ao parar). **Desligado:**
  SubViewport do tamanho **físico** da janela (`get_window().size`; o canvas
  é 720×1280 lógico e o Android ampliava para 1080×2400, serrilhando e
  borrando), desenhado com escala 1/k (k = físico/canvas): 1 px renderizado
  = 1 px da tela; reage a `size_changed`. **Comparação manual (v0.42.0):**
  CONFIG → **3D LISO** cicla 100/85/75/67/50%; **MSAA LISO** cicla 4×/2×/off,
  independentemente. Padrão de cada partida continua **100%/4×**, sem gravação,
  DRS ou ajuste automático. A redução é do próprio `sv.size`, com altura
  arredondada para cima e largura cobrindo o aspecto do canvas; composição
  **uniforme, centrada**, com <1 texel de overscan horizontal, sem distorcer a
  câmera nem as coordenadas do dedo. `scaling_3d_scale=1`: nenhum fator duplo.
  Status mostra pixels e percentuais efetivos por eixo; COPIAR REGISTRO separa
  a escolha do liso do modo aplicado. Troca/resize invalida síncrono o histórico
  e a janela parcial. HUD e mapa do chão mantêm suas resoluções. Pixel Pass
  suspende/desabilita os dois controles, conserva 640+margem/AA off/nearest e
  devolve as escolhas ao retornar ao liso. Raio do contorno usa **interno/canvas**;
  o método de profundidade MSAA é desligado com AA off. Na mata continua sem
  contorno de tela. FXAA avaliado e desligado (`vista.fxaa_liso`): na resolução física o MSAA cobre as bordas
  de geometria, as faixas do toon têm AA no shader, e o FXAA borraria os
  contornos e custaria um passe de tela cheia.
- **Sombra do sol** (S5a): com câmera **ortográfica** o Godot ignora
  `directional_shadow_max_distance` (`renderer_scene_cull.cpp`) e a sombra
  cobre a fatia near..far da câmera — por isso `vista.aplicar_camera` põe
  near/far justos ao chão visível (pela inclinação e `altura_mundo`) e o
  `fade_start` depois do último chão visível. `shadow_blur` 1 é obrigatório no
  Mobile: lá o bias direcional é multiplicado pelo blur (blur 0 = bias 0 =
  acne, as manchas nas copas); `shadow_bias` 0,06, `normal_bias` 2.
  `project.godot`: atlas direcional 4096 e `soft_shadow_filter_quality` 2
  (soft low) **iguais** na chave base (CI) e na `.mobile` (APK).
- **Materiais:** `toon.gdshader` (luz em faixas no `light()`, cada troca um
  `smoothstep` de meia-largura `fwidth(n)`·0,75 — AA analítico, ~1 px; o nível
  passa por `OUTPUT_IS_SRGB` porque o Compatibility soma luz em sRGB e o
  Mobile em linear). **Contorno** (S6): `contorno_tela.gdshader`, pós 3D
  pela profundidade num quad de tela cheia da vista (`vista.contorno`:
  QuadMesh 2×2, `POSITION = vec4(VERTEX.xy, 1, 1)`, `extra_cull_margin`
  16384, `hint_depth_texture`; NDC z por `CURRENT_RENDERER`). Linha = vizinho
  num disco de raio `raio` px MAIS PERTO por > `limiar` (0,25 unidade; começa
  em 0,08), descontada a inclinação local do plano (diferença de 1 px, o menor
  lado, vezes o offset INTEIRO do texel lido — o filtro é nearest); 16 amostras, cobertura = soma/3 (Pixel Pass: raio 1, soma/1). Raio
  liso = `vista.espessura_contorno` (4 px de canvas) × interno/canvas. A linha
  cai fora do objeto da frente e some no contato (base de tronco, ator,
  quina). **Vinco** (S7), no mesmo shader: linha onde a normal muda mais de
  `vista.limiar_vinco_graus` (75°; copa ≈ 51–58°, tronco 60°, borda do topo
  da pedra 68° ficam de fora), centrada no vinco, no anel de 0,55·raio: normal
  pela profundidade (centro pelo quadrante mais plano; amostra por 2
  vizinhos de 1 px para fora, descartada se um deles salta), só se o ponto do
  meio cai num dos dois planos e não é oclusão com folga — a quina desce até
  o chão e encontra o pé da parede, a rampa encosta na parede com linha.
  **MSAA (liso, `profundidade_msaa`):** a profundidade resolvida (Mobile:
  `VK_RESOLVE_MODE_MAX_BIT`, a sub-amostra mais perto; Forward+/OpenGL:
  média) dá ao pixel em cima da quina um chanfro de ~1 px fora dos dois planos,
  conforme o ângulo; usado nas diferenças, ele fazia a normal do centro
  híbrida e a linha da quina clareava no meio. No liso o centro vem de braços
  de 1 e 2 px para fora (sem o próprio pixel), com `zp` (plano no centro) na
  oclusão e no ponto do meio, e o ponto do meio tem folga de meio px de
  diferença de inclinação. Pixel Pass: 1 px, só o lado mais rasante (anel
  dos 8 vizinhos), centro pelas diferenças de 1 px. 53 leituras de
  profundidade por pixel no liso, 41 no Pixel Pass (eram 21). Lê a profundidade no Mobile (resolve de MSAA no
  `render_forward_mobile.cpp`) e no Compatibility (medido na prévia). A
  `casca.gdshader` (casca invertida, `cull_front`) fica de reserva: só com
  `Mat.modo_contorno = MODO_CASCA`. No mapa NATUREZA (o único desde
  2026-11-27) o contorno de tela fica DESLIGADO (`vista.contorno.layers = 0`).
  Ambiente/reflexo do `WorldEnvironment` desligados; a faixa baixa faz o papel
  de ambiente. Os três compilam no Mobile e no Compatibility (conferido no CI
  #108 em Vulkan).
- **Marcas no chão** (S5b): trilha, mira e áreas de perigo moram no
  **mapa do chão** (`jogo/mundo3d/chao.gd`): SubViewport 2D transparente,
  `UPDATE_ALWAYS`, que cobre o mapa + 1 célula de margem em vista de cima, com
  afim FIXA px da sim → texel (`chao.raiz`; escala = min(2, 2048 / lado) a
  texels inteiros por célula — Natureza: 32/32, 1536×2048). Desenho em px da
  sim, `antialiased=true`, sem câmera nem altura. O shader do **solo** (o da
  mata, `mata.ligar_chao`; era o `toon.gdshader` da ilha da Fundação) lê a
  textura pelo XZ do mundo (`chao_ret`), linear sem mipmap, e mistura no ALBEDO antes da luz (a sombra
  cai sobre o caminho), só em face para cima (normal y > ~0,7). A textura é
  **premultiplicada** (mix do canvas sobre fundo transparente; o shader divide
  por alfa) e sRGB (convertida a linear se `!OUTPUT_IS_SRGB`). Copas, paredes e
  atores passam por cima, em qualquer yaw e altura; com o Pixel Pass a marca
  é quantizada junto com o chão.
- **Tela lisa:** HUD, barra de giro e os **projéteis no ar** (tiro, cuspe:
  `efeitos_ar`/`perigos_ar` com `no_ar = true`) são 2D na resolução da tela
  (`antialiased=true`), por cima do 3D; os projéteis usam a afim
  `cam3d.chao_para_tela` como `transform` do nó pai (`sobre`) e `main.relevo`.
- **Import de PNG:** padrão do Godot 4 para texturas 2D é sem perda; manter
  mipmaps desligados para sprites. Conferir no `.import` gerado.
- **Animação de sprite:** `AnimatedSprite2D` + `SpriteFrames` (um `SpriteFrames`
  por criatura, uma animação por ação×direção). O spritesheet do PixelLab
  (`export_asset(format="spritesheet")`) traz o JSON com `cell_size` e
  `rows` — um script geraria o `SpriteFrames` a partir dele (era do P6,
  descartado em 2026-11-26).
- **Evolução por peças:** `Node2D` com `Sprite2D`/`AnimatedSprite2D` filhos
  (corpo, cabeça, asas, galhada) e `offset`/posição por ponto de encaixe.
  `Skeleton2D`/`Bone2D` existem para deformar polígonos — não testado aqui.
- **Paleta por shader** (envelhecimento, elemento): `ShaderMaterial` com
  `canvas_item` lendo uma textura-LUT de paleta (cor original → cor nova).
  Não desenhada (era do P6, descartado em 2026-11-26); validar no oráculo.
- **Partículas** (fogo, estática, gelo): `CPUParticles2D` é a aposta segura nos
  dois renderizadores (Mobile e o fallback Compatibility) e no oráculo; `GPUParticles2D` não testado.
- **Luz 2D:** `PointLight2D` + `CanvasTexture` (`diffuse_texture` +
  `normal_texture` do `create_normal_map` do PixelLab, convenção OpenGL).

## 7. Toque (o jogo não tem botão virtual)

- Ler em `_unhandled_input`: `InputEventScreenTouch` (`pressed`, `index` = dedo)
  e `InputEventScreenDrag` (`position`, `relative`, `velocity`).
  **Tela → chão (P24):** `main.mundo_de(tela)` / `tela_de(mundo)` usam
  `sim/camera3d.gd` (`tela_para_chao`/`chao_para_tela`, câmera SUAVE — é o que
  o jogador vê); ortográfica ⇒ afim exata, em qualquer yaw.
- **Barra de giro (P24):** faixa no topo da tela (`jogo/barra_giro.gd`,
  `CanvasLayer` 1, altura `main.ALTURA_BARRA`, bússola que anda com o yaw).
  Dedo que **desce** nela é da barra até subir (`main._toque_barra`, no
  `_input`, que consome o evento): o deslocamento horizontal vira
  `cam3d.girar_px` e nada chega a `dedo_*`, à pinça nem ao caminho. Dedo que
  desce fora segue o fluxo normal, mesmo se depois passar por ela; os dois
  convivem (multitoque). A demo gira ~120° por esse mesmo caminho.
- `emulate_touch_from_mouse=true`: no PC/oráculo o mouse vira toque.
- Toque roteirizado (oráculo/testes de cena): `Input.parse_input_event(ev)`.
- A classificação de gestos é da `sim/` (P3), testada com traços gravados.
- **v0.8 (multitouch):** `_unhandled_input` guarda os dedos por `ev.index` e
  chama `main.dedo_*`; o PRIMEIRO dedo é o caminho (origem congelada na
  descida: `_gesto_origem` + a afim inversa da câmera; cada ponto convertido
  com `desenho.ganho` e alimentando `corpo.tracar` a cada quadro). Enquanto
  desenha, o **mundo** roda em tempo lento (`planejamento`) e um véu escurece a
  tela. A rota é desenhada em `jogo/trilha.gd`. A **pinça** alterna as vistas
  `alta`/`intima` da câmera 3D.

## 8. Exportar para Android (P2) — como funciona e o que quebra

O job `apk` do `ci.yml`, via `tools/android/exportar.sh`:

1. JDK 17 (temurin) + SDK do runner (`ANDROID_HOME`, build-tools 34–37).
2. Templates: o `.tpz` oficial tem **1,2 GB**; extraímos só
   `android_release.apk` e `android_debug.apk` (o Godot exige os dois mesmo
   para release) para `~/.local/share/godot/export_templates/4.7.2.stable/`,
   em cache do Actions.
3. **Caminhos do JDK e do SDK vão no `editor_settings-4.7.tres`** — no 4.7 não
   há variável de ambiente para isso (o padrão gravado é `/root/Android/Sdk`).
4. Keystore pelas variáveis `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`
   (a doc oficial lista também as `_DEBUG_*`); no CI o arquivo vem do secret
   `ANDROID_KEYSTORE_B64` — o `exportar.sh` recusa rodar sem elas.
5. Preset temporário com `version/code` = nº do run (cresce sempre: o Android
   só aceita atualizar para código maior) e `version/name` = `<versão do
   HISTORICO>-b<run>`.
6. `--export-release "Android"`; depois `aapt dump badging` confere pacote e
   versão.
   O mesmo passo grava `config/version` e `galapago/build` num `project.godot`
   temporário — é o que o jogo mostra no título e o que o atualizador compara.
   O preset tem `permissions/internet=true` (o atualizador usa a rede) e
   `include_filter="*.json"` (mapas e metadados de tileset são lidos com
   `FileAccess`, não como recurso importado).
7. Publicação (commit `vX.Y.Z:` em main, ou dispatch com `publicar`) →
   Release **`dev`** (pré-release, refeita a cada publicação) com o APK e o
   `versao.json` (o manifesto do atualizador); tag `v*` → Release da tag.
   Commit comum não gera APK ([`BUILD.md`](BUILD.md)).

Fatos do 1º APK (CI #6): `com.projetogalapago.jogo`, `0.2.0-b6`, minSdk 24
(Android 7), targetSdk 36, 26 MB, assinatura conferida localmente
(`keytool -printcert -jarfile`) = SHA-256 do keystore de dev.

Armadilhas medidas:

| sintoma | causa | conserto |
|---|---|---|
| "ETC2/ASTC texture compression is required" | Android exige | `rendering/textures/vram_compression/import_etc2_astc=true` |
| "No export template found … android_debug.apk" | templates ausentes | passo de templates do CI |
| "A valid Java SDK path is required" / "Missing platform-tools" | editor settings | `exportar.sh` grava os caminhos |
| "cannot connect to daemon at tcp:5037" | o export tenta o `adb` | inofensivo |

**Keystore:** só nos secrets do CI e no cofre do operador — ver
[`BUILD.md`](BUILD.md#o-keystore-assinatura). Trocar de chave obriga o
operador a desinstalar. O pacote `com.projetogalapago.jogo` é provisório — mudar depois também.
