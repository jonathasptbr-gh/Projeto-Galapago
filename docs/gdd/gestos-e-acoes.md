# Gestos e ações — como a criatura se move e age

> Regra toda em `sim/` (testada) e nas tabelas `dados/gestos.json` +
> `dados/acoes.json` (editáveis); `jogo/` só desenha. **v0.6.**

## O fluxo

```
dedo (toque real ou demo roteirizada — mesmo caminho)
  → sim/gestos.gd   : reconhece O GESTO e a ÂNCORA do caminho
  → sim/comandos.gd : traduz em COMANDO (ação + lado + alvo no mundo)
  → sim/corpo.gd    : ROTA (pontos de referência + desvio) + OVERLAYS +
                      AUTONOMIA (a afinidade entra aqui, P4)
```

Tempo **simulado** (`tempo_ms`): teste, demo e oráculo são determinísticos.

## A regra de ouro: o gesto é da TELA, o caminho é da ÂNCORA

Os setores **não são relativos ao olhar da criatura**. Não existe mais
"para a frente dela": o que vale é a direção do dedo na tela.

| gesto (na tela) | vira |
|---|---|
| **para cima** | **ataque físico** |
| **para a esquerda / direita** | **especial** daquele lado |
| **para baixo** (rápido) | **esquiva para trás** |
| **para baixo e continuar segurando** | **defesa** (sustentada até soltar) |
| **segurar parado e arrastar** | **caminho** (rota desenhada a partir da âncora) |
| **segurar nela, sem arrastar** | **escavar** |
| **toque** | **travar a mira** no alvo mais próximo do toque; baú → interagir |
| **toque duplo** | **pular** |

O ataque **não usa o ângulo do dedo para mirar**: a direção continua saindo do
**alvo marcado** ou, sem alvo, da **direção da rota/olhar**. O gesto só decide
*qual* ação. O especial sai para o lado do gesto.

## O caminho por âncora (v0.6)

Antes o caminho começava no dedo em cima da criatura — e o dedo tapava a
visão. Agora:

1. o jogador **encosta e segura parado** em qualquer lugar da tela (por
   `segurar_min_ms`, 0,38 s). Esse ponto é a **ÂNCORA**, o "animal virtual";
2. com a âncora viva, o **mundo desacelera** (`planejamento.escala_tempo`,
   0,35×) — dá tempo de desenhar e planejar. O dedo continua em tempo real;
3. ao arrastar, a prévia do traço aparece **transladada sobre a criatura**
   (o desenho é interpretado como se a âncora fosse ela), com um anel no
   ponto segurado;
4. ao soltar, o traço vira a rota da criatura: a âncora é mapeada para a
   posição **atual** dela, então o caminho começa nela e segue a forma
   desenhada;
5. **segurar + arrastar** é sempre caminho. **Segurar sem arrastar** fora dela
   não faz nada (é só a âncora); em cima dela, vira **escavar** (só se não
   arrastou além da tolerância).

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
| **defesa** | para a rota enquanto o dedo fica (baixo + segurar) | para, sem apagar |

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
- **Peso de cada ação** (vento, alcance, recarga, altura do pulo):
  `dados/acoes.json`.
- **Tolerância dos gestos e o tempo lento**: `limiares` e `planejamento` em
  `dados/gestos.json`.
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
