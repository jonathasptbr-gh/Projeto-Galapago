# Mapa e camadas — a fundação

> Como o mundo é organizado em camadas LÓGICAS (regra) e de DESENHO
> (apresentação). v0.6: tudo em MOCKUP de xadrez — a estrutura é o produto;
> a arte entra depois no lugar das cores.

## Camadas lógicas (sim/mundo.gd)

| camada | o que é |
|---|---|
| **superfície** | uma grade de células; cada célula tem um terreno (dados/terrenos.json) com `altura` (níveis), `andavel`, `escavavel` |
| **subsolo** | grade própria de TÚNEIS (`=`); células escavadas viram túnel |

Regras (testadas em `testes/test_mundo.gd`):

- **ANDAR** só vence diferença de altura de até 0,5 nível; a **rampa** (`altura` 1,5) liga o chão (1) ao planalto (2).
- **PULAR** pousa em célula andável até 1 nível ACIMA (descer, qualquer altura) e passa por cima de água e obstáculos no caminho; sem pouso válido, pula no lugar.
- **ESCAVAR** em célula escavável desce ao subsolo; escavar de novo sob uma célula escavável (ou já aberta) sobe. No subsolo não dá para pular.
- **Objetos com tronco** (árvore) bloqueiam a célula deles.

Posições em **pixels de mundo** (célula = 32 px); a conversão célula↔pixel é do `sim/mundo.gd`.

## Camadas de desenho (z_index, de trás para frente)

| z | camada | faz |
|---|---|---|
| −20 | **parallax fundo** | mar profundo, anda DEVAGAR (0,35×) — visto pela água semitransparente |
| 0 | **chão** | xadrez por terreno; níveis altos sobem na tela com PAREDE na face sul; água deixa ver o fundo; buracos escuros |
| 1 | **trilha** | o traço riscado, liso |
| 2 | **objetos (y-sort)** | troncos, baú e a CRIATURA, ordenados pela base |
| 15 | **subsolo** | só visível com a criatura embaixo da terra: escurece tudo e desenha os túneis; a criatura sobe para z 20 |
| 30 | **copas** | subcamada de VISIBILIDADE |
| 40 | **parallax frente** | nuvens, andam RÁPIDO (1,35×) |
| — | **HUD** | CanvasLayer, na resolução da tela |

## Subcamadas de visibilidade (sim/visibilidade.gd)

A **copa da árvore** fica numa camada ACIMA de tudo: longe da criatura é
opaca (esconde o que está embaixo — o baú do bosque); com a criatura passando
por baixo ou ao lado, quase transparente (deixa ver). A transição é suave
(smoothstep) para não piscar na borda. É o mesmo mecanismo que vai servir para
telhado, ponte e arco.

## O mapa de teste (dados/mapas/fundacao.json)

- `celulas`: um caractere por célula (legenda em dados/terrenos.json).
- `subsolo`: `=` túnel, espaço = rocha.
- `inicio`, `objetos`: `{tipo, celula, copa?}` — tronco bloqueia; `copa` (raio)
  vira uma copa na camada de cima.
- O mapa cobre: um canal (pulo), planalto com rampa, terra fofa com túnel que
  liga os dois lados (escavação), rochas, e um bosque com baú escondido sob a
  copa.

## Mockup → arte

Tudo desenha com `jogo/mock.gd` (xadrez gerado em código, cores de
`terrenos.json`). Trocar pela arte é trocar as texturas/mock por sprites —
a estrutura de camadas e as regras não mudam. O desenho Wang do v0.3
(`jogo/mapa.gd` + `sim/mapa.gd` + `ilha_teste.json`) fica PARADO, para quando a
arte de verdade voltar; a fundação não depende dele.

## Ainda não existe

- Ciclo dia/noite; animação de água/vegetação.
- Afinidade alterando o movimento (P4).
- Pulo com física de pouso (hoje cair na água é só "precisa de outro pulo").
