# Godot — como usar (guia do projeto)

> Godot **4.7.2**, renderizador de compatibilidade. Tudo aqui foi **medido
> neste projeto** em 2026-11-20 (o que não foi está marcado "não testado").
> Dúvida de API: `tools/godot-api.sh <Classe> [filtro]` — a referência oficial
> desta versão exata, sem depender de memória. Não "lembre" API do Godot 3:
> muita coisa mudou de nome.

## 1. Onde o Godot roda

| onde | o quê | limite |
|---|---|---|
| celular (proot aarch64) | `~/.local/share/godot/Godot_v4.7.2-stable_linux.arm64`, link `~/.local/bin/godot` — **fora do PATH dos shells do agente**: os scripts caem para `$HOME/.local/bin/godot`; use `$GODOT` para sobrepor | sem GPU: imagem só pelo oráculo (softpipe); sem SDK Android |
| CI (ubuntu-24.04 x86_64) | mesmo 4.7.2 (`GODOT_VERSION` no `ci.yml`) | testes, quadros (llvmpipe) e APK |
| operador | o APK no celular; opcionalmente o app oficial "Godot Editor" para Android | editor no Android: não testado neste projeto |

**Versão local e do CI andam juntas.** Subir o Godot = mudar `GODOT_VERSION`,
o binário local, `config/features` do `project.godot` e o nome
`editor_settings-4.7.tres` (em `tools/android/exportar.sh`) no mesmo lote.

## 2. As ferramentas do projeto (use estas, não o binário cru)

| comando | faz | quando |
|---|---|---|
| `tools/testes.sh` | `--import`, roda `testes/run.gd`, reprova `SCRIPT ERROR`, e passa **todo `.gd`** pelo parser (`--check-only`) | antes de todo commit |
| `tools/verificar.sh [--tudo] [arquivos]` | guardião + só os testes da área (mapa `res://`) + parser dos arquivos tocados; `--tudo` chama a suíte | durante a iteração |
| `tools/quadros.sh [N] [saída]` | grava N quadros PNG da cena principal em modo `--demo` (Xvfb + Mesa) | mudança visível; depois **abrir** os PNG |
| `node tools/quadros-baseline.mjs --run <id>` | baixa o artefato `baseline` do CI e aplica em `testes/baseline/` | lote visível, antes do commit |
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
| `--rendering-driver opengl3 --audio-driver Dummy --resolution WxH` | o que o oráculo usa |
| `--export-release "Android" caminho.apk` | export pelo preset de `export_presets.cfg` (`--export-debug` idem, template debug) |
| `--export-pack` / `--export-patch` | só o `.pck` / só o que mudou — não usamos ainda |
| `--doctool <dir>` | despeja a API (1076 classes) — **sem os textos** no binário de distribuição |
| `-- --demo` | argumentos depois de `--` vão para `OS.get_cmdline_user_args()` |

## 4. Arquivos do projeto: o que é cada um e como editar

| arquivo | regra |
|---|---|
| `project.godot` | texto INI; editar à mão é normal. Chaves que **decidimos** (v0.6.0): **720×1280 em retrato** (`window/handheld/orientation=1`), `stretch/mode="canvas_items"`, `aspect="expand"`, filtro `0` (nearest), snap 2D **desligado**, `config/version` + `galapago/build` (o export grava os reais), `gl_compatibility` (também no mobile), `emulate_touch_from_mouse`, `import_etc2_astc=true` (**o export Android recusa sem ele**) |
| `*.tscn` / `*.tres` | cena/recurso em texto (`format=3`). Editar à mão: cada `[ext_resource]` com `id` único referenciado por `ExtResource("id")`; nós com `parent="."`/caminho. Cenas grandes: preferir montar em código (`_ready`) a escrever `.tscn` gigantes à mão |
| `*.gd.uid` | id estável do script (Godot ≥ 4.4) — **versionar** |
| `*.import` | configuração de import de cada asset — **versionar** |
| `.godot/` | cache — **nunca** versionar (`.gitignore`) |
| `.gdignore` | pasta que o Godot ignora (usamos em `arte/fonte/`, o bruto da IA) |
| `export_presets.cfg` | presets de export; o `version/code`/`version/name` versionados são de mentira — o `exportar.sh` troca num preset temporário |

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

- **Arte pixelada, tela não** (decisão do operador, v0.3.0; **retrato desde a
  v0.6.0**): a tela é 720×1280 (`canvas_items`, `expand`, orientação 1 =
  retrato); a arte usa filtro *nearest*. A câmera nasceu com **zoom inteiro**
  (2 → cada pixel de arte vira 2×2) e desde a **v0.11.4** está em **1,6**
  (`jogo/mock.gd`, pedido do operador para ver mais do mapa): o pixel de arte
  passa a ocupar 1–2 px de tela — no xadrez do mock não se nota, e com a arte
  real (P6) é decisão a tomar (arte em 2× ou zoom inteiro).
  Linhas, sombras, efeitos e texto são desenhados na resolução da tela, lisos:
  `draw_polyline(..., antialiased=true)`, `draw_circle(..., antialiased=true)`,
  `draw_arc(..., antialiased=true)`. Snap 2D desligado: movimento em subpixel.
- **Zoom não inteiro** (pinça, efeito) borra/deforma pixels de arte: o 1,6 da
  v0.11.4 é o caso vivo disso. Alternativas quando a arte real chegar: desenhar
  a arte em 2× (32→64) e voltar a um zoom inteiro, ou aceitar o 1,6.
- **Import de PNG:** padrão do Godot 4 para texturas 2D é sem perda; manter
  mipmaps desligados para sprites. Conferir no `.import` gerado.
- **Animação de sprite:** `AnimatedSprite2D` + `SpriteFrames` (um `SpriteFrames`
  por criatura, uma animação por ação×direção). O spritesheet do PixelLab
  (`export_asset(format="spritesheet")`) traz o JSON com `cell_size` e
  `rows` — o P6 cria um script que gera o `SpriteFrames` a partir dele.
- **Evolução por peças:** `Node2D` com `Sprite2D`/`AnimatedSprite2D` filhos
  (corpo, cabeça, asas, galhada) e `offset`/posição por ponto de encaixe.
  `Skeleton2D`/`Bone2D` existem para deformar polígonos — não testado aqui.
- **Paleta por shader** (envelhecimento, elemento): `ShaderMaterial` com
  `canvas_item` lendo uma textura-LUT de paleta (cor original → cor nova).
  A desenhar no P6; validar no oráculo.
- **Partículas** (fogo, estática, gelo): `CPUParticles2D` é a aposta segura no
  renderizador de compatibilidade e no oráculo; `GPUParticles2D` não testado.
- **Luz 2D:** `PointLight2D` + `CanvasTexture` (`diffuse_texture` +
  `normal_texture` do `create_normal_map` do PixelLab, convenção OpenGL).

## 7. Toque (o jogo não tem botão virtual)

- Ler em `_unhandled_input`: `InputEventScreenTouch` (`pressed`, `index` = dedo)
  e `InputEventScreenDrag` (`position`, `relative`, `velocity`). Com
  câmera, converter para o mundo com `mundo.make_input_local(ev).position`
  (`mundo` = o Node2D raiz do mundo) — é o que `jogo/main.gd` faz.
- `emulate_touch_from_mouse=true`: no PC/oráculo o mouse vira toque.
- Toque roteirizado (oráculo/testes de cena): `Input.parse_input_event(ev)`.
- A classificação de gestos é da `sim/` (P3), testada com traços gravados.
- **v0.8 (multitouch):** `_unhandled_input` guarda os dedos por `ev.index` e
  chama `main.dedo_*`; o PRIMEIRO dedo é o caminho (origem congelada na
  descida: `_gesto_origem` + `canvas_transform` inverso; cada ponto convertido
  com `desenho.ganho` e alimentando `corpo.tracar` a cada quadro) e os dedos
  EXTRAS fazem a ação (cima = ataque, baixo = defesa, abrindo = especial).
  Enquanto desenha, o **mundo** roda em tempo lento (`planejamento`) e um véu
  escurece a tela. A rota é desenhada em `jogo/trilha.gd`.

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
7. Push em main → Release **`dev`** (pré-release, refeita a cada push) com o
   APK e o `versao.json` (o manifesto do atualizador); tag `v*` → Release da tag.

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
