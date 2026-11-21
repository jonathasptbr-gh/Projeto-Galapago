# Gestos e ações — como a criatura se move e age

> Regra toda em `sim/` (testada) e nas tabelas `dados/gestos.json` +
> `dados/acoes.json` (editáveis); `jogo/` só desenha. **v0.10.**

## O fluxo

```
dedos (toque real ou demo roteirizada — mesmo caminho)
  → sim/gestos.gd   : UM dedo = caminho · toque · toque duplo · segurar
  → sim/formas.gd   : lê a FORMA do traço (laço; o beco do bico sai da rota)
  → sim/comandos.gd : traduz o gesto em COMANDO (ação + alvo no mundo)
  → sim/corpo.gd    : ROTA ao vivo (estrada) + marcas (onda, batida) +
                      MARCA do alvo (tiro/golpe) + PERSEGUIÇÃO + AUTONOMIA
```

Tempo **simulado** (`tempo_ms`): teste, demo e oráculo são determinísticos.

## A regra de ouro: um dedo faz tudo

| gesto | vira |
|---|---|
| **1 dedo arrastando** (acima de 16 px) | **caminho**, desenhado **AO VIVO** (sem espera) |
| **laço** no caminho | **ataque em área**: uma onda que cresce do **centro** do laço; a trava é a **distância da criatura ao centro** (`area_gatilho_px` = 224 px, ~7× o corpo) — não precisa chegar no anel |
| **bico** (ida e volta brusca, em "T" ou "V") | o **beco sai da rota** (o animal não entra nele). **v0.10: o bico NÃO atira mais** — o tiro virou o toque duplo |
| **levar o fim do caminho até o alvo** | ele fica **MARCADO** (um "X" amarelo que anda com ele); a marca vale para o **tiro** e para o **golpe físico** — e está ligada ao caminho |
| **passar por cima** de um alvo com a linha | **batida/empurrão** ao chegar naquele ponto (embalo longo) |
| **terminar o caminho** com alvo marcado | o animal **vai atrás** (perseguição final, sem a zona de freio) e só bate **ao chegar perto** |
| **segurar parado** (em qualquer lugar) | **habilidade em si mesmo** (hoje: cavar) |
| **toque simples** | **PULO** (o toque deixou de marcar alvos; ele sai ~0,28 s depois, para não pular no 1º toque de um duplo) |
| **toque duplo** | **TIRO** mirado no **alvo marcado** (1 s de recarga; o animal **para** para atirar e segue o caminho) |

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

### Estrada, caminho orgânico e zona de freio (v0.9.1+)

A linha desenhada é o **eixo de uma ESTRADA**, não a risca que a criatura pisa:

- a criatura anda **por dentro da faixa** (`estrada_largura_px` = 30 px, ±15):
  pode ir mais à esquerda, mais à direita ou no centro;
- o desvio lateral é uma **onda suave** (`estrada_desvio_px` = 9 px, dois
  períodos de `estrada_onda_px` 120 e `estrada_onda2_px` 47, com fases
  sorteadas pela semente): o caminho do animal **não fica retilíneo**;
- ela **mira um ponto À FRENTE** (`olhar_px` = 22 px) da estrada + o desvio:
  o percurso vira uma curva, em vez de ir reto de ponto em ponto;
- os **pontos de referência** continuam sendo o eixo da estrada (a rota), não a
  obrigação de pisar neles;
- no fim há uma **ZONA DE FREIO** (`freio_px` = 44 px, mínimo `freio_min` =
  0,12): a velocidade cai suave (`smoothstep`) e a criatura **para onde está**,
  sem salto para o último ponto (`parada_px` = 4). **v0.10: com ALVO MARCADO
  não há freio** — o animal chega em velocidade cheia para perseguir/bater.

Um tronco no caminho: o alvo à frente **pula** o ponto que cai dentro dele e a
criatura contorna por um lado, **mantendo o lado** até passar (sem ficar
oscilando na beirada).

### Desconto inicial

Ao começar um traço é comum um pequeno **vai e volta**; obedecer isso faz a
criatura ir e voltar antes de seguir. `sim/trajetoria.descontar_inicio`
descarta esse trecho (volta de verdade ≥ 6 px, dentro de
`desconto_janela_px` = 140 px, alinhando a `desconto_raio_px` = 44 px).

**Exceção v0.9:** se o traço **começa com um bico** (do ponto de partida), o
vai-e-volta é ATAQUE, não tremor de dedo: o desconto é **pulado** e a rota
começa pelo espinho.

### Pontos de referência, não o traço inteiro

O traço é reduzido com Douglas-Peucker (`Trajetoria.simplificar`,
`simplificar_px` = 10). **v0.9:** a distância é ao **segmento**, não à reta
infinita — um ponto que passa da PONTA do segmento conta como desvio. É o que
mantém a **ponta de um bico** na rota (na reta infinita a ida e a volta se
anulavam e a criatura nunca chegava a fazer o espinho).

A criatura procura **um ponto por vez, na ordem**. Em **objetos** (troncos) ela
contorna com um leque de pequenos desvios; **terreno** (água, rocha, altura) é
barreira: para e espera, mas a rota **não é apagada** — um pulo passa por cima
e retoma.

### A LINHA do caminho (v0.9.2)

A linha desenhada mostra o **traço real do dedo** — os pontos **densos** do
desenho, não a rota simplificada (que traçava retas entre os pontos de
referência e ficava quebrada):

- **contínua**: os pontinhos seguem a curva de verdade (o espaçamento é por
  ARCO, então não há "emenda" de retas);
- **pontilhada**, **escura e transparente** (azul-quase-preto a 55%) e **no
  chão** (`z_index` 1, embaixo dos objetos e da criatura);
- a **rota** (a estrada) continua sendo a referência do movimento — a linha é o
  desenho, o animal anda dentro da faixa.

## As formas (o ataque nasce do desenho)

Tudo em `sim/formas.gd` (puro). O traço CRU é lido antes de virar rota:

| forma | como é reconhecida | o que a marca guarda |
|---|---|---|
| **laço** | o traço volta e **cruza** a si mesmo; a área fechada tem `laco_area_min` (700 px²) e o arco `laco_arco_min` (90 px) | o **nó**, o **anel** (a circunferência fechada), o **centro** (centroide da área), o **raio** (`√area/π`, limitado a 24–120 px) e a direção do fechamento |
| **bico** | uma **PONTA** (reversão de ~180°) e uma **BASE**: a volta reencontra a estrada numa curva forte (`bico_base_angulo` 45°) ou no fim do traço, perto do traço anterior — o espinho é estreito (o traço não se afasta da reta base→ponta) | a **base**, a **ponta**, a **direção** e os índices `i`/`j` do trecho a **cortar** |

- **Laço → onda em área.** A marca acende quando a **distância da criatura ao
  CENTRO** do laço é ≤ `area_gatilho_px` (224 px ≈ 7× o corpo de ~32 px) — não
  precisa chegar no anel nem no nó. Laço feito perto: a onda sai **na hora**.
  A onda é **um círculo que cresce do centro**; varre e empurra quem está na
  área.
- **Bico → só o beco sai da rota.** O espinho continua sendo lido (o "T"/"V"),
  e o trecho `i+1..j` **não é andado**. **v0.10: o bico não atira**; o tiro é o
  **toque duplo** no alvo marcado (o gesto do bico fica como um "beco sem
  saída" ignorado — ver RESIDUOS).
- **Sem "desenho certo":** as marcas são lidas a cada ~5 pontos do traço; o
  que já acendeu não volta, e a marca é a mesma mesmo redesenhando por cima.

## A MARCA do alvo e o TIRO (v0.10)

O jogador **leva o fim do caminho até o alvo** (durante o desenho ou a
caminhada): quando a ponta do traço alcança um adversário, ele fica **marcado**
("X" amarelo no inimigo, andando com ele). A marca é **ligada ao caminho**:

- vale para o **TIRO** (toque duplo): a criatura **para** `tiro_pausa_s`
  (0,25 s), atira **mirada no alvo marcado**, tem `tiro_recarga_s` (1 s) e
  **segue o caminho**;
- **não sai** com o disparo — dá para atirar de novo após a recarga;
- **sai** quando o animal faz o **golpe físico** (chegar no alvo) ou quando um
  **novo caminho** começa;
- sem alvo marcado, o toque duplo **não dispara** (a HUD diz "sem alvo
  marcado").

## Travessia e alvo final (no `sim/corpo.gd`)

- **Travessia:** se a rota passa **por cima** de um alvo (a menos de
  `raio + batida_cruza_px` = +8 px do centro), a marca de **batida** nasce
  naquele ponto. Ao chegar, se o alvo ainda está ali (`batida_tol_px` = 34 px),
  a criatura **bate e empurra** (adversário desliza 26 px e pisca; árvore só
  leva a batida, porque não se move).
- **Alvo final / perseguição:** com alvo marcado, no fim do caminho o animal
  **vai atrás dele** (perseguição final, `embalo.perseguir_s` 3 s de teto, sem
  a zona de freio) e só dá o **golpe físico** quando chega perto
  (`ataque.alcance` + raio + 10 px). Se o alvo estiver inalcançável/tempo
  esgotar, a marca se perde (`mira_final:perde`). A marca **sai no golpe**.
  (v0.10 tirou a "automira perdida se ele andar > 48 px": o animal persegue.)

## Segurar parado = habilidade em si mesmo

Parado sem arrastar por `segurar_min_ms` (380 ms), o gesto é uma **habilidade
de si mesmo** — em qualquer lugar da tela (não precisa ser em cima do animal).
A primeira é **cavar** (a que existia): desce ao subsolo em célula escavável e
sobe de novo do subsolo. A habilidade dura o tempo das fases dela
(`dados/acoes.json`, `cavar.fases`) e é recusada onde não dá para cavar (a HUD
diz o motivo). O estado genérico já existe para as próximas (basta uma entrada
com `duracao` em `acoes.json` e o nome em `habilidade.nome`).

## Tempo lento, escurecida e a rampa de saída

Só o **desenho confirmado** desacelera: `planejamento.escala_tempo` (0,35×), a
tela escurece `planejamento.escurecer` (0,22) e, ao soltar, o tempo acelera
numa rampa de `planejamento.retomada_ms` (0,45 s). Segurar para a habilidade
**não** desacelera o mundo.

## Overlays

| overlay | o que faz | efeito na rota |
|---|---|---|
| **onda** (laço) | círculo que cresce do centro do laço e empurra quem varre | nenhum: continua andando |
| **tiro** (toque duplo) | projétil mirado no alvo marcado, para no primeiro alvo | nenhum: o animal PAUSA para atirar e segue |
| **golpe** (`ataque`/`batida`) | arco de fases (antecipação → ativa → recuperação) | nenhum |
| **pulo** | arco no ar enquanto segue; atravessa barreira | nenhum |
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
| `pular` | `fases` [0,06 · 0,42 · 0,06] s, `altura` 26 px, `recarga` 0,30 |
| `habilidade` | `nome` = `cavar` (o que o segurar ativa) |
| `cavar` | `fases` [0,15 · 0,55 · 0,15] s |
| `formas` | limiares do laço e do bico (tabela abaixo) |
| `combate` | onda/tiro/batida/alvo final (tabela abaixo) |
| `rota` | `simplificar_px` 10 · `desconto_raio_px` 44 · `desconto_janela_px` 140 · `chegada_px` 12 · `desvio_angulos` · `desvios_max` 80 · **estrada/freio** abaixo |

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

### `rota` — estrada e freio (v0.9.1)

| chave | valor | o quê |
|---|---|---|
| `olhar_px` | 22 | o ponto à frente que a criatura mira (curva o percurso) |
| `estrada_largura_px` | 30 | largura da estrada (±15 px) |
| `estrada_desvio_px` | 9 | amplitude do desvio orgânico lateral |
| `estrada_onda_px` / `estrada_onda2_px` | 120 / 47 | os dois períodos da onda do desvio |
| `freio_px` / `freio_min` | 44 / 0,12 | zona de freio e velocidade mínima |
| `parada_px` | 4 | a que distância do fim ela para |

### `formas`

| chave | valor | o quê |
|---|---|---|
| `gatilho_raio_px` | 24 | distância da marca que acende o gatilho |
| `laco_arco_min` | 90 | arco mínimo do laço |
| `laco_area_min` | 700 | área mínima (px²) |
| `laco_raio_min` / `laco_raio_max` | 24 / 120 | raio da onda |
| `laco_dedupe_px` | 26 | laços repetidos |
| `bico_angulo_min` | 120° | quanto a direção precisa virar na ponta |
| `bico_ponta_min` | 18 | altura mínima do espinho |
| `bico_janela_px` | 10 | janela de leitura da reversão/curva |
| `bico_tol_px` | 26 | largura máxima do espinho |
| `bico_base_px` | 14 | o quanto a volta pode terminar longe da estrada (com curva) |
| `bico_fim_px` | 40 | o mesmo, quando o traço acaba na volta |
| `bico_base_angulo` | 45° | curva mínima que marca a base |

### `combate`

| chave | valor | o quê |
|---|---|---|
| `onda_velocidade` / `onda_empurrao` | 140 px/s / 30 px | expansão e empurrão da onda |
| `tiro_velocidade` / `tiro_alcance` | 420 px/s / 280 px | tiro do toque duplo (no alvo marcado) |
| `tiro_raio` / `tiro_empurrao` | 9 / 24 px | acerto e empurrão do tiro |
| `batida_cruza_px` / `batida_tol_px` | 8 / 34 px | quando a linha "passa por cima" e a tolerância na chegada |
| `batida_empurrao` | 26 px | empurrão da batida |
| `onda_recarga_s` / `tiro_recarga_s` | 1,0 s | **cooldown** dos especiais (área/tiro) |
| `area_gatilho_px` | 224 | distância da criatura ao **centro** que acende a área (≈7× o corpo) |
| `tiro_pausa_s` | 0,25 s | a pausa do animal para atirar |
| `mira_final_raio` | 34 px | onde o fim do caminho MARCA o alvo |
| `mira_final_empurrao` | 44 px | empurrão do golpe final |

## Alvos

- **Adversário:** fica **marcado** quando o fim do caminho o alcança (X amarelo
  que anda com ele); é o alvo do **tiro** (toque duplo) e do **golpe físico**
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
- **O que é laço e o que é bico**: `formas` em `dados/acoes.json`.
- **O que cada ataque faz no alvo**: `combate` (empurrões, alcances, raio).
- **Peso de cada ação**: fases/alcance/arco em `dados/acoes.json`.
- **Caminho** (simplificação, desconto, desvio, chegada): bloco `rota`.

## O que fica para depois

- **Dano e vida**: o adversário reage (empurrão + piscada), mas não tem vida;
  3 golpes derrubarem é uma decisão futura.
- **Defesa e esquiva como efeito**: não existem (esquivar é andar).
- **Especiais por criatura/evolução** (P4/P5).
- **Afinidade** (P4): hoje a criatura obedece.
- **Habilidades além de cavar**: o estado genérico está pronto (nome +
  `duracao`), falta conteúdo.
- **Bico**: o espinho continua sendo lido e o beco ignorado, mas **não atira
  mais** (o tiro é o toque duplo) — decidir com o operador se o gesto sai de
  vez; um bico com volta MUITO suave (sem canto) pode não ser lido.
- **Baú e mira vermelha**: sem gesto desde a v0.10 (o toque é o pulo) — o baú
  precisa de um gatilho novo.
- **Estrada**: a largura, a amplitude/onda e o freio são pontos de partida —
  ajustar no aparelho com o operador.
- **Linha**: mostra o traço CRU do dedo (inclusive o beco e o tremor inicial);
  se o operador preferir a linha do **caminho andado** (o rastro do animal), é
  outra decisão.
- **Embalo/cooldown**: os valores (0,25 s/1,7× e 0,6 s/2,0× · 1 s) são pontos
  de partida.
