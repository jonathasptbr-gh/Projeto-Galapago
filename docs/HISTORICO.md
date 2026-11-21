# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

## v0.11.2 — água e rocha contornadas quando a rota volta à terra (2026-11-21)

- **Pedido do operador:** aplicar o **mesmo desvio dos troncos** a **pedras e
  rios**. Se a linha entra 100 px na água e **logo continua na terra**, o
  destino não é a água: contornar e seguir. Se a rota **termina** no bloqueio
  (ou não há continuação próxima), **não tentar cruzar** — para na fronteira, e
  só o **pulo** atravessa (a menos que bata na fronteira do mapa pulando).
  Priorizar o destino quando há **continuação do caminho num raio x** perto do
  animal.
- **`sim/corpo.gd` — `_alvo_visivel`:** procura um trecho de **TERRENO**
  (água/rocha) na **rota** (não na corda) até `olhar_px` + 24 px. Se achar e a
  rota **voltar a uma célula andável** em até `contorno_alcance_px` 260 de arco
  e `contorno_raio_px` 128 de distância do animal, mira a **continuação** e
  devolve `contorno: true`. Sem continuação, `contorno: false` e o alvo é o de
  sempre.
- **`sim/corpo.gd` — `_passo_com_desvio(..., permitir_terreno)`:** o caso
  "terreno" deixa de ser sempre parada: com `permitir_terreno`, entra no
  **mesmo leque de desvios do tronco** (candidatos conferidos com
  `limitar_segmento`, então **nunca entra na água/rocha**); sem ele, para.
  O compromisso/histerese do contorno continua.
- **`sim/corpo.gd` — teimosia limitada:** `_desvio_inicio_s` guarda o arco onde
  o contorno começou; depois de `desvio_teimoso_apos` 36 passos sem a rota
  andar `desvio_teimoso_px` 6 px, para na fronteira (antes podia ficar indo e
  voltando no muro). Um pulo ou caminho novo reinicia.
- **`dados/acoes.json`:** `contorno_alcance_px` 260, `contorno_raio_px` 128,
  `desvio_teimoso_apos` 36, `desvio_teimoso_px` 6; `_leia` em v0.11.2.
- **Testes (102, 0 falhas; parser 38 scripts, 0 erros):**
  `test_rota_atravessa_agua_contornando_quando_ha_continuacao` (o antigo
  `test_mover_respeita_o_mundo` virou este: a rota atravessa o lago e segue;
  confere que ela **nunca entra na água**, 0 quadros),
  `test_rota_que_termina_na_agua_para_na_fronteira`,
  `test_rota_contorna_rocha_quando_ha_continuacao` e
  `test_linha_que_entra_na_agua_e_sai_na_terra_e_contornada` (o vai-e-volta
  dentro do lago). Os testes de pulo em canal de 1 linha continuam valendo
  (não há volta; para e o pulo atravessa).
- **Verificação:** `tools/testes.sh` verde (102 testes, 0 falhas; parser 38
  scripts); **oráculo de quadros** com **45 quadros** 720×1280, os PNG abertos
  (a cena/demo não tem lago no roteiro, então o contorno é medido pela sonda
  headless/testes: posição, tempo e **0 invasão de água**).

## v0.11.1 — estrada que anda o laço, contorna a barreira e freia depois do fim (2026-11-21)

- **Pedido do operador:** (1) não travar perto de **pedra/beira de mar** quando
  a rota desenhada tem caminho; **tronco** não bloqueia se dá para contornar;
  (2) o **retorno/bico** travava na **ponta** e o **laço** era **cortado** (não
  fazia a volta) — o laço deve ser **andado**; (3) ignorar **amontoados** de
  movimentos numa zona do tamanho do animal (vai-e-volta, cruzamento) e
  **laços pequenos** que acendem a área por engano; (4) **sem freio antes do
  fim**: chegar na velocidade normal e frear **depois**, numa **mini inércia**,
  um pouco maior no **sprint manual**; (5) **tiro híbrido**: sem marca, na
  direção do **toque em relação ao animal**; com marca, automirado no alvo.
- **`sim/corpo.gd` — projeção:** `_projetar` custa
  `distância + projecao_peso × |arco − esperado|` e varre a rota inteira (a
  busca local de ±12 segmentos saiu). No cruzamento do laço (e no bico, cujos
  braços são a mesma linha) ela continua o braço andado em vez de pular para a
  volta; um teto de avanço por quadro fecha a porta do "teleporte".
- **`sim/corpo.gd` — alvo:** `_alvo_visivel` mira o ponto mais longe do traço
  (horizonte `olhar_px` 22, amostras de 2 px) que a linha reta **alcança
  andando** e que está **à frente** no sentido atual. A corda de uma curva não
  entra mais na pedra/água; no bico, o braço de volta fica atrás e é rejeitado
  até cruzar a ponta. O desvio orgânico lateral só é aplicado se o ponto
  desviado também for alcançável. O desvio de tronco mantém o lado e **cai para
  o outro** se o primeiro não passar (antes ficava presa).
- **`sim/corpo.gd` — fim:** saiu a **zona de freio** antes do fim
  (`freio_px`/`freio_min`); o corpo chega na velocidade normal e
  `_terminar_rota` inicia a **INÉRCIA** (`_inercia_*`): desaceleração linear na
  tangente do último trecho, `freio_extra_px` 16 px fora da rota (~0,3 s),
  ×`freio_sprint_x` 1,6 no sprint. Sem alvo marcado, claro: com alvo, continua
  a perseguição final.
- **`sim/trajetoria.gd`:** `limpar_amontoados(pontos, raio, janela, livre)` —
  corta o trecho que **retorna** para dentro de 24 px em até 100 px de arco
  (laço minúsculo, cruzamento de passagem, vai-e-volta nervoso); o critério é
  `arco ≥ d·1,8 + 12` (reta/curva não são tocadas) e o atalho precisa ser
  andável (`mundo.caminho_livre`, via Callable). Remove também o **ponto de
  entrada** do amontoado (senão sobrava um espinho).
- **`sim/formas.gd` / `dados/acoes.json`:** tamanho MÍNIMO do laço para a área
  — `laco_area_min` 2200 px² (era 700), `laco_arco_min` 160 (era 90),
  `laco_raio_min` 28 (era 24). Bloco `rota` novo: `amontoado_raio_px` 24,
  `amontoado_janela_px` 100, `alvo_pulo_objeto_px` 56, `projecao_peso` 0,25,
  `freio_extra_px` 16, `freio_sprint_x` 1,6; saem `freio_px` e `freio_min`.
- **`sim/corpo.gd` — TIRO HÍBRIDO (v0.11.1):** `_cmd_tiro(cmd, alvos)` não
  exige mais marca. **Com** `mira_final_id` continua a automira da v0.10 (o
  toque não muda a direção); **sem marca**, a direção é `cmd.alvo − pos` — o
  ponto do **toque na tela convertido para mundo** pelo `jogo/main.gd`; toque
  em cima dela usa o `olhar`. Se o alvo marcado sumir, a marca cai
  (`mira_final:perde`) e o tiro sai livre. Recarga/pausa iguais nos dois.
  `jogo/main.gd`/`jogo/hud.gd`: a nota vira "TIRO" e a legenda explica as duas
  formas.
- **Testes (99, 0 falhas; parser 38 scripts, 0 erros):** novos —
  `test_limpar_amontoados_*` (corta o laço pequeno, preserva o bico grande, não
  mexe em curva, respeita o caminho livre), `test_laco_pequeno_nao_acende_a_area`
  e `test_laco_de_tamanho_util_acende_a_area`, `test_laco_e_andado_sem_cortar_a_volta`,
  `test_bico_e_andado_ate_a_ponta_e_continua`,
  `test_beira_de_agua_nao_trava_quando_a_rota_contorna`,
  `test_amontoado_curto_e_cortado_da_rota`,
  `test_laco_pequeno_nao_acende_a_area` (no corpo),
  `test_inercia_depois_do_fim_do_caminho` (substitui o antigo teste de freio) e
  `test_inercia_do_sprint_e_um_pouco_maior`,
  `test_toque_sem_marca_atira_na_direcao_do_toque` e
  `test_toque_com_alvo_marcado_mira_no_alvo` (o teste antigo "sem marca não
  atira" foi substituído). Sonda headless da rota desenhada
  AO VIVO (laço e bico em passos de 8 px, tempo lento 0,35×): o laço passa por
  baixo e pela direita e termina em (112, 16), em 5,8 s; o bico chega a y > 150
  e termina em (297, 47), em 4,4 s; 0 quadros `barrado`; inércia 17,9 px
  (normal) × 28,8 px (sprint). TIRO: sem marca, toque abaixo → `dir` (0, 1);
  com marca, toque ao lado oposto → `dir` (0,71, 0,71) (mirou no alvo).
- **Verificação visual:** oráculo de quadros (`tools/quadros.sh`, **75
  quadros** 720×1280, ~103 s de render) — os PNG foram abertos: a HUD mostra a
  legenda nova ("toque → tiro (no alvo marcado ou na direção do toque)"), a
  linha pontilhada do laço aparece inteira e o evento `laco:onda` imprime; a
  criatura segue o traço sem salto para a volta. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.11.0 — bico andado, PULO no toque duplo, TIRO no toque simples e SPRINT com energia no segurar (2026-11-21)

- **Pedido do operador:** (1) **não ignorar mais o bico** (v0.10 ele era
  cortado da rota); (2) **inverter os toques**: PULO no toque duplo e TIRO no
  toque simples; (3) a **habilidade de escavar** só vale **sem um caminho** e
  deve ativar **no momento em que o tempo mínimo de segurar passa** (não no
  soltar); (4) o **tiro usa o toque simples**, mas **segurar durante uma
  caminhada sem mover o dedo** (com alvo marcado ou não) faz o animal dar um
  **SPRINT**, que **gasta uma barra de energia**.
- **`sim/formas.gd`:** o **BICO saiu** do leitor de formas — o traço é a rota
  inteira, do jeito que foi desenhado (o espinho é andado). A análise agora
  devolve só **laços**; `bicos`, os índices `i`/`j` do corte e os limiares do
  bico saíram.
- **`sim/corpo.gd`:** sem `_bicos`/`_sem_bicos` (nada é cortado). **SEGURAR**
  virou `_cmd_segurar`: **com um caminho em curso → SPRINT** (`sprint.fator`
  1,7×, gasta `gasto_s` 0,45/s da barra `energia`, para ao soltar ou ao zerar;
  recupera `recarga_s` 0,22/s); **sem caminho → habilidade (cavar)**, que agora
  é chamada no limiar. O sprint entra na velocidade de `_avancar_rota` e no
  `passo` (gasto/recuperação), com reset no fim/novo caminho.
- **`sim/gestos.gd`:** o **toque simples fica PENDENTE** até a janela do duplo
  fechar (o `tick` solta "toque" = TIRO); o **segundo toque** vira
  "toque_duplo" = PULO; o **SEGURAR ativa no limiar** (`tick` emite
  "segurar_inicio") e o soltar emite "segurar_fim" (não é mais no soltar que a
  habilidade nasce).
- **`sim/comandos.gd` / `dados/gestos.json`:** mapa novo — `toque` → `tiro`,
  `toque_duplo` → `pular`, `segurar` → `segurar` (o corpo decide sprint ×
  habilidade), `segurar_fim` → `soltar_segurar`.
- **Dados (`dados/acoes.json`):** bloco novo `sprint` (1,7× · 0,45/s · 0,22/s ·
  mínimo 0,08); saem as chaves `bico_*` de `formas`.
- **`jogo/hud.gd`:** a **barra de ENERGIA** embaixo, à esquerda (fica laranja
  com menos de 25%) e a legenda nova: toque = tiro, toque duplo = pulo,
  segurar no caminho = sprint, segurar parado = habilidade.
- **`jogo/demo.gd`:** o pulo usa o **toque duplo**, o tiro o **toque simples**
  (dois tiros, com a recarga de 1 s); a cavada continua nos `segurar` sem
  caminho; o caminho em "L" leva ao adversário e o golpe final fecha.
- **Verificação:** **86 testes, 0 falhas**, 38 scripts (parser limpo); novos:
  o segurar ativando no limiar, o sprint acelerando/gastando/recuperando a
  energia, o segurar sem caminho cavando, e o bico **andado** (na rota).
  Sonda headless da demo: `laco:onda`, `mira_final`, dois
  `tiro:disparo`+`acerto` e `golpe_final`. **Oráculo de quadros**
  (`tools/quadros.sh`, 45 quadros 720×1280 em ~3 min): HUD com a legenda nova
  (toque = tiro, toque duplo = pulo, segurar no caminho = sprint) e a **barra
  de energia** cheia embaixo, à esquerda — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.10.0 — marca ligada ao caminho, TIRO no toque duplo, PULO no toque e perseguição final (2026-11-21)

- **Pedido do operador:** (1) **sem a desaceleração final** quando o caminho
  termina num alvo marcado e **melhorar a perseguição final** — o animal estava
  batendo sem ter ido atrás do alvo; (2) o **ataque em área** deve acender
  **antes de chegar no laço**: a trava é a **distância até o CENTRO** da área
  (começar com ~7× o tamanho do animal), sem esperar o animal entrar no anel;
  (3) mudar o **gatilho do tiro e o método de marcação**: a **marcação** é a
  mesma do golpe — **levar o fim do caminho até o alvo** (durante o caminho ele
  fica marcado) — e o **tiro é o TOQUE DUPLO**; o **pulo vira o TOQUE SIMPLES**
  (que antes marcava). O resumo do tiro: com o alvo marcado, os toques duplos
  disparam **mirados nele**, não interrompem o caminho, o animal **para** para
  atirar e segue; a **marca não sai no disparo**, sai no **golpe físico** —
  está **ligada ao caminho**.
- **`sim/gestos.gd`:** o **toque simples fica PENDENTE** até a janela do duplo
  fechar (`toque_duplo_janela_ms` 280 ms): sem um segundo toque, o `tick` solta
  o "toque" (PULO); com o segundo perto e logo, é "toque_duplo" (TIRO) e o
  simples é descartado. Sai o par `_ultimo_toque_*`.
- **`dados/gestos.json`:** `toque` → `pular`; `toque_duplo` → `tiro` (o toque
  não trava mais mira).
- **`sim/corpo.gd`:** a **marca** (`mira_final_id`) nasce **durante o caminho**
  (`_montar_marcas` chama `_marcar_alvo_no_fim` a cada atualização da rota);
  ela **anda com o inimigo**, vale para o tiro e para o golpe, e **sai** no
  golpe físico (ou num caminho novo). **`_cmd_tiro`** (toque duplo): exige
  marca e recarga (`tiro_recarga_s` 1 s), atira no alvo (`_atirar`), pausa
  (`tiro_pausa_s` 0,25 s) e segue a rota. **A área** acende pela **distância ao
  centro** (`area_gatilho_px` 224). **Sem zona de freio** quando há marca. No
  fim do caminho com marca: `_iniciar_final` — perto, bate; longe, **PERSEGUE**
  (`_perseguir`, teto `embalo.perseguir_s` 3 s, embalo curto) e bate **ao
  chegar** (`ataque.alcance` + raio + 10). Saem a tolerância de 48 px
  (`mira_final_tol_px`) e `mira_final_pos`; o **tiro do bico** sai (o bico só
  corta o beco da rota).
- **Dados:** `combate` ganha `area_gatilho_px` (224) e `tiro_pausa_s` (0,25);
  saem `mira_final_tol_px` e `bico_pausa_s`; `embalo` ganha `perseguir_s`
  (3,0 s). `formas.lacos` não guarda mais o `anel` (o gatilho é a distância ao
  centro); `distancia_polilinha` sai.
- **`jogo/`:** `hud.gd` com a legenda nova (toque = pular, toque duplo = tiro,
  fim do caminho no alvo = marca) e "ALVO MARCADO"; `main._evento` nota
  "TIRO no alvo marcado"; `demo.gd` reescrito: laço perto (área), cavar, toque
  (pulo), caminho em "L" até o adversário (travessia + marca), **dois toques
  duplos (tiros)** e o **golpe final** na perseguição.
- **Verificação:** **90 testes, 0 falhas**, 38 scripts (parser limpo); novos:
  o toque pendente/duplo, o tiro no alvo marcado (mira, recarga, pausa, marca
  mantida), a marca nascendo durante o caminho, a perseguição final, a área
  pela distância e o bico sem tiro. Sonda headless da demo: `laco:onda`,
  `mira_final`, dois `tiro:disparo`+`acerto`, `batida`, `golpe_final`.
  **Oráculo de quadros** (`tools/quadros.sh`, 45 quadros 720×1280 em ~3 min,
  ~4 s/quadro — a linha pontilhada pesa no `softpipe`): HUD com a legenda nova
  (toque = pular, toque duplo = tiro, fim do caminho = marca) e a linha
  pontilhada escura seguindo o traço — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.2 — a linha do caminho vira traço real pontilhado; cooldown dos especiais e EMBALO dos golpes (2026-11-21)

- **Pedido do operador (ajustes):** (1) a linha do caminho estava **quebrada**
  (retas entre os pontos da rota simplificada): desenhá-la **contínua**, como o
  desenho real do dedo, com mais pontos — e **pontilhada**, **mais escura e
  transparente**, na posição; (2) **cooldown de 1 s** para reusar os ataques
  especiais (área do laço e tiro do bico); (3) os golpes físicos devem
  **acelerar o movimento**: curto na **marcação** (golpe final) e mais longo no
  **empurrão** (embala antes, passa mais rápido que a caminhada pelo alvo e
  desacelera depois).
- **`jogo/trilha.gd` (reescrito):** a linha agora recebe `corpo.traco` (o traço
  CRU do dedo, denso) e desenha **pontos a cada 9 px de arco** — a curva de
  verdade, sem emendar retas. Estilo: `PASSO_PX` 9 · raio 2,1 · cor
  `#0a171f` a 55% (escura e transparente) · no chão (`z_index` 1) · pontinho
  maior no destino. `jogo/main.gd` mostra o traço enquanto desenha/anda na
  rota, e apaga ao terminar.
- **`sim/corpo.gd` — COOLDOWN (1 s):** os especiais usam `_recargas` ("onda" e
  "tiro"): ao disparar, `onda_recarga_s`/`tiro_recarga_s` (1,0 s) entram; a
  marca do especial **não é consumida** durante a recarga — fica **pendente** e
  acende quando ela termina (se a criatura ainda estiver no anel/perto da base).
- **`sim/corpo.gd` — EMBALO:** `_iniciar_embalo(duração, fator)` + `_fator_embalo()`
  (pico `sin(π·u)`), aplicado à velocidade do passo da rota. O **empurrão**
  (batida de travessia) chama o **longo** (0,6 s · 2,0×) — passa rápido pelo
  alvo e desacelera; a **marcação** (alvo final) chama o **curto** (0,25 s ·
  1,7×) uma vez, quando a criatura chega a `gatilho_px` (70 px) do alvo. A
  recarga do embalo final é armada de novo a cada nova marca/rota.
- **Dados:** `combate` ganha `onda_recarga_s` e `tiro_recarga_s` (1,0 s);
  bloco novo `embalo` (0,25 s/1,7× · 0,6 s/2,0× · 70 px).
- **Verificação:** **91 testes, 0 falhas**, 38 scripts (parser limpo); três
  novos: a recarga de 1 s (marca pendente), o empurrão embalando (passa > 135
  px/s) e a marcação com embalo CURTO (≤ 0,3 s). **Oráculo de quadros**
  (`tools/quadros.sh`, parcial: 33 quadros em ~2,5 min — ~4,5 s/quadro neste
  celular com a linha pontilhada; abri o quadro 30): a linha aparece
  **PONTILHADA, escura e translúcida**, acompanhando o traço do dedo (sem as
  retas entre pontos de referência da versão anterior). Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.1 — o laço acende no anel, o bico em "T" não é andado e o caminho vira ESTRADA (2026-11-21)

- **Pedido do operador (ajustes):** (1) o efeito do laço deve acender quando a
  criatura estiver em **qualquer parte da circunferência** do laço, desde o nó —
  se ela já estiver andando no laço quando ele fecha, a habilidade já está
  ativa; (2) o **bico** só era lido a partir do parado: reconhecer o espinho no
  **meio do caminho** (formatos de "T") e **não andar o beco** — a criatura para
  antes de entrar e dispara na direção apontada; (3) o caminho é uma **ESTRADA
  mais larga**: o animal pode ir mais à esquerda, à direita ou no centro (os
  pontos eram a referência, não a obrigação de pisar na linha), o percurso fica
  **menos retilíneo e mais orgânico**, e o fim ganha uma **zona de freio** para
  parar suave.
- **`sim/formas.gd`:** o laço guarda o **anel** (a circunferência fechada) na
  marca. O **bico foi reescrito**: a PONTA é uma reversão (~180°) e a BASE é
  onde a volta **reencontra a estrada** — a primeira curva forte
  (`bico_base_angulo` 45°) depois da ponta, ou o fim do traço, sempre perto do
  traço anterior (`bico_base_px` 14, `bico_fim_px` 40 no fim). A marca leva
  `i`/`j` (índices no traço cru) do trecho a cortar. `distancia_polilinha`
  mede a distância ao anel. Isso pega o **"T" perpendicular**, o "V" e o bico
  deitado na própria linha.
- **`sim/corpo.gd`:** o gatilho do laço agora é a **distância ao anel**
  (qualquer parte), sem a checagem de direção: laço fechado com a criatura em
  cima = onda na hora. `_bicos`/`_sem_bicos` **cortam o beco da rota** (o trecho
  `i+1..j`) e o bico só arma a marca na base; ao acender, a criatura **PAUSA**
  (`bico_pausa_s` 0,25 s) e o tiro sai da base na direção da ponta.
  A rota virou **follow-the-road**: `_projetar` (busca local na rota),
  `_ponto_em_rota`/`_tangente_em_rota`, alvo **à frente** (`olhar_px` 22) +
  **desvio lateral orgânico** (duas senoides de fases sorteadas, amplitude
  `estrada_desvio_px` 9, dentro de `estrada_largura_px` 30) e **zona de freio**
  (`freio_px` 44, `freio_min` 0,12, smoothstep) — a criatura para onde está
  (`parada_px` 4), sem salto para o último ponto. No desvio de tronco, o alvo
  à frente **pula** o ponto dentro do objeto e o **lado** escolhido é mantido
  até passar (sem oscilar na beirada). O **alvo final** também é marcado quando
  a rota acaba **durante** o desenho (traço ao vivo); o comando `ataque` usa a
  **tangente** da estrada (o `_rota_i` agora é o segmento atual).
- **Dados (`dados/acoes.json`):** `formas` ganha `bico_base_px`, `bico_fim_px`,
  `bico_base_angulo` (sai `bico_volta_px`); `combate` ganha `bico_pausa_s`;
  `rota` ganha `olhar_px`, `estrada_largura_px`, `estrada_desvio_px`,
  `estrada_onda_px`, `estrada_onda2_px`, `freio_px`, `freio_min`, `parada_px`.
- **`jogo/`:** `demo.gd` troca o bico por um **"T" no meio do caminho**;
  `main._evento` mostra no log `mira_final:perde`.
- **Verificação:** **88 testes, 0 falhas**, 38 scripts (parser limpo); seis
  novos: laço acende no anel, T no meio não é andado (e a criatura para),
  estrada orgânica dentro da largura, freio no fim, T e anel em `test_formas`.
  **Oráculo de quadros** (`tools/quadros.sh`, 180 quadros 720×1280 em ~5 min,
  ~1,7 s/quadro): o laço acende cedo (nota "LAÇO: onda em área" antes de
  4,4 s, com a criatura no anel), o **"T" é desenhado e o beco sai do traço**
  (a linha segue reta), a criatura **para na base e dispara para cima** (nota
  "BICO: tiro disparado") e o corpo anda **DENTRO da faixa**, fora da linha
  branca — abri os PNG. Detalhe em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.9.0 — o ataque nasce do DESENHO: laço, bico, travessia e alvo final (2026-11-21)

- **Pedido do operador:** ajustar o sistema de gestos e ações — (1) **laço** no
  caminho = **ataque em área** com centro no centro estimado do laço, ativado
  no **nó** (onde o laço fecha na primeira linha) quando o animal passa por
  ele, sem depender de ir ao centro; (2) **bico** (ida e volta brusca) = **tiro**
  na direção do bico, saindo do ponto do caminho **antes** dele (um bico a
  partir da posição inicial dispara sem se mover); (3) **segurar parado** =
  **habilidade em si mesmo** com duração; (4) dois toques pulam sem
  interromper o caminho; (5) **cruzar a linha sobre** um alvo = **batida/
  empurrão**; (6) **terminar o caminho em cima** do adversário = **golpe
  físico**, com a marca **no inimigo** (se ele andar demais, a automira se
  perde); (7) **esquiva é o próprio caminhar** + tempo lento, sem efeito.
- **Decisões do operador na mesma conversa:** **nenhum gesto de dois dedos**
  (saem ataque ↑, defesa ↓ e especial abrindo); o efeito do golpe no
  adversário é **empurrão + piscada, sem vida**; a habilidade de teste do
  segurar é **cavar** (não a cor piscando), valendo **em qualquer lugar** da
  tela, não só em cima do animal.
- **`sim/formas.gd` (novo, puro):** lê o traço CRU e devolve MARCAS.
  **Laço:** cruzamento entre segmentos (`cruzamento`), área/centroide por
  shoelace, raio `√(área/π)` limitado, direção do fechamento; lido no traço
  reduzido (RDP 3 px). **Bico:** REVERSÕES (~180° numa janela de 10 px de
  arco) — a ponta e a base (onde a volta reencontra o caminho); volta
  estreita, altura ≥ 18 px; lido no traço **amostrado a cada 6 px** (uma ida e
  volta na MESMA reta tem desvio zero e o RDP comeria a ponta).
- **`sim/trajetoria.gd`:** a distância do Douglas-Peucker agora é ao
  **SEGMENTO** (não à reta infinita): a **ponta do bico** que passa além da
  corda deixa de ser engolida, e a criatura **anda o espinho**.
- **`sim/gestos.gd` (reescrito):** um dedo só; **segurar parado em qualquer
  lugar** = `segurar_inicio` (habilidade); segundo dedo **não é ação** (o
  caminho continua; toque/toque duplo/segurar ficam desarmados). Saem
  `_acao_dedos`, `defendendo`, `deslize`, `especial`, `caminho_cancelar`.
- **`sim/comandos.gd`:** tabela nova (`toque` → travar, `toque_duplo` → pular,
  `segurar` → habilidade, `trajetoria` → mover); saem `setor` e o `deslize`.
- **`sim/corpo.gd`:** o ataque saiu dos gestos e foi para as FORMAS —
  `tracar` guarda o traço cru, lê as formas (a cada ~5 pontos, e no soltar) e
  monta as **marcas**; o gatilho é a passagem da criatura pelo ponto da marca
  (`gatilho_raio_px` 24; o laço exige a direção do fechamento). **Onda**
  (círculo que cresce do centro e empurra quem varre), **tiro** (projétil na
  direção do bico, para no primeiro alvo), **batida** de travessia,
  **alvo final** marcado no inimigo (golpe físico na chegada; perdido se ele
  andar > 48 px), **habilidade** genérica com `cavar` como primeira. Saem
  `esquiva`, `defesa`, `especial`, `desvio` e `guardar_rota`/`voltar_rota`.
  A rota ao vivo continua igual (pontos de referência, desconto, desvio de
  objeto, barreira e pulo).
- **`sim/adversario.gd`:** `empurrar(dir, px)` — desliza (260 px/s) até gastar
  o empurrão, cortado pelo mundo, e **pisca** 0,24 s; `piscando()`/`empurrado()`.
  **`sim/alvos.gd`:** `empurrar` (só quem sabe reagir) e `reage`.
- **`jogo/`:** `efeitos.gd` (novo: onda/tiro); `mira.gd` desenha o **"X"
  amarelo do alvo final no inimigo**; `criatura.gd` perde rastro de esquiva e
  anel de defesa, ganha anel de habilidade; `adversario_mock.gd` pisca no
  acerto; `hud.gd` com a legenda/estado novos e a **nota** do último golpe;
  `main.gd` sem cancelamento de traço (não há gesto de dois dedos), com o
  fechamento do caminho chamando `finalizar_rota` e o nó dos efeitos.
  `demo.gd` reescrito: laço → onda; bico → tiro; segurar → cavar (desce e
  sobe); toque duplo; travessia; fim em cima (golpe final).
- **Dados:** `gestos.json` só com toque/toque duplo/segurar/trajetória;
  `acoes.json` ganha `formas`, `combate`, `habilidade` + `cavar` e `batida`;
  saem `esquiva`, `especial`, `defender`, `escavar` (virou `cavar`).
- **Verificação:** **82 testes, 0 falhas**, 38 scripts (parser limpo).
  **Sonda headless da demo inteira** (2.400 quadros, `--demo`): `laco:onda` em
  ~3 s, `bico:tiro` em ~4,6 s, `habilidade:on` + `camada:subsolo` (8,2 s) e
  `camada:superficie` (10,0 s), `mira_final:adversario:0` (12,6 s), `batida` +
  `acerto` + `golpe_final:adversario:0` (15,6 s). **Oráculo de quadros**
  (`tools/quadros.sh`, 150 quadros 720×1280 em ~3 min 50 s, ~1,5 s/quadro):
  caminho com **laço** desenhado, **onda azul saindo do centro** do laço em
  3,1 s, HUD v0.9 e o **bico** desenhado em 4,6 s — abri os PNG. Uma segunda
  gravação (520 quadros, a demo inteira) mostrou a **cavada** (terra voando e
  `subsolo` na HUD), o **alvo final** e o **"X" amarelo pulsando NO INIMIGO**
  em 16,7 s — abri os PNG. Detalhe de projeto em
  [`gdd/gestos-e-acoes.md`](gdd/gestos-e-acoes.md).

## v0.8.0 — gestos de ação com DOIS dedos (2026-11-20)

- **Pedido do operador:** os gestos de ação conflitavam com o movimento
  contínuo. Agora: **mover = 1 dedo arrastando** (como está, sem espera);
  **ataque = 2 dedos para cima**; **defesa = 2 dedos para baixo**; **especial =
  2 dedos abrindo** (do centro para a borda, como um zoom). O dedo que desenha
  o caminho **desconta**: com o segundo dedo dá para atacar **durante** o
  desenho, sem parar o traço.
- **`sim/gestos.gd` (multitouch, reescrito):** o PRIMEIRO dedo é o do caminho;
  os dedos EXTRAS formam o ponteiro da ação (média dos deslocamentos) — cima
  (`acao_min_px` 44 px em até `acao_max_ms` 0,7 s) → `deslize` (ataque);
  baixo → `segurar_inicio` com `defesa` (sustentada até soltar); lateral +
  afastamento do dedo do caminho ≥ `especial_abre_px` (70 px) → `especial`.
  Um disparo por gesto; soltar e tocar de novo abre outro. Se o segundo dedo
  chega antes de o caminho desenhar (`desenho_min_ms` 150 ms), o gesto é só
  ação: `caminho_cancelar` (o motor devolve a rota anterior). Toque, toque
  duplo e escavar continuam no dedo do caminho sozinho.
- **`sim/comandos.gd`:** evento `especial` próprio (ação + direção de fora).
  A tabela `deslize` ficou só com "cima" — o "baixo" agora é DEFESA, não
  esquiva.
- **`jogo/main.gd`:** entrada multitouch (`_dedos` por índice, origem congelada
  no PRIMEIRO dedo); `caminho_cancelar` restaura a rota; uma AÇÃO devolve o
  tempo na hora (`_plano_liberado`), o golpe não fica em câmera lenta. **Bug
  meu da v0.7 corrigido:** a fórmula do véu estava invertida (alfa cheio FORA
  do desenho); agora é 0 parado, 0,22 desenhando e cai junto com a rampa
  (medido nos quadros: brilho médio 110 desenhando × 135–140 parado).
- **`jogo/demo.gd`:** roteiro reescrito com TRILHAS por dedo (caminho de 1
  dedo; ataque/especial/defesa de 2 dedos; ataque com o dedo extra no meio de
  um caminho em curso); `jogo/hud.gd` com a legenda nova.
- **Dados (`dados/gestos.json`):** entram `desenho_min_ms`, `acao_min_px`,
  `acao_max_ms`, `especial_abre_px`; saem os `flick_*` e o `segurar_estavel_ms`.
- **Verificação:** **73 testes, 0 falhas**, 35 scripts. Sonda headless da demo
  inteira (400 quadros): caminho ao vivo (véu 0,22 · 0,35×), ataque de 2 dedos
  em 2,2 s **sem andar** (célula estável, rota seguindo), especial em 3,4 s,
  defesa em 4,6 s (rota parada, `soltar` retoma), pulo, mira, ataque no alvo, e
  **ataque com o 2º dedo em 10,0 s com o caminho ainda sendo desenhado**
  (`desenhando` segue, a rota continua, o tempo volta na hora). Quadros do
  oráculo (96) abertos: legenda, véu e ataque sem véu.

## v0.7.1 — o gesto de AÇÃO não é passo (2026-11-20)

- **Correção do operador sobre a v0.7.0:** "em paralelo" queria dizer poder
  **atacar DURANTE a caminhada**, e não que todo gesto vira movimento. Na
  v0.7.0 o risco de ataque também desenhava um passo (≈120 px de mundo) e
  desviava a criatura.
- **Gestos (`sim/gestos.gd`):** quando o risco dispara, `_desenhando` volta a
  falso — o gesto é de AÇÃO, não de caminho — e o `soltar` não emite
  `trajetoria` (e nem `nada`: o gesto já resolveu). A **defesa** também
  cancela o traço. Um gesto = uma intenção.
- **Corpo (`sim/corpo.gd`):** novos `guardar_rota()` / `voltar_rota(g)` — o
  instantâneo da rota (pontos, índice, progresso, barreira e autonomia) é
  tirado na DESCIDA do dedo (`jogo/main.gd`) e devolvido quando o gesto vira
  ação. Assim o golpe acontece **por cima** da caminhada, que continua de onde
  estava.
- **Tela (`jogo/main.gd`):** `_cancelar_traco()` no evento `deslize` e no
  `segurar_inicio` (defesa/escavar); num risco o tempo volta na hora
  (`_retomada = 0`), sem rampa — ação não fica em câmera lenta. O véu é
  suavizado e o "planejamento" (tempo lento + véu) só começa quando o gesto
  **deixou de poder ser um risco** (`_planejavel` em `sim/gestos.gd`): senão a
  tela escureceria por dois quadros a cada ataque.
- **Verificação:** 72 testes; sonda headless da demo inteira (520 quadros, 30 fps):
  ataques em 2,6 s / 3,6 s / 4,9 s / 6,0 s / 9,2 s / 12,4 s **não** movem a
  criatura (célula estável; a rota de 3 pontos volta logo após o disparo); a
  defesa em 10,6 s cancela o traço para baixo; os dois caminhos seguem
  normais. **71 testes, 0 falhas**, 35 scripts.
- **O que fica:** a linha da rota pode piscar por ~2 quadros no começo de um
  risco (o traço nasce ao vivo e é cancelado no disparo) — ver `RESIDUOS`.

## v0.7.0 — caminho ao vivo, sem espera, e ações em paralelo (2026-11-20)

- **Pedido do operador:** (1) tirar o atraso do toque longo — o arrasto
  contínuo vira caminho **direto**; (2) a linha **não se move com o animal**
  (parte da posição no INÍCIO do gesto; se ele se mexeu no meio, volta para
  começar por lá); (3) **ataques e afins em paralelo**, sem atraso; (4)
  **escurecer** a tela durante o desenho e uma **rampa de aceleração** na saída;
  (5) **mais sensibilidade** (dedo menor cobrindo mais tela).
  **Decisões dele** (perguntadas antes de codar): caminho **AO VIVO** (a
  criatura já anda atrás do dedo) e ação disparada **no meio do risco**, ao
  cruzar o limiar.
- **Gestos (`sim/gestos.gd`, reescrito):** `segurar_min_ms` deixou de ser porta
  do caminho — passou de `desenho_min_px` (16 px) já é caminho
  (`desenhando()`), e o `tick` só decide **defesa** (baixo + parado 0,18 s) e
  **escavar** (segurar nela, parado, sem arrastar, 0,38 s — decidido no
  soltar). O **RISCO** (`flick_*`) dispara `deslize` NO MEIO do arrasto e o
  caminho continua: 44–170 px, ≤ 0,26 s, ≥ 700 px/s, desvio da corda ≤ 24 px,
  **um por gesto** (senão um desenho rápido viraria metralhadora). Guarda
  `_tempos` por ponto para medir velocidade numa janela de 90 ms.
- **Corpo (`sim/corpo.gd`):** novo `tracar(pontos, mundo, inicio)` — a rota é
  refeita a cada quadro com o traço até agora, o progresso **nunca anda para
  trás** e a origem fica congelada. No primeiro quadro, se a criatura já se
  mexeu, o trecho que a traz de volta ao começo é posto NA FRENTE **depois** da
  simplificação (um traço reto com os três pontos colineares seria engolido
  pelo Douglas-Peucker e ela cortaria o caminho — foi o primeiro teste
  vermelho). `_pontos_de_rota` (desconto + RDP) e `_guardar_rota` foram
  extraídos do antigo `_cmd_mover`, que continua valendo (testes antigos).
- **Tela (`jogo/main.gd`):** na descida do dedo congela-se a **origem**
  (posição da criatura + `canvas_transform` inverso); o traço é traduzido com
  `desenho.ganho` (1,6), então 100 px de dedo desenham 160 px de tela. O **véu**
  (`ColorRect` na CanvasLayer da HUD, atrás dos rótulos) escurece
  `planejamento.escurecer` (0,22) enquanto desenha/defende e clareia junto com
  a **rampa** `retomada_ms` (0,45 s), que devolve o tempo de 0,35× a 1× com
  `v²` (começa devagar e solta no fim). `jogo/trilha.gd` perdeu a âncora;
  `jogo/hud.gd` (legenda v0.7.0, "DESENHANDO") e `jogo/demo.gd` (sem `hold`,
  divide o traço pelo ganho para cobrir as mesmas células) seguem a regra.
- **Dados (`dados/gestos.json`):** `desenho.ganho` 1,6; `planejamento` 0,35× ·
  0,45 s · 0,22; `flick_*`; saíram `trajetoria_min_px` e `deslize_max_ms`
  (eram da regra antiga).
- **Verificação:** `tools/testes.sh` — **70 testes, 0 falhas**, 35 scripts no
  parser. `test_gestos.gd` reescrito (sem espera, risco no meio, um por gesto,
  desenho lento/curvo sem ação, defesa, escavar, toques); `test_corpo.gd` ganhou
  o traço ao vivo (cresce sem voltar; a volta ao começo quando ela se mexeu).
  Oráculo: 96 quadros 720×1280 (t≈3,2 s) — véu visível, rota ao vivo atrás do
  dedo, ataque disparado no meio do risco com o caminho continuando; a demo
  completa (500 quadros) confere os passos seguintes.

## v0.6.1 — o aviso de atualização volta a aparecer na tela (2026-11-20)

- **Relato do operador:** o app detectou a atualização (a HUD dizia "toque em
  ATUALIZAR"), mas **não havia botão nem painel na tela** para atualizar.
- **Causa medida:** o `Atualizador` é um `Control` filho de uma `CanvasLayer`;
  os anchors sozinhos **não davam tamanho a ele** (ficava 0×0). O botão
  "ATUALIZAR" era ancorado no topo-direita de um retângulo de 0×0 e caía em
  **x = −252** (fora da tela); o painel de download tinha o mesmo problema. A
  HUD mostrava o texto, mas o controle não.
- **Conserto:** o `Atualizador` passou a ocupar a tela (`size` =
  `get_viewport_rect().size`, reaplicado em `size_changed`); o botão desceu
  para `y + 420` (abaixo da legenda) e, na **primeira detecção**, o painel
  "Nova versão … disponível" abre **sozinho**, com "Baixar agora" e "Depois".
  O botão continua disponível depois; o painel não reabre sozinho na mesma
  sessão.
- **Verificação:** sonda headless com `await` mediu o `Atualizador` em
  720×1280 e o botão em x = 468..708 (dentro da tela); a tela real com build
  13 contra a Release conferiu o painel. 66 testes, 35 scripts, CI e APK
  verdes. O runner de testes síncrono não roda quadros, então o layout do
  atualizador não tem teste unitário (ver `RESIDUOS`).
- **Para o operador:** a **v0.5.0 instalada** tem o código antigo e não
  consegue mostrar o botão — é preciso instalar o APK da **v0.6.1 à mão uma
  vez** (o `ATUALIZAR` do app não aparece nela). Depois disso o aviso funciona
  nas próximas versões. O APK 0.6.0-b14 também tem o defeito; use o 0.6.1-b15.

## v0.6.0 — retrato, gestos de tela, caminho por âncora e desvio de objetos (2026-11-20)

- **Pedido do operador:** os gestos de ação não são mais relativos ao animal
  (não existe "para a frente dele"): são da TELA — para cima é ataque físico,
  lados são especiais, para baixo é esquiva; arrastar para trás e continuar
  segurando é defesa. Tela em **retrato**. O caminho passa a ser desenhado a
  partir de uma **âncora segurada** longe da criatura (o dedo não tapa a
  visão), com **retardo de tempo** durante o desenho/planejamento; **desconto
  inicial** do vai-e-volta; caminho contado como **pontos de referência** com
  **pequenos desvios de objetos**; barreira sem pulo = para, com pulo = segue.
- **Gestos (`sim/gestos.gd`):** setores de tela (0° = direita, -90° = cima);
  segurar parado 0,38 s cria a âncora; arrastar a partir dela = `trajetoria`;
  baixo + segurar (parado 0,18 s) = `segurar_inicio` de defesa; segurar nela
  sem arrastar = escavar (só no soltar, e só se não arrastou além de 16 px).
  Toque, toque duplo e os demais limiares continuam em `dados/gestos.json`.
- **Comandos (`sim/comandos.gd`):** a tabela `mapa.deslize` agora é de ângulos
  de TELA: cima → ataque; direita/esquerda → especial com lado; baixo →
  esquiva com direção. A defesa (`defesa: true`) vence o "nela".
- **Caminho (`sim/trajetoria.gd` + `sim/corpo.gd`):** o traço é cortado no
  início (`descontar_inicio`: só se houve volta ≥ 6 px, janela de 140 px e
  reta andável) e reduzido por Douglas-Peucker (`simplificar`, 10 px) a pontos
  de referência. O corpo procura um ponto por vez; tronco é contornado por um
  leque de até ±120° (`desvio_angulos`, teto de 80 passos); água/rocha/altura
  são barreira: a criatura **para** (`barrado()`), a rota fica guardada e um
  **pulo** durante a rota atravessa e retoma. Caiu na água? Não anda sobre ela:
  precisa de outro pulo.
- **Especial:** ação nova em `dados/acoes.json` (fases 0,14/0,22/0,26; alcance
  56; arco 120°; recarga 0,55), um golpe lateral genérico — o conteúdo por
  criatura fica para P4/P5. O ataque físico continua mirando no alvo/rota, não
  no ângulo do dedo.
- **Retrato:** `project.godot` 720×1280, `window/handheld/orientation=1`;
  oráculo em 720×1280; HUD e painel de atualização reorganizados para a tela
  alta (texto do aviso em cima, botões embaixo); botão "Verificar atualização"
  desceu para não colidir com a legenda.
- **Tempo lento:** enquanto a âncora existe, o MUNDO roda a 0,35×
  (`planejamento.escala_tempo`); o relógio do gesto e o dedo continuam reais.
  A HUD mostra `PLANEJANDO 35%`.
- **Prévia:** o traço é desenhado transladado sobre a criatura (a âncora vira
  o "animal virtual") com um anel ciano no ponto segurado; ao soltar, a rota
  começa na posição atual dela.
- **Testes:** 66 verdes (gestos de tela/âncora/defesa, desconto, RDP, ordem dos
  waypoints, desvio de tronco, barreira + pulo, pulo curto na água, especial,
  esquiva de tela). Parser: 35 scripts limpos. Oráculo: 60 quadros 720×1280
  sem erro de script, âncora e prévia conferidas por imagem.
- Dois defeitos encontrados no caminho: a célula bloqueada era testada 3 px à
  frente e caía na célula de baixo (o desvio nunca começava) — agora o primeiro
  bloqueio é amostrado ao longo do passo; e a criatura conseguia **andar para
  fora da água** depois de um pulo curto — agora a célula atual de terreno
  bloqueia o passo normal.
- **Fica para depois:** especiais por criatura, ajuste fino de
  `escala_tempo`/`desconto_raio_px` com o operador, física de pouso/natação e
  a afinidade (P4).

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
