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
| `tools/quadros.sh [N] [saída]` | grava N quadros PNG da cena principal em modo `--demo` (Xvfb + Mesa) | mudança visível; depois **abrir** os PNG |
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
| `project.godot` | texto INI; editar à mão é normal. Chaves que **decidimos**: 320×180, `stretch/mode="viewport"`, `scale_mode="integer"`, filtro `0` (nearest), snap 2D ligado, `gl_compatibility` (também no mobile), `emulate_touch_from_mouse`, `import_etc2_astc=true` (**o export Android recusa sem ele**) |
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

- **Nitidez:** filtro padrão *nearest* (projeto), `snap_2d_transforms_to_pixel`
  e `snap_2d_vertices_to_pixel` ligados, ampliação **inteira** (320×180 ×4 =
  1280×720; em telas que não dividem, sobra borda — é o preço da nitidez).
- **Desenho por código:** `draw_polyline` de 1 px sai falhado nas diagonais com
  o snap (resíduo v0.1.0) — para traços, desenhar por pixel ou largura 2.
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
  `stretch/mode="viewport"` as posições já chegam em pixels de jogo (320×180).
- `emulate_touch_from_mouse=true`: no PC/oráculo o mouse vira toque.
- Toque roteirizado (oráculo/testes de cena): `Input.parse_input_event(ev)`.
- A classificação de gestos é da `sim/` (P3), testada com traços gravados.

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
   (a doc oficial lista também as `_DEBUG_*`).
5. Preset temporário com `version/code` = nº do run (cresce sempre: o Android
   só aceita atualizar para código maior) e `version/name` = `<versão do
   HISTORICO>-b<run>`.
6. `--export-release "Android"`; depois `aapt dump badging` confere pacote e
   versão.
7. Push em main → Release **`dev`** (pré-release, refeita a cada push);
   tag `v*` → Release da tag.

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

**Keystore:** `tools/android/galapago-dev.keystore` é de DESENVOLVIMENTO
(versionado, senha no script) — serve para o APK de teste instalar por cima do
anterior. A chave da **loja** será outra, gerada fora, guardada em *secret* do
GitHub, nunca no repositório. Trocar de chave obriga o operador a desinstalar.
O pacote `com.projetogalapago.jogo` é provisório — mudar depois também.
