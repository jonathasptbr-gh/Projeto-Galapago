# Gestos e ações — como a criatura se move e age

> Regra toda em `sim/` (testada) e nas tabelas `dados/gestos.json` +
> `dados/acoes.json` (editáveis); `jogo/` só desenha. **v0.13.0.**

## O fluxo

```
dedos (toque real ou demo roteirizada — mesmo caminho)
  → sim/gestos.gd   : UM dedo = caminho · toque · toque duplo · segurar
  → sim/formas.gd   : lê a FORMA do traço (LAÇO)
  → sim/comandos.gd : traduz o gesto em COMANDO (ação + alvo no mundo)
  → sim/corpo.gd    : ROTA ao vivo (estrada) + marcas (onda, batida) +
                      MARCA do alvo (tiro/golpe) + PERSEGUIÇÃO + AUTONOMIA
```

Tempo **simulado** (`tempo_ms`): teste, demo e oráculo são determinísticos.

## A regra de ouro: um dedo faz tudo

| gesto | vira |
|---|---|
| **1 dedo arrastando** (acima de 16 px) | **caminho**, desenhado **AO VIVO** (sem espera) |
| **laço** no caminho | **DESLIGADO na v0.11.5** (era ataque em área: uma onda que crescia do centro do laço). Hoje o círculo é **só caminho** — a rota é andada e nada acende. O código da onda fica atrás de `formas.laco_ataque` |
| **bico** (ida e volta brusca, em "T" ou "V") | **v0.11: o bico é ANDADO** — o traço é obedecido como foi desenhado, nada é ignorado |
| **levar o fim do caminho até o alvo** | ele fica **MARCADO** (um "X" amarelo que anda com ele); a marca vale para o **tiro** e para o **golpe físico** — e está ligada ao caminho. **v0.11.4:** a marca segue a **PONTA** do traço — passar por cima e **seguir longe** não marca (não há volta para bater) |
| **passar por cima** de um alvo com a linha | **batida/empurrão** ao chegar naquele ponto (embalo longo) |
| **terminar o caminho** com alvo marcado | o animal **vai atrás** (perseguição final) e só bate **ao chegar perto**. Com o destino longe do alvo **não há marca** e ele **não volta** (v0.11.4) |
| **segurar** | **com um caminho em curso → SPRINT** (acelera e gasta a **barra de energia**); **sem caminho → habilidade em si mesmo** (cavar). Ativa no **limiar** do segurar, sem esperar soltar. **v0.11.4:** ao soltar, o embalo **continua por `sprint.cauda_s`** e cai aos poucos (dá para pular ainda acelerado) |
| **toque simples** | **TIRO** HÍBRIDO: **com alvo marcado**, mirado nele; **sem marca**, na **direção do toque em relação ao animal** (1 s de recarga; o animal **para** para atirar e segue o caminho). Sai ~0,28 s depois, para não atirar no 1º toque de um duplo |
| **toque duplo** | **PULO**. **v0.11.4:** o pulo pedido **durante o ar** entra na **FILA** e sai no quadro em que o anterior pousa (`pular.buffer_s`) — pulsos seguidos emendam sem atraso. **v0.13:** com o **PULO AUTO** ligado (botão da HUD), o corpo pula sozinho o degrau de **1 nível** quando o caminho continua — ver a seção própria |

**Não há gesto de dois dedos** (v0.9 tirou ataque ↑, defesa ↓ e especial
abrindo). Um segundo dedo não é ação: o caminho continua no primeiro dedo e
toque/toque duplo/segurar ficam desarmados — dois dedos nunca "pulam sem
querer".

**Não há efeito de esquiva.** Esquivar é **caminhar**: o tempo lento do desenho
e a rampa de aceleração já dão a janela de reação; a criatura desvia andando.
Defesa também saiu (não há gesto para ela).

## O caminho (um dedo): sem espera, ao vivo, com origem congelada

1. O primeiro dedo desce e a **origem** é congelada: a posição da criatura
   NAQUELE instante (e o mapa tela→mundo daquele instante). A linha **não anda
   junto com o animal** nem com a câmera enquanto o dedo desenha.
2. Passou de `desenho_min_px` (16 px), **já é caminho** — não há espera. A rota
   é refeita a cada quadro e a criatura **já anda por ela**, atrás do traço.
3. Se ela se mexeu até o traço começar, o primeiro trecho da rota a **traz de
   volta ao começo**.
4. Ao soltar, a rota é fechada com o último trecho. O **alvo** é marcado
   **durante** o caminho: quando a ponta do traço alcança um adversário, ele
   fica marcado (e a marca **anda com ele**, ligada a este caminho).
5. **Sensibilidade**: `desenho.ganho` (1,6) multiplica o traço.

### Estrada, caminho orgânico e inércia (v0.9.1+ / v0.11.3)

A linha desenhada é o **eixo de uma ESTRADA**, não a risca que a criatura pisa:

- a criatura anda **por dentro da faixa** (`estrada_largura_px` = 30 px, ±15):
  pode ir mais à esquerda, mais à direita ou no centro;
- o desvio lateral é uma **onda suave** (`estrada_desvio_px` = 9 px, dois
  períodos de `estrada_onda_px` 120 e `estrada_onda2_px` 47, com fases
  sorteadas pela semente): o caminho do animal **não fica retilíneo**;
- ela **mira o ponto mais LONGE da estrada que a VISÃO alcança andando**
  (`olhar_px` = 22 px de horizonte, amostras de 2 px) e só aceita o que está
  **NA FRENTE** do sentido atual. É o que faz a criatura **contornar** a curva
  em vez de cortar a corda por dentro de uma pedra/beira de mar — e o que faz
  ela **chegar na ponta do bico** em vez de virar antes;
- o **desvio orgânico lateral** só vale se o ponto desviado também for
  alcançável: perto da barreira ele volta ao eixo da estrada;
- a criatura vai até o **fim na velocidade normal**. A frenagem é uma
  **INÉRCIA curta DEPOIS do fim** (`freio_extra_px` = 16 px, ~0,3 s), fora da
  rota: ela passa do último ponto e para logo adiante. No **SPRINT manual** a
  frenagem é um pouco maior (`freio_sprint_x` = 1,6×, ~26 px). `parada_px` = 4
  é a folga para virar `rota:fim`;
- **v0.10+:** com ALVO MARCADO o fim não freia: começa a perseguição/golpe.

Um tronco no caminho: o alvo à frente **pula** o ponto que cai dentro dele e a
criatura contorna com o leque de desvios; o **lado** é mantido (histerese), mas
se aquele lado não passar ela **tenta o outro** — nunca fica presa na beirada.

### Água, rocha e DESNÍVEL (v0.11.2 / v0.11.3)

A mesma regra do tronco vale para **qualquer barreira** que o traço atravesse
— água, rocha e **encosta/desnível** — **quando a rota volta a um ponto
alcançável**:

- a barreira é lida como **"não dá para ANDAR"** (`Mundo.caminho_livre` entre
  as amostras da rota, de 4 px): pega água, rocha, **degrau de altura > 0,5**
  e canto diagonal — não só o `bloqueio` de terreno;
- se a rota entra na barreira **perto do horizonte** (`olhar_px` + 24 px) e
  encontra um ponto **andável e de nível alcançável** (mesmo nível ±0,5, ou
  mais baixo) **de volta**, a criatura entende que o destino não é a barreira:
  **mira a continuação** e usa o **mesmo leque de desvios**. O topo de um
  barranco (mais alto) não conta como continuação; a volta por baixo/rampa
  conta;
- a continuação precisa estar a **`contorno_raio_px` = 128 px** do animal (raio
  x próximo, ~4 células) e a **`contorno_alcance_px` = 260 px** de arco — um
  rio/lago/encosta longe demais fica de fora;
- **se a rota termina no bloqueio**, não há continuação: para na fronteira. O
  **PULO** é o que atravessa (e enquanto está no ar a checagem do chão é
  ignorada, como já era);
- **teimosia limitada:** um contorno que roda `desvio_teimoso_apos` = 36
  passos sem a rota andar 6 px para na fronteira em vez de ficar indo e
  voltando no muro. Um caminho novo ou um pulo reinicia.

### Direção estável (v0.11.3)

O alvo da estrada pode andar 2 px de um quadro para o outro; a criatura não
pisca a direção por causa disso:

- `_dir_suave` filtra a direção de **andar** e `_olhar_suave` a direção
  **desenhada** (`giro_suavidade` = 10/s, `giro_max_graus_s` = 720°/s): no
  máximo ~24° por quadro a 30 fps (12° a 60 fps);
- o **ângulo do contorno** é mantido (`_desvio_angulo`): o leque tenta o mesmo
  ângulo do quadro anterior antes de escolher outro, então o desvio vira uma
  linha estável em vez de uma escolha nova a cada quadro;
- o passo REAL continua sendo o do desvio (a segurança de não entrar na
  barreira é do `_passo_com_desvio`); a suavização é da direção, não da
  checagem de colisão.

### Amontoados e laços minúsculos (v0.11.1)

O traço tem ruído: um laço de 20 px, um cruzamento de passagem, um vai-e-volta
nervoso. Andar isso não parece intenção — parece tremida, e ainda pode acender
a área por engano. Depois do Douglas-Peucker:

- **`Trajetoria.limpar_amontoados`** corta o trecho que sai e **volta para
  dentro de `amontoado_raio_px` = 24 px** em menos de
  `amontoado_janela_px` = 100 px de arco (a **zona do tamanho do animal**); a
  rota liga o ponto anterior direto ao ponto de retorno. O corte só é aceito se
  o atalho for **andável** (`mundo.caminho_livre`);
- o teste é o **RETORNO**, não a proximidade: o arco precisa ser bem maior do
  que a distância líquida (`arco ≥ d·1,8 + 12`) — reta e curva de verdade não
  são tocadas;
- **laço mínimo para a ÁREA (v0.11.5: sem efeito, a área está desligada):**
  `laco_area_min` 2200 px², `laco_arco_min` 160 px e `laco_raio_min` 28 px
  (≈1,4× a área do corpo de 40×40). Abaixo disso o traço não virava marca.

### O laço e o bico são ANDADOS (v0.11.1)

Duas peças garantem que o traço não seja "cortado" no cruzamento:

- **projeção com continuidade**: o ponto da rota onde a criatura está custa
  `distância + 0,25 × |arco − arco_esperado|`; num cruzamento (ou num bico,
  cujos dois braços são a MESMA linha) ela continua o braço que já andava em
  vez de pular para a volta. Um teto de segurança limita o avanço por quadro;
- **alvo na frente**: o alvo da estrada precisa estar no sentido do trecho
  atual; no bico, o braço de volta fica atrás e é rejeitado até ela cruzar a
  ponta. Na volta, a projeção já está do outro lado e ela segue.

### Desconto inicial

Ao começar um traço é comum um pequeno **vai e volta**; obedecer isso faz a
criatura ir e voltar antes de seguir. `sim/trajetoria.descontar_inicio`
descarta esse trecho (volta de verdade ≥ 6 px, dentro de
`desconto_janela_px` = 140 px, alinhando a `desconto_raio_px` = 44 px).

**v0.11:** o espinho (bico) é **andado** como foi desenhado; o desconto inicial
continua valendo só para o tremor do começo (um bico grande no começo não é
cortado porque o desconto só mexe no primeiro vai-e-volta curto).

### Pontos de referência, não o traço inteiro

O traço é reduzido com Douglas-Peucker (`Trajetoria.simplificar`,
`simplificar_px` = 10). **v0.9:** a distância é ao **segmento**, não à reta
infinita — um ponto que passa da PONTA do segmento conta como desvio. É o que
mantém a **ponta de um bico** na rota (na reta infinita a ida e a volta se
anulavam e a criatura nunca chegava a fazer o espinho).

A criatura procura a rota **em ordem**, mirando o ponto mais longe que a visão
alcança. Em **objetos** (troncos) ela contorna com um leque de pequenos desvios
(com o lado mantido; se não passar, troca de lado); **terreno** (água/rocha)
também é contornado **quando a rota volta à terra perto** (v0.11.2); se a rota
termina no bloqueio — ou a continuação está longe/fora do raio — é barreira de
verdade: para e espera, e a rota **não é apagada** (um pulo passa por cima e
retoma). A criatura **não corta a curva** da rota: se a linha passa perto da
água e faz a volta, ela segue a linha, não a corda.

### A LINHA do caminho (v0.9.2 / v0.11.3)

A linha desenhada mostra o **traço real do dedo** — os pontos **densos** do
desenho, não a rota simplificada (que traçava retas entre os pontos de
referência e ficava quebrada):

- **contínua**: os pontinhos seguem a curva de verdade (o espaçamento é por
  ARCO, então não há "emenda" de retas);
- **pontilhada**, **escura e transparente** (azul-quase-preto a 55%) e **no
  chão** (`z_index` 1, embaixo dos objetos e da criatura);
- a **rota** (a estrada) continua sendo a referência do movimento — a linha é o
  desenho, o animal anda dentro da faixa;
- **v0.11.3: a linha APAGA o trecho já andado.** `sim/corpo.gd` projeta a
  criatura no traço cru (`traco_t`, contínuo e sem voltar) e `jogo/trilha.gd`
  desenha só do corte para a frente, com um **rabinho de fade** de 22 px atrás.
  O que já passou some; o caminho à frente fica inteiro.

## As formas (o ataque nasce do desenho)

Tudo em `sim/formas.gd` (puro). O traço CRU é lido antes de virar rota:

| forma | como é reconhecida | o que a marca guarda |
|---|---|---|
| **laço** | o traço volta e **cruza** a si mesmo; a área fechada tem `laco_area_min` (2200 px²) e o arco `laco_arco_min` (160 px) — tamanho mínimo v0.11.1 | o **nó**, o **centro** (centroide da área), o **raio** (`√area/π`, limitado a 28–120 px) e a direção do fechamento |

- **Laço → onda em área (DESLIGADO na v0.11.5).** `formas.laco_ataque`
  falso faz `Formas.analisar` devolver `[]` **sem nem reduzir o traço**: o laço
  não vira marca. A regra fica registrada para quando (se) voltar: a marca
  acendia quando a **distância da criatura ao CENTRO** do laço era
  ≤ `area_gatilho_px` (224 px ≈ 7× o corpo), sem precisar chegar no anel; a
  onda era um círculo que cresce do centro e empurra quem varre.
- **O bico é andado.** O espinho faz parte do traço: a criatura sai, vai até a
  ponta e volta, como desenhado. (v0.10 ele era ignorado; v0.11 não é mais.)
- **Sem "desenho certo":** as marcas são lidas a cada ~5 pontos do traço; o
  que já acendeu não volta, e a marca é a mesma mesmo redesenhando por cima.

## A MARCA do alvo e o TIRO HÍBRIDO (v0.10/v0.11.1)

O jogador **leva o fim do caminho até o alvo** (durante o desenho ou a
caminhada): quando a ponta do traço alcança um adversário, ele fica **marcado**
("X" amarelo no inimigo, andando com ele). A marca é **ligada ao caminho**.

O **toque simples** atira **sempre**, de duas formas:

- **com alvo marcado**: automira nele (como na v0.10). O ponto do toque **não**
  muda a direção;
- **sem marca**: **não é auto-mirado** — a direção é do **animal para o ponto
  tocado na tela** (`cmd.alvo`, convertido para mundo). Tocar em cima dela usa
  o olhar;
- nos dois: a criatura **para** `tiro_pausa_s` (0,25 s), tem
  `tiro_recarga_s` (1 s) e **segue o caminho**;
- **não sai** com o disparo — dá para atirar de novo após a recarga;
- a marca **sai** quando o animal faz o **golpe físico** (chegar no alvo) ou
  quando um **novo caminho** começa. Se o alvo marcado sumir, a marca cai e o
  toque vira um tiro livre.
- **v0.11.4 — a marca acompanha a PONTA:** ela só nasce enquanto a ponta do
  traço está no alvo e **sai** se o traço continua e termina mais de
  `combate.mira_final_raio` (34 px) longe dele (`_soltar_marca_longe_da_ponta`;
  evento `mira_final:` vazio). Um caminho que **passa por cima** (batida) e
  **segue** para longe não volta para dar o golpe de perseguição. Depois de
  soltar o dedo, a marca **não é revalidada**: ela anda com o alvo, como antes.

## Travessia e alvo final (no `sim/corpo.gd`)

- **Travessia:** se a rota passa **por cima** de um alvo (a menos de
  `raio + batida_cruza_px` = +8 px do centro), a marca de **batida** nasce
  naquele ponto. Ao chegar, se o alvo ainda está ali (`batida_tol_px` = 34 px),
  a criatura **bate e empurra** (adversário desliza 26 px e pisca; árvore só
  leva a batida, porque não se move).
- **Alvo final / perseguição:** com alvo marcado, no fim do caminho o animal
  **vai atrás dele** (perseguição final, `embalo.perseguir_s` 3 s de teto, sem
  freio antes do fim) e só dá o **golpe físico** quando chega perto
  (`ataque.alcance` + raio + 10 px). Se o alvo estiver inalcançável/tempo
  esgotar, a marca se perde (`mira_final:perde`). A marca **sai no golpe**.
  (v0.10 tirou a "automira perdida se ele andar > 48 px": o animal persegue.)

## Segurar: SPRINT no caminho, habilidade sem caminho (v0.11)

Segurar o dedo **parado** (sem arrastar) por `segurar_min_ms` (380 ms) ativa o
gesto **na hora** (no limiar, sem esperar soltar). Quem decide o que ele faz é o
corpo:

- **com um caminho em curso → SPRINT**: o animal acelera (`sprint.fator` 1,7×)
  enquanto o dedo fica e **gasta a BARRA DE ENERGIA** (`sprint.gasto_s` 0,45/s);
  ao soltar (ou quando a energia acaba), a energia **recupera**
  (`sprint.recarga_s` 0,22/s). A barra aparece na HUD (embaixo, à esquerda) e
  fica laranja quando está baixa. Com alvo marcado ou não, funciona igual;
- **v0.11.4 — a CAUDA:** soltar não corta a velocidade na hora. `_fator_sprint`
  mantém o embalo por `sprint.cauda_s` (0,60 s) em **queda linear de 1,7× até
  1,0×** (a energia só é gasta segurando). É ela que deixa **pular ainda
  acelerado**: o pulo sobe a mesma altura, mas o **avanço horizontal** cresce;
- **v0.13 — o ar acelera MAIS:** com o sprint (ou a cauda) ativo, o avanço
  horizontal **no ar** ganha `pular.sprint_fator` (1,5) — o fator só vale
  durante o pulo, a caminhada acelerada não mudou. Medido em teste: pulo
  normal 46,9 px; acelerado **66,8 → 98,2 px** (de ~2,1 para ~3,1 células). Um
  vão de 2 células, que antes só passava no sprint apertado, passa com folga;
- **sem caminho → HABILIDADE em si mesmo** (hoje: **cavar**), ativada no
  limiar: desce ao subsolo em célula escavável e sobe de novo do subsolo. A
  habilidade dura o tempo das fases (`cavar.fases`). A HUD diz o motivo quando
  não dá para cavar.

## Pulo automático (v0.13)

Um **botão na HUD** (`PULO AUTO: LIGADO/DESLIGADO`, canto superior esquerdo)
liga e desliga o sistema; o padrão vem de `pular.auto_padrao` (**falso** — o
jogo continua igual até o jogador ligar). O estado é do corpo
(`sim/corpo.gd: pulo_auto`), então o teste e a simulação usam a mesma regra.

Ligado, quando a **rota para na beirada** e o desenho **continua**:

| situação | pula sozinho? |
|---|---|
| célula à frente é **andável 1 nível acima** (passarela/planalto) | **sim** |
| **vão de água curto** antes do degrau de 1 nível, com o pouso **dentro do alcance** | **sim** (cruza o vão e sobe) |
| vão de **2 células** antes do degrau, sem sprint | **não** (pousaria na água) |
| o mesmo vão **com sprint** (o pulo alonga) | **sim** |
| água no **mesmo nível**, rocha/objeto, degrau de **2+ níveis** | **não** |
| o caminho **acaba** na beirada (nada do outro lado) | **não** |

O disparo é o **mesmo** `_iniciar_pulo` do toque duplo (respeita a recarga) e
sai com o evento `pulo:on` + `pulo:auto`. Não há "pular no vazio": a decisão
checa o **pouso dentro do alcance** e a **continuação** da rota depois dele.

## Tempo lento, escurecida e a rampa de saída

Só o **desenho confirmado** desacelera: `planejamento.escala_tempo` (0,35×), a
tela escurece `planejamento.escurecer` (0,22) e, ao soltar, o tempo acelera
numa rampa de `planejamento.retomada_ms` (0,45 s). Segurar para a habilidade
**não** desacelera o mundo.

## Overlays

| overlay | o que faz | efeito na rota |
|---|---|---|
| **onda** (laço) | círculo que cresce do centro do laço e empurra quem varre — **DESLIGADA desde a v0.11.5** (`formas.laco_ataque`) | nenhum: continua andando |
| **tiro** (toque simples) | projétil no alvo marcado (automira) ou na direção do toque (sem marca); para no primeiro alvo | nenhum: o animal PAUSA para atirar e segue |
| **golpe** (`ataque`/`batida`) | arco de fases (antecipação → ativa → recuperação) | nenhum |
| **pulo** | arco no ar enquanto segue; atravessa barreira; **v0.13:** o automático sobe o degrau de 1 nível quando a rota continua | nenhum |
| **habilidade** | em si mesmo, com duração; cavar troca de camada | cavar apaga a rota (outra camada) |

## Autonomia (sem rota)

Ao terminar a rota, a criatura decide sozinha, com sorteio **semeado**:
**fica parada**, **vagueia devagar** ou, se há alvo marcado, **aproxima** dele e
depois **ronda** ao redor. Cada passo é cortado pelo mundo.

## Ações (`dados/acoes.json`)

| ação | parâmetros |
|---|---|
| `mover` | `velocidade` 110 px/s |
| `ataque` | golpe físico do fim do caminho: `fases` [0,10 · 0,14 · 0,18] s, `alcance` 40, `arco` 90°, `recarga` 0,15 |
| `batida` | pancada de travessia: `fases` [0,06 · 0,10 · 0,12] s, `alcance` 30, `arco` 120° |
| `pular` | `fases` [0,06 · 0,42 · 0,06] s, `altura` 26 px, `recarga` 0,08 (cooldown de POUSO), `buffer_s` 0,60 (fila do pulo no ar), `auto_padrao` falso (PULO AUTO começa desligado), `sprint_fator` 1,5 (avanço no ar com sprint) |
| `habilidade` | `nome` = `cavar` (o que o segurar ativa) |
| `cavar` | `fases` [0,15 · 0,55 · 0,15] s |
| `formas` | limiares do laço (tabela abaixo) |
| `sprint` | aceleração do segurar no caminho (tabela abaixo) |
| `combate` | onda/tiro/batida/alvo final (tabela abaixo) |
| `rota` | `simplificar_px` 10 · `desconto_raio_px` 44 · `desconto_janela_px` 140 · `amontoado_raio_px` 24 · `amontoado_janela_px` 100 · `contorno_alcance_px` 260 · `contorno_raio_px` 128 · `desvio_teimoso_*` 36/6 · **estrada/inércia** abaixo |

### `embalo` — a aceleração dos golpes físicos (v0.9.2)

| chave | valor | o quê |
|---|---|---|
| `curto_s` / `curto_fator` | 0,25 s / 1,7× | EMBALO CURTO da **marcação** (golpe final) |
| `longo_s` / `longo_fator` | 0,6 s / 2,0× | EMBALO LONGO do **empurrão** (travessia) |
| `gatilho_px` | 70 | a que distância do alvo final a marcação embala |
| `perseguir_s` | 3,0 s | teto da perseguição final |

O embalo é um **pico de velocidade** que sobe e desce suave (`sin(π·u)`): o
empurrão embala antes e **passa mais rápido que a caminhada normal** pelo alvo,
desacelerando depois da batida; a marcação dá um puxão curto na direção do alvo
final. O cooldown de 1 s segura a marca do especial (ela fica **pendente** e
acende quando a recarga termina).

### `rota` — estrada, visão, contorno e inércia (v0.9.1+ / v0.11.3)

| chave | valor | o quê |
|---|---|---|
| `olhar_px` | 22 | horizonte do alvo (o ponto mais longe **visível e à frente**) |
| `alvo_pulo_objeto_px` | 56 | quanto o alvo nominal pode pular um tronco para o desvio trabalhar |
| `projecao_peso` | 0,25 | peso do desvio de ARCO na projeção (continuidade no laço/bico) |
| `amontoado_raio_px` / `amontoado_janela_px` | 24 / 100 | zona do amontoado e arco máximo do corte |
| `contorno_alcance_px` / `contorno_raio_px` | 260 / 128 | arco máximo e raio do contorno de **água/rocha** até a terra |
| `desvio_teimoso_apos` / `desvio_teimoso_px` | 36 / 6 | passos de contorno sem progresso antes de parar na fronteira |
| `estrada_largura_px` | 30 | largura da estrada (±15 px) |
| `estrada_desvio_px` | 9 | amplitude do desvio orgânico lateral |
| `estrada_onda_px` / `estrada_onda2_px` | 120 / 47 | os dois períodos da onda do desvio |
| `giro_suavidade` / `giro_max_graus_s` | 10 / 720 | filtro e teto de giro da direção (estabilidade) |
| `freio_extra_px` / `freio_sprint_x` | 16 / 1,6× | INÉRCIA depois do fim; no sprint ×1,6 |
| `parada_px` | 4 | folga para virar `rota:fim` (a inércia continua) |

### `formas`

| chave | valor | o quê |
|---|---|---|
| `laco_ataque` | **falso** | v0.11.5: liga/desliga o ataque em área do laço (falso = o laço é só caminho) |
| `gatilho_raio_px` | 24 | distância da marca que acende o gatilho |
| `laco_arco_min` | 160 | arco mínimo do laço (tamanho mínimo v0.11.1) |
| `laco_area_min` | 2200 | área mínima (px²) — abaixo disso não acende a área |
| `laco_raio_min` / `laco_raio_max` | 28 / 120 | raio da onda |
| `laco_dedupe_px` | 26 | laços repetidos |

### `sprint` — a aceleração do segurar no caminho (v0.11)

| chave | valor | o quê |
|---|---|---|
| `fator` | 1,7× | quanto acelera |
| `gasto_s` / `recarga_s` | 0,45 / 0,22 por s | quanto a barra gasta e quanto recupera |
| `cauda_s` | 0,60 s | v0.11.4: quanto o embalo dura DEPOIS de soltar (1,7× → 1,0×) |
| `minimo` | 0,08 | energia mínima para começar o sprint |

### `combate`

| chave | valor | o quê |
|---|---|---|
| `onda_velocidade` / `onda_empurrao` | 140 px/s / 30 px | expansão e empurrão da onda |
| `tiro_velocidade` / `tiro_alcance` | 420 px/s / 280 px | tiro do toque simples (no alvo marcado) |
| `tiro_raio` / `tiro_empurrao` | 9 / 24 px | acerto e empurrão do tiro |
| `batida_cruza_px` / `batida_tol_px` | 8 / 34 px | quando a linha "passa por cima" e a tolerância na chegada |
| `batida_empurrao` | 26 px | empurrão da batida |
| `onda_recarga_s` / `tiro_recarga_s` | 1,0 s | **cooldown** dos especiais (área/tiro) |
| `area_gatilho_px` | 224 | distância da criatura ao **centro** que acende a área (≈7× o corpo) |
| `tiro_pausa_s` | 0,25 s | a pausa do animal para atirar |
| `mira_final_raio` | 34 px | onde o fim do caminho MARCA o alvo — e o quanto a PONTA pode se afastar dele sem perder a marca (v0.11.4) |
| `mira_final_empurrao` | 44 px | empurrão do golpe final |

## O inimigo hostil (v0.14)

- **Botão HOSTILIDADE** na HUD: liga/desliga a caçada em todos os adversários.
  Desligado, ele é o passeio de sempre (vagueia, leva empurrão e pisca).
- **Caçada:** 104 px/s (o passeio é 26), zigue-zague na aproximação, **órbita**
  a 70 px e abre espaço quando encosta. Mesma semente = mesma caçada; ele não
  entra na água (o mundo corta o passo).
- **Preparação + área no chão:** toda ação tem `fases` = [preparo, ativo,
  recuperação] (o mesmo formato da criatura). No preparo ele **para**, a área
  acende no chão, o miolo enche e a borda pisca perto do fim. Levar um golpe
  cancela o ataque em preparo.
- **As quatro ações:** **bote** (até 78 px) = círculo de raio 30 no lugar onde
  o jogador estava; **esbarrão** (80–240 px) = faixa de 34 px de largura,
  corrida a 380 px/s; **cuspe** (150–460 px) = linha fina, projétil a 280 px/s;
  **esconder** (especial) = afunda, fica **intocável** 2 s e reaparece a
  ~110 px do jogador (recarga 7 s; dispara ao levar um golpe).
- **O golpe no jogador:** empurrão + atordoamento curto (sem vida, decisão do
  operador); 0,8 s de invencibilidade depois de levar um; atordoada, a criatura
  **não obedece** e a rota espera.
- **Onde fica:** regra em `sim/adversario.gd`; área no chão e projétil em
  `jogo/perigos.gd`; número em `dados/adversario.json`.

## Alvos

- **Adversário:** fica **marcado** quando o fim do caminho o alcança (X amarelo
  que anda com ele); é o alvo do **tiro** (toque simples) e do **golpe físico**
  (a marca sai no golpe, ou num caminho novo).
- **Árvore:** alvo da **batida de travessia** (leva a pancada, mas não é
  empurrada — não reage).
- **Baú:** ficou **sem gesto** na v0.10 (o toque virou PULO) — ver RESIDUOS.
- A **mira vermelha** (travar no toque) também ficou sem gesto; o código do
  `travar`/`alvo_id` continua no corpo, sem uso.

## Como mudar sem tocar em código

- **Ação de cada gesto**: `mapa` em `dados/gestos.json`.
- **Sensibilidade do desenho**: `desenho.ganho`.
- **Segurar/planejamento**: `limiares` e `planejamento`.
- **O que é laço** (e se ele ataca): `formas.laco_ataque` e os limiares `laco_*` em `dados/acoes.json`.
- **O que cada ataque faz no alvo**: `combate` (empurrões, alcances, raio).
- **Inimigo hostil**: `dados/adversario.json` (movimento, as quatro ações,
  recarga do esconder) e `reacao` em `dados/acoes.json` (invencibilidade e
  velocidade do empurrão).
- **Peso de cada ação**: fases/alcance/arco em `dados/acoes.json`.
- **Caminho** (simplificação, desconto, desvio, chegada): bloco `rota`.

## O que fica para depois

- **Dano e vida**: agora o adversário **ataca** (v0.14), mas ninguém tem vida:
  o golpe dele é empurrão + atordoamento e o seu é empurrão. Vida/derrota
  continua sendo uma decisão futura.
- **Defesa e esquiva como efeito**: não existem (esquivar é andar).
- **Especiais por criatura/evolução** (P4/P5).
- **Afinidade** (P4): hoje a criatura obedece.
- **Habilidades além de cavar**: o estado genérico está pronto (nome +
  `duracao`), falta conteúdo.
- **Bico**: é **andado** como desenhado (v0.11) e não tem ataque próprio; o
  espinho pode deixar o caminho mais longo.
- **Baú e mira vermelha**: sem gesto desde a v0.10 (o toque é o pulo) — o baú
  precisa de um gatilho novo.
- **Estrada**: a largura, a amplitude/onda, a inércia (`freio_extra_px`,
  `freio_sprint_x`) e o giro (`giro_suavidade`/`giro_max_graus_s`) são pontos
  de partida — ajustar no aparelho com o operador.
- **Contorno de altura**: o topo do barranco não é continuação; se a rota
  termina lá, para (o pulo sobe/desce).
- **Linha**: mostra o traço CRU do dedo (inclusive o beco e o tremor inicial);
  se o operador preferir a linha do **caminho andado** (o rastro do animal), é
  outra decisão.
- **Embalo/cooldown**: os valores (0,25 s/1,7× e 0,6 s/2,0× · 1 s) são pontos
  de partida.
