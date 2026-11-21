# Gestos e ações — como a criatura se move e age

> Regra toda em `sim/` (testada) e nas tabelas `dados/gestos.json` +
> `dados/acoes.json` (editáveis); `jogo/` só desenha. **v0.7.**

## O fluxo

```
dedo (toque real ou demo roteirizada — mesmo caminho)
  → sim/gestos.gd   : reconhece O GESTO (caminho ao vivo + RISCO de ação)
  → sim/comandos.gd : traduz o risco em COMANDO (ação + lado + alvo no mundo)
  → sim/corpo.gd    : ROTA ao vivo (pontos de referência + desvio) + OVERLAYS
                      + AUTONOMIA (a afinidade entra aqui, P4)
```

Tempo **simulado** (`tempo_ms`): teste, demo e oráculo são determinísticos.

## A regra de ouro: o gesto é da TELA, o caminho é da CRIATURA

Os setores **não são relativos ao olhar da criatura**. Não existe "para a
frente dela": o que vale é a direção do dedo na tela.

| gesto (na tela) | vira |
|---|---|
| **arrastar** (qualquer distância acima de 16 px) | **caminho**, desenhado **AO VIVO** (sem espera) |
| **risco rápido para cima** | **ataque físico** (em paralelo ao caminho) |
| **risco rápido para a esquerda / direita** | **especial** daquele lado |
| **risco rápido para baixo** | **esquiva para trás** |
| **para baixo e parar (sem soltar)** | **defesa** (sustentada até soltar; para a rota) |
| **segurar nela, sem arrastar** | **escavar** (decidido no soltar) |
| **toque** | **travar a mira** no alvo mais próximo do toque; baú → interagir |
| **toque duplo** | **pular** |

O ataque **não usa o ângulo do dedo para mirar**: a direção continua saindo do
**alvo marcado** ou, sem alvo, da **direção da rota/olhar**. O gesto só decide
*qual* ação. O especial sai para o lado do gesto.

## O caminho (v0.7): sem espera, ao vivo, com origem congelada

1. O dedo desce e a **origem** é congelada: a posição da criatura NAQUELE
   instante (e o mapa tela→mundo daquele instante). A linha **não anda junto
   com o animal** nem com a câmera enquanto o dedo desenha.
2. Passou de `desenho_min_px` (16 px), **já é caminho** — não há mais
   "segurar parado 0,38 s antes de arrastar". A rota é refeita a cada quadro e
   a criatura **já anda por ela**, atrás do traço.
3. Se ela se mexeu até o traço começar (andou sozinha), o primeiro trecho da
   rota a **traz de volta ao começo** — ela não corta caminho.
4. Ao soltar, a rota é fechada com o último trecho. Ela segue até o fim.
5. **Sensibilidade**: `desenho.ganho` (1,6) multiplica o traço. Um dedo que
   anda 100 px na tela desenha 160 px de caminho — movimento menor cobre mais
   área. Ajustável sem tocar em código.

### O RISCO (ação em paralelo)

Sem a espera, o arrasto deixaria de disparar ataque/esquiva. Para manter as
ações: um **risco** — traço **curto**, **reto**, **rápido** e **no começo do
gesto** — dispara a ação do setor **no meio do arrasto**, e o caminho continua:

- `deslize_min_px` (44) ≤ traço ≤ `flick_janela_px` (170);
- duração ≤ `flick_max_ms` (0,26 s) e velocidade ≥ `flick_vel_min_px_s` (700);
- desvio da corda ≤ `flick_reta_px` (24) — curva não é risco;
- **um disparo por gesto**: desenhar rápido não vira metralhadora.

Ou seja: desenho lento/curvo é só caminho; um "tapa" rápido no setor vira
ataque E caminho, sem atraso e sem cancelar o desenho.

### Tempo lento, escurecida e a rampa de saída

- enquanto desenha (ou defende), o **mundo** roda em
  `planejamento.escala_tempo` (0,35×) — o relógio do GESTO continua real;
- a tela **escurece** `planejamento.escurecer` (0,22) — é o que ilustra a
  desaceleração;
- ao soltar, o tempo **acelera numa rampa** de `planejamento.retomada_ms`
  (0,45 s): começa devagar e solta no fim, e o véu clareia junto. Dá tempo de
  ver o resultado e tomar a próxima ação.

### Desconto inicial

Ao começar um traço é comum fazer um pequeno **vai e volta** no ponto de
partida; obedecer isso faz a criatura ir e voltar antes de seguir. O
`sim/trajetoria.descontar_inicio` descarta esse trecho:

- só corta se houve **volta de verdade** (a distância ao início diminuiu ≥ 6 px)
  e se o corte cabe em `desconto_janela_px` (140 px) de traço;
- a criatura se alinha a `desconto_raio_px` (44 px) do início e só então
  obedece o resto;
- a reta até o ponto de alinhamento precisa ser **andável**; se o vai-e-volta
  era um desvio necessário (pedra no começo), não corta;
- **só vale para o início**: ao longo do caminho, idas e vindas são permitidas.

### Pontos de referência, não o traço inteiro

O traço é reduzido com Douglas-Peucker (`sim/trajetoria.simplificar`,
`simplificar_px` = 10): uma reta vira duas pontas; curvas e cantos continuam
com alguns pontos. A criatura procura **um ponto por vez, na ordem**. Isso é o
que permite o desvio local:

- **objeto** (tronco) no caminho: ela testa um leque de pequenos desvios
  (`desvio_angulos`, até ±120°) e escolhe o que chega mais perto do ponto —
  contorna e continua. Teto de `desvios_max` passos para não ficar girando;
- **terreno** (água, rocha, diferença de altura): é **barreira**. Ela **para**
  (`barrado()`), mas a rota **não é apagada**;
- **pulo durante a rota**: no ar ela ignora o chão e segue o percurso — é o
  que atravessa a barreira. Se o pulo termina na água, ela não anda sobre a
  água: precisa de **outro pulo**;
- um ponto de referência **dentro** de um tronco conta como alcançado a 24 px
  (não dá para chegar ao centro dele).

A rota só é perdida se o jogador riscar **outra**, se **defender** (para, sem
apagar; ao soltar retoma) ou se **escavar** (troca de camada).

## Overlays

| overlay | o que faz | efeito na rota |
|---|---|---|
| **ataque** | golpe (antecipação → ativa → recuperação); direção do alvo ou da rota | nenhum: continua andando |
| **especial** | golpe lateral mais longo/aberto, na direção do gesto (lados) | nenhum: continua andando |
| **esquiva** | desloca para a direção do gesto (baixo = para trás) e **volta** | nenhum: corrige sozinha e segue |
| **pulo** | arco no ar enquanto segue; atravessa barreira | nenhum: continua andando |
| **defesa** | para a rota enquanto o dedo fica (baixo + parado) | para, sem apagar |

## Autonomia (sem rota)

Ao terminar a rota, a criatura decide sozinha, com sorteio **semeado**
(determinístico): **fica parada**, **vagueia devagar** ou, se há alvo marcado,
**aproxima** dele e depois **ronda** ao redor. Cada passo é cortado pelo mundo
(não entra na água nem em parede).

## Ações (`dados/acoes.json`)

| ação | parâmetros |
|---|---|
| `mover` | `velocidade` 110 px/s |
| `ataque` | `fases` [0,10 · 0,14 · 0,18] s, `alcance` 40, `arco` 90°, `recarga` 0,15 |
| `especial` | `fases` [0,14 · 0,22 · 0,26] s, `alcance` 56, `arco` 120°, `recarga` 0,55 |
| `esquiva` | `fases` [0 · 0,20 · 0] s, `deslocamento` 34 px (na direção do gesto), `recarga` 0,30 |
| `pular` | `fases` [0,06 · 0,42 · 0,06] s, `altura` 26 px, `recarga` 0,30 |
| `defender` | `sustentada` |
| `escavar` | `fases` [0,15 · 0,55 · 0,15] s |
| `rota` | `simplificar_px` 10 · `desconto_raio_px` 44 · `desconto_janela_px` 140 · `chegada_px` 12 · `desvio_angulos` · `desvios_max` 80 |

## Alvos

- Travaveis: **árvore** e **adversário**; interativo: **baú**.
- A mira trava no mais perto do toque dentro de ~110 px e **acompanha** o alvo
  que anda (a posição é re-resolvida a cada quadro por `sim/alvos.gd`).
- Toque no mesmo alvo solta a mira.

## Como mudar sem tocar em código

- **Setores** (qual direção da tela faz o quê): `mapa.deslize` em
  `dados/gestos.json`. A legenda da HUD e a demo seguem.
- **Sensibilidade do desenho**: `desenho.ganho` (1,6 hoje).
- **Risco** (o que conta como ação no meio do arrasto): `flick_*` em
  `limiares`.
- **Tolerância dos toques e da defesa**: `toque_*`, `segurar_*`.
- **Tempo lento, escurecida e rampa**: `planejamento` (0,35× · 0,22 · 0,45 s).
- **Peso de cada ação** (vento, alcance, recarga, altura do pulo):
  `dados/acoes.json`.
- **Caminho** (simplificação, desconto, desvio, chegada): bloco `rota` em
  `dados/acoes.json`.

## O que fica para depois

- **Especiais de verdade** (P4/P5): hoje os dois lados usam o mesmo golpe
  lateral genérico; cada criatura/evolução terá os seus.
- **Afinidade** (P4): hoje a criatura obedece; a decisão
  {obedece · hesita · reinterpreta · desobedece} entra em `corpo.comandar()`.
- **Dano e contato**: o adversário só vagueia (de propósito, por enquanto).
- **Interação de verdade**: hoje o baú só muda de cor.
- **Pulo/física de pouso**: cair na água exige outro pulo; não há natação,
  dano nem empurrão.
