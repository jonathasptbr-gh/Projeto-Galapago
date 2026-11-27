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

## Câmera de pinça (v0.20)

A pinça aproxima de zoom 1,6 a 3,2 e comprime o plano verticalmente de 1,0
até 0,72; objetos são compensados para não achatar sua imagem. Na vista
superior marcas, efeitos, perigos e adversários mantêm a posição histórica;
seu deslocamento por altura interpola continuamente até o topo projetado na
vista íntima máxima. **Compromisso:** nas inclinações intermediárias eles não
coincidem exatamente com o topo do chão, que já tem desnível na vista superior.
A projeção é visual; não altera altura ou colisão da simulação.

## Subcamadas de visibilidade (sim/visibilidade.gd)

A **copa da árvore** fica numa camada ACIMA de tudo: longe da criatura é
opaca (esconde o que está embaixo); com a criatura passando
por baixo ou ao lado, quase transparente (deixa ver). A transição é suave
(smoothstep) para não piscar na borda. É o mesmo mecanismo que vai servir para
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
