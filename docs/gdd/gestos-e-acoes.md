# Gestos e ações — como a criatura se move e age

> Regra toda em `sim/` (testada) e nas tabelas `dados/gestos.json` +
> `dados/acoes.json` (editáveis); `jogo/` só desenha. v0.5.

## O fluxo

```
dedo (toque real ou demo roteirizada — mesmo caminho)
  → sim/gestos.gd   : reconhece O GESTO
  → sim/comandos.gd : traduz em COMANDO (ação + lado + alvo no mundo)
  → sim/corpo.gd    : ROTA + OVERLAYS + AUTONOMIA (a afinidade entra aqui, P4)
```

Tempo **simulado** (`tempo_ms`): teste, demo e oráculo são determinísticos.

## A regra de ouro: perto = MOVE, longe = AGE

| onde começa o dedo | o que é |
|---|---|
| **perto da criatura** (≈110 px de tela) | **ROTA** — qualquer arrasto, mesmo rápido, é caminho |
| **longe** | **GESTO DE AÇÃO** — o setor decidido pelo ângulo |

## A rota manda; as ações só a modificam

A criatura **segue a rota até o fim**. Ela só perde a rota se:

1. o jogador riscar **outra** rota (substitui);
2. **defender** (segurar) — isso a **para** sem apagar a rota; ao soltar, retoma;
3. **escavar** — troca de camada, e a rota não vale mais lá.

**Ataque, esquiva e pulo NÃO cancelam a rota** — são *overlays* por cima:

| overlay | o que faz | efeito na rota |
|---|---|---|
| **ataque** | golpe (antecipação → ativa → recuperação); a direção é **do alvo** ou, sem alvo, **da rota** | nenhum: continua andando |
| **esquiva** | desloca para o lado (amplitúe do gesto) e **volta** | nenhum: corrige sozinha e segue |
| **pulo** | arco no ar enquanto segue | nenhum: continua andando |

## Gestos (limiares em `dados/gestos.json`)

| gesto | como | vira |
|---|---|---|
| **toque** | dedo quase parado, rápido | **travar a mira** no alvo mais próximo do toque (árvore/adversário); no que é interativo (baú) → **interagir**; repetir no mesmo alvo → soltar |
| **toque duplo** | dois toques perto, < 0,34 s | **pular** (arco) |
| **segurar** | parado ≥ 0,38 s, longe dela | **defender** (para a rota enquanto o dedo fica) |
| **segurar nela** | o mesmo, começando em cima | **escavar** (desce/sobe) |
| **deslize longe** | ≥ 44 px, < 0,38 s | pelo **setor relativo ao olhar**: frente (±70°) → **ataque**; esquerda/direita → **esquiva** daquele lado |
| **arrasto perto** | ≥ 40 px | **rota** |

O ataque **não usa o ângulo do dedo**: só o setor (frente). A direção do golpe
sai do **alvo marcado** (mesmo móvel) ou, sem alvo, da **direção em que segue**.

## Alvos

- Travaveis: **árvore** e **adversário**; interativo: **baú**.
- A mira trava no mais perto do toque dentro de ~110 px e **acompanha** o alvo
  que anda (a posição é re-resolvida a cada quadro por `sim/alvos.gd`).
- Toque no mesmo alvo solta a mira.

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
| `esquiva` | `fases` [0 · 0,20 · 0] s, `deslocamento` 34 px (lateral), `recarga` 0,30 |
| `pular` | `fases` [0,06 · 0,42 · 0,06] s, `altura` 26 px, `recarga` 0,30 |
| `defender` | `sustentada` |
| `escavar` | `fases` [0,15 · 0,55 · 0,15] s |

## Como mudar sem tocar em código

- **Setores** (`frente`/`esquerda`/`direita` e qual ação cada um faz):
  `mapa.deslize` em `dados/gestos.json`. A legenda da HUD e a demo seguem.
- **Peso de cada ação** (vento, alcance, recarga, altura do pulo):
  `dados/acoes.json`.
- **Tolerância dos gestos**: `limiares` em `dados/gestos.json`.

## O que fica para depois

- **Afinidade** (P4): hoje a criatura obedece; a decisão
  {obedece · hesita · reinterpreta · desobedece} entra em `corpo.comandar()`.
- **Dano e contato**: o adversário só vagueia (de propósito, por enquanto).
- **Interação de verdade**: hoje o baú só muda de cor.
