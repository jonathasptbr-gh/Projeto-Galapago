# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

## v0.2.0 — APK no CI (P2) + catálogo do PixelLab e guias (2026-11-20)

- **P2:** job `apk` no `ci.yml` (depois de `testes`): JDK 17 (temurin), Godot
  4.7.2, templates Android extraídos do `.tpz` de 1,2 GB e guardados em cache
  (`android_debug.apk`, `android_release.apk`), `tools/android/exportar.sh`
  (import → editor settings com `java_sdk_path`/`android_sdk_path` → preset
  temporário com `version/code` = nº do run → `--export-release "Android"` →
  `aapt`/`apksigner` conferem). Publica Release `dev` (pré-release refeita a
  cada push em main) e Release por tag `v*`.
- `export_presets.cfg`: Android, só arm64-v8a, sem Gradle,
  `com.projetogalapago.jogo` (provisório), imersivo, paisagem (do projeto).
  Validado localmente: o Godot lê o preset e só reclama do que falta aqui
  (templates, JDK, SDK) — os mesmos três que o CI fornece.
- Keystore de DESENVOLVIMENTO versionado (`tools/android/galapago-dev.keystore`,
  PKCS12, alias `galapago`): assina builds de teste para que cada APK instale
  por cima do anterior. A chave da loja será outra, em *secret*.
- `tools/baixar-apk.mjs`: baixa o APK de uma Release (privada) para
  `/sdcard/Download/DSH-Go/`.
- CI #5 vermelho → `import_etc2_astc=true` (o export Android recusa sem ETC2/ASTC);
  CI #6 verde: `com.projetogalapago.jogo` `0.2.0-b6`, minSdk 24, targetSdk 36,
  26 MB; assinatura conferida localmente = SHA-256 do keystore de dev. APK
  entregue em `/sdcard/Download/DSH-Go/projeto-galapago-dev.apk`.
- **Catálogo PixelLab da fonte:** `tools/pixellab-catalogo.mjs` (MCP
  `tools/list` + `resources/list`/`read`) → `docs/pixellab/CATALOGO.md`
  (140 ferramentas em 11 categorias), `ferramentas.json` (esquemas completos),
  `recursos/` (7 guias oficiais, 3 de Godot). Diff servidor × ferramentas
  visíveis na sessão: idêntico (140 = 140).
- **Guias:** `docs/PIXELLAB.md` (ferramenta por tarefa do jogo, custos, o que o
  trial não tem: Tier 1 = tiles/salas pro, edit_animation, transfer_outfit…;
  Tier 2 = música e som), `docs/GODOT.md` (CLI conferida no `--help`, arquivos,
  convenções, pixel art, toque, export Android e armadilhas), `docs/BUILD.md`
  (o rito; o `ci.yml` já o citava sem existir).
- **Ferramentas:** `tools/godot-api.sh` (API 4.7.2 offline: estrutura do
  `--doctool` + textos da tag `4.7.2-stable` em cache), `tools/ci-log.mjs`,
  e `tools/testes.sh` passa a rodar `--check-only` em todo `.gd` (testado:
  reprova erro de parse com código 1).
- Ambiente: JDK 17 no celular (para `keytool`); o `dpkg` só configura com
  `/usr/share/man/man1` existente (imagem enxuta). `~/.local/bin` NÃO está no
  PATH dos shells do agente: os scripts já caem para `$HOME/.local/bin/godot`.

## v0.1.1 — PixelLab conectado, P1 (2026-11-20)

- Chave do operador (chegou pelo chat) → cofre `refs.PIXELLAB_TOKEN`; validada
  antes de configurar (MCP `initialize` + `tools/list` = 140 ferramentas +
  `get_balance`: trial, 40 gerações).
- Entrada `mcp-pixellab` no `cordis.patch.yml` do perfil web (backup em
  `~/tmp/cordis.patch.yml.bak-20261120-1552`); cabeçalho por `!!js` que lê o
  cofre. Conferida por `dsh web --dump-config` e pela avaliação do `!!js` fora
  do motor. Recarga a quente: as ferramentas vieram na mesma sessão.
- Prova: `create_image_pixen` 64×64, vista lateral, seed 20261120 →
  `arte/fonte/p1-cao-base-pixen.png` (64 cores, fundo transparente). 1 geração.
- `docs/ARTE.md`: como a conexão é feita, como trocar a chave, tabela de custo.
- Ambiente: Pillow instalado por pip (inspeção de PNG em script).

## v0.1.0 — esqueleto (2026-11-20)

- Repositório privado `jonathasptbr-gh/Projeto-Galapago` criado; motor
  **Godot 4.7.2** (renderizador de compatibilidade, 320×180 inteiro) e arte
  via **PixelLab MCP** — decisões do operador.
- Viabilidade medida antes de decidir: Godot arm64 renderiza neste celular sob
  Xvfb com Mesa **softpipe** (llvmpipe: SIGILL no JIT do proot; GLES sem EGL).
  Daí o oráculo `tools/quadros.sh` (Movie Maker, `--write-movie`).
- `sim/trajetoria.gd` (amostrar, comprimento, ponto_em) + 4 testes;
  executor `testes/run.gd` + `tools/testes.sh` (reprova também SCRIPT ERROR —
  controle negativo feito: falha proposital e erro de script reprovaram).
- Cena viva `jogo/main.tscn`: risca → a criatura provisória segue; `--demo`
  roteiriza o traço para o oráculo.
- CI `ci.yml`: Godot x86_64, testes, quadros como artefato. APK fica para P2.
- Docs: `AGENTS.md` (contrato), `CONCEITO`, `ARQUITETURA`, `ORACULO`, `ARTE`,
  `AMBIENTE`, fila `PEDIDOS-EM-ESPERA` (P1–P8), `RESIDUOS`.
