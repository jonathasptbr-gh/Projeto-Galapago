# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

## v0.5.0 — movimento com rota + autonomia, alvos e atualizador consertado (2026-11-20)

- **Atualização (relato do operador):** só funcionou baixando à mão. Medido: o
  manifesto e o `galapago/build` estavam certos; o defeito era **quando**
  verificar — só no arranque a frio, e o Android mantém o app vivo. Agora
  verifica ao abrir, **ao voltar do segundo plano**, de 5 em 5 min, e por botão
  ("Verificar atualização"); o estado fica **visível** na HUD; duas fontes
  (manifesto e API da Release) com nova tentativa; e um botão persistente
  "ATUALIZAR" que não depende de o aviso ser visto.
- **Movimento redesenhado (regra do operador):** rota e ações **andam
  juntas**. Ataque, esquiva e pulo são OVERLAYS que não cancelam a rota; a
  esquiva desloca e volta; o pulo é arco enquanto ela segue; a defesa PARALISA
  sem apagar; só uma rota nova substitui. Arrasto perto dela = rota (mesmo
  rápido); longe = gesto de ação (frente = ataque; lados = esquiva).
- **Alvos:** toque trava/solta a mira em árvore ou adversário (posição
  re-resolvida: mira em alvo MÓVEL); o ataque vai na direção do alvo, ou da
  rota sem alvo; baú interage.
- **Autonomia:** ao fim da rota, fica parada, vagueia devagar ou vai/ronda o
  alvo marcado — sorteio **semeado** (determinístico).
- **Adversário de teste** (`sim/adversario.gd`): vagueia sem reagir, sem dano,
  sem contato; determinístico por semente; não entra na água.
- `sim/corpo.gd` reescrito; `sim/alvos.gd` e `sim/adversario.gd` novos; HUD
  mostra versão, estado da atualização, rota/autonomia, alvo e camada.
- **Testes:** 49 verdes (rota, overlays sem cancelar rota, defesa para/retoma,
  alvo móvel, autonomia determinística e dentro do mapa, escavação). Parser: 35 scripts limpos.
- Defeito real encontrado e corrigido: no quadro em que a rota terminava, o
  código limpava `rota` e depois lia a posição dela — a criatura ia para
  (0,0). Agora a posição final é calculada antes de limpar.

## v0.4.0## v0.4.0 — a fundação: gestos, ações e camadas (2026-11-20)

- **Escala confirmada (captura do operador = análise):** criatura 64×64 px de
  arte, célula 32 px, câmera 2×. A "impressão de grande" é a ampliação
  (64 × 2 × ~1,64 da tela real), não a resolução.
- **Gestos** (`sim/gestos.gd`, tempo simulado = determinístico): toque, toque
  duplo, segurar, deslize, trajetória; limiares em `dados/gestos.json`.
- **Gestos → comandos** (`sim/comandos.gd`): deslize por SETOR relativo ao
  OLHAR da criatura (frente-esquerda → `ataque_x`, frente → `investida`,
  frente-direita → `ataque_y`, trás → `esquiva`); tabela em `dados/gestos.json`
  (a legenda da HUD e a demo seguem ela).
- **Ações** (`sim/corpo.gd` + `dados/acoes.json`): máquina com
  antecipação/ativa/recuperação, recarga, sustentada (defender), pulo e
  deslocamento consultam o mundo (não atravessam parede, pulo pousa só onde
  dá), escavar troca a camada.
- **Mundo em camadas** (`sim/mundo.gd` + `dados/terrenos.json` +
  `dados/mapas/fundacao.json`): superfície (terreno por célula, altura, andável,
  escavável, rampa 1,5) e subsolo (túneis); andar vence 0,5 nível, pulo sobe 1,
  escavação desce/sobe.
- **Visibilidade** (`sim/visibilidade.gd`): copa opaca de longe, quase
  transparente com a criatura por baixo (smoothstep) — baú escondido no bosque.
- **Apresentação em MOCKUP de xadrez** (`jogo/mock.gd`, `jogo/camadas/`):
  parallax fundo (0,35×) e frente (1,35×), chão com paredes e buracos, objetos
  y-sort pela base, subsolo que escurece a cena, copas acima de tudo, HUD de
  desenvolvimento com a legenda gerada da tabela.
- **Demo roteirizada** (`jogo/demo.gd`): sintetiza DEDOS (não comandos) e passa
  pelo fluxo real; cobre trajetória, os 3 deslizes, toque duplo (pulo sobre o
  canal), segurar (defender), escavação (desce, anda no túnel, sobe) e bosque.
- **Verificação:** 43 testes (gestos, comandos, corpo, mundo, visibilidade),
  parser em 30 scripts; demo 450 quadros a 15 fps SEM erro de script; camadas
  conferidas por amostragem de pixels (superfície verde/cinza/azul, subsolo
  escuro). O modelo desta sessão não lê imagem → verificação visual programática.
- GDDs novos: [`docs/gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md) e
  [`docs/gdd/mapa.md`](gdd/mapa.md) reescrito para as camadas.

## v0.3.1## v0.3.1 — atualização pelo método do IASD; repositório público (2026-11-20)

- O operador recusou o canal separado (link para o navegador, login no GitHub)
  e pediu o método do Áudio Visual IASD com o repositório público. Feito:
  `ShellUpdater.kt` do IASD lido e replicado em Godot — manifesto
  `versao.json` como asset da Release `dev`, download DENTRO do app com barra,
  tamanho conferido, instalador do sistema via `OS.shell_open(arquivo)`
  (conferido no `GodotIO.java` 4.7.2: `FileProvider` `<pacote>.fileprovider`).
  Permissão `REQUEST_INSTALL_PACKAGES` por `custom_permissions` (não está na
  lista do Godot). `sim/atualizacao.gd`: host travado, teto de 300 MB,
  `download_completo` (6 testes).
- **Antes de abrir o repositório:** histórico inteiro auditado (10 commits) —
  sem token/chave; a única coisa sensível era o keystore de dev + senha.
  Keystore NOVO (RSA 3072, senha aleatória) só em secrets
  (`ANDROID_KEYSTORE_B64`/`_SENHA`) e no cofre do operador; o antigo saiu da
  árvore (fica no histórico, revogado). Reinstalação única do operador.
- Canal da v0.3.0 desmontado: repositório `Projeto-Galapago-canal` apagado,
  secret `CANAL_DEPLOY_KEY` apagado, `publicar-canal.sh` removido.

## v0.3.0 — atualização automática + ilha vista de cima em alta resolução (2026-11-20)

- **Atualização (P9):** canal PÚBLICO só de versão (`jonathasptbr-gh/Projeto-Galapago-canal`,
  `canal.json`) — decisão do operador: tudo privado. CI → `tools/android/publicar-canal.sh`
  via deploy key só do canal (secret `CANAL_DEPLOY_KEY`; a chave privada não
  existe fora do secret). App → `jogo/atualizador.gd` (HTTP no `raw`, `?t=`) +
  `sim/atualizacao.gd` (pura, 3 testes) → aviso com "Atualizar" (abre o APK da
  Release `dev` no navegador; precisa de login no GitHub). `exportar.sh` grava
  `config/version`/`galapago/build` num `project.godot` temporário;
  `permissions/internet=true`; `include_filter="*.json"`.
- **Tela (decisão do operador):** 1280×720, `canvas_items`, `expand`; arte
  *nearest* com câmera zoom 2; linhas/sombras/anel/texto lisos (antialiasing);
  snap 2D desligado (movimento em subpixel). Oráculo em 1280×720 (~40 s/60 quadros).
- **Mapa (P10):** `sim/mapa.gd` (cantos Wang por níveis mar/areia/grama/planalto,
  validador, 8 testes incl. o desenho real) + `jogo/mapa.gd` (TileMapLayer
  montado em código dos metadados do PixelLab) + `dados/mapas/ilha_teste.json`
  (41×22 pontos, 12 objetos) + y-sort de objetos/criatura pela base + sombras
  lisas. Design em `docs/gdd/mapa.md`.
- **Arte (PixelLab, 6 gerações; saldo 33/40):** tilesets standard 32 px
  `mar_areia` (transição 0,25), `areia_grama` (encadeado na areia),
  `grama_planalto` (transição 0,5 = paredes de penhasco ao sul) — cores dos
  terrenos compartilhados conferidas iguais (`#ffebba`, `#37a129`); objetos
  Pixen high top-down: `arvore` 64 (seed 3001), `rocha` 32 (3002), `estacao` 96
  (3003). Duas gerações falharam no servidor (502 e timeout) e não foram cobradas.
- Ferramentas: `tools/pixellab-tileset.mjs`, `tools/pixellab-imagem.mjs`.
- Conferido de fora após o CI #8: `canal.json` responde 200 SEM autenticação
  (`versao_codigo` 8, `0.3.0-b8`); o link do APK sem login responde 404 (privado,
  como decidido); o APK traz `assets/dados/mapas/*.json` e os metadados dos
  tilesets. Achado no b9: o `raw` serve cache de até 5 min ignorando o `?t=` →
  o atualizador passa a ler pela API (fresca), com o `raw` de reserva (b10).
  O b8 foi deixado em `Download/DSH-Go/` de propósito: o push seguinte
  (b9) faz o b8 oferecer a atualização — teste real do fluxo pelo operador.

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
