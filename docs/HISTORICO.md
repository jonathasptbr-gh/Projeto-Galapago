# Histórico

> Apêndice: a entrada mais nova em cima. Uma seção por versão, escrita uma vez
> no lote. Lê-se por `grep`, nunca inteiro.

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
