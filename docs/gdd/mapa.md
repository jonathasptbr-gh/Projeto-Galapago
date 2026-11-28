# Mapa e camadas

> Como o mundo é organizado em camadas LÓGICAS (regra) e de DESENHO
> (apresentação). **Desde 2026-11-27 o mapa do jogo é a NATUREZA** (a mata,
> `sim/natureza.gd`), o único: a ilha de teste **Fundação**
> (`dados/mapas/fundacao.json`, com a extensão de parkour e o baú) saiu por
> decisão do operador; o texto dela está no git até `f38962a`.

## Camadas lógicas (sim/mundo.gd)

| camada | o que é |
|---|---|
| **superfície** | uma grade de células; cada célula tem um terreno (dados/terrenos.json) com `altura` (níveis), `andavel`, `escavavel` |
| **subsolo** | grade própria de TÚNEIS (`=`); células escavadas viram túnel |

Regras (testadas em `testes/test_mundo.gd`):

- **ANDAR** só vence diferença de altura de até 0,5 nível; a **rampa** (`altura` 1,5) liga o chão (1) ao planalto (2).
- **PULAR** pousa em célula andável até 1 nível ACIMA (descer, qualquer altura) e passa por cima de água e obstáculos no caminho; sem pouso válido, pula no lugar.
- **ESCAVAR** em célula escavável desce ao subsolo; escavar de novo sob uma célula escavável (ou já aberta) sobe. No subsolo não dá para pular. Desde a v0.9 cavar é a **habilidade do segurar parado** (o gesto não precisa ser em cima do animal).
- **Objetos com tronco** (árvore) bloqueiam a célula deles.

Posições em **pixels de mundo** (célula = 32 px); a conversão célula↔pixel é do `sim/mundo.gd`.

## Camadas de desenho (z_index, de trás para frente)

| z | camada | faz |
|---|---|---|
| −20 | **parallax fundo** | mar profundo, anda DEVAGAR (0,35×) — visto pela água semitransparente |
| 0 | **chão** | xadrez por terreno; níveis altos sobem na tela com PAREDE na face sul; água deixa ver o fundo; buracos escuros |
| 1 | **trilha** | o traço riscado, liso |
| 2 | **objetos (y-sort)** | troncos e a CRIATURA, ordenados pela base |
| 15 | **subsolo** | só visível com a criatura embaixo da terra: escurece tudo e desenha os túneis; a criatura sobe para z 20 |
| 30 | **copas** | subcamada de VISIBILIDADE |
| 40 | **parallax frente** | nuvens, andam RÁPIDO (1,35×) |
| — | **HUD** | CanvasLayer, na resolução da tela |

## Câmera orbital 3D (P24; pinça contínua na v0.44)

A câmera é **ortográfica orbital** (`sim/camera3d.gd`, `dados/camera3d.json`):
o foco segue a criatura, a barra do topo gira o `yaw` 360° e a **pinça ajusta a
aproximação continuamente**. A altura do mundo visível interpola de **25
unidades** (vista de longe, `pitch` −60°) a **8 unidades** (máxima aproximação,
`pitch` −35°), e **para onde for solta** — não há mais dois estados de zoom nem
controle de movimento próprio da vista próxima: o caminho é o mesmo gesto em
qualquer aproximação. A projeção continua visual; não altera altura ou colisão
da simulação. O valor atual aparece no registro do diagnóstico.

## Transparência das copas (copa vazada)

No mundo 3D, folhas e madeira das árvores que ficam **entre a câmera e a
criatura** somem por **dither ordenado 4×4**, numa abertura circular centrada
nela (`jogo/mundo3d/natureza/natural.gdshader` e `folha.gdshader`,
`raio_foco`). Na v0.44 o raio subiu de 1,9 para **2,6 unidades** na vista de
longe (≈133 px de raio numa tela de 1280) e o `main` o encolhe junto com a
aproximação (até **1,45** na máxima), então a abertura **cresce em pixels de
tela** com o zoom — ≈232 px no perto — sem apagar a mata. Fora do passe de
sombra: a sombra projetada continua inteira. O mesmo mecanismo serve para
telhado, ponte e arco.

## O mapa: NATUREZA (sim/natureza.gd)

- Gerado por código puro com semente fixa: `Natureza.mundo_dict()` devolve a
  grade no formato de mapa do `sim/mundo.gd` — `celulas` (um caractere por
  célula, legenda em `dados/terrenos.json`), `inicio`, `objetos` (`arvore`
  com `copa`, `tronco` que bloqueia) e `adversarios`.
- 46×62 células: mata (`,`), a trilha (`p`), o riacho (`~`) com vaus (`v`) e
  a clareira de terra fofa (`:`, onde se cava). O chão andável é plano (nível
  1); só o leito do riacho desce.
- O desenho 3D é `jogo/mundo3d/natureza/` (malhas, mapa, shaders natural e
  folha), na mesma escala da sim (`jogo/mundo3d/espaco.gd`). Direção de arte:
  [ARTE](../ARTE.md#mata-3d--direção-em-avaliação-2026-11-26).
- `q` (plataforma, altura 3) segue em `terrenos.json` só para o teste do
  degrau de DOIS níveis do corpo; `^` (planalto) e `/` (rampa) para os testes
  de desnível.

## Ainda não existe

- Ciclo dia/noite; animação de água/vegetação.
- Afinidade alterando o movimento (P4).
- Pulo com física de pouso (hoje cair na água é só "precisa de outro pulo").
