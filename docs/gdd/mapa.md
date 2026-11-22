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
- **ESCAVAR** em célula escavável desce ao subsolo; escavar de novo sob uma célula escavável (ou já aberta) sobe. No subsolo não dá para pular. Desde a v0.9 cavar é a **habilidade do segurar parado** (o gesto não precisa ser em cima do animal).
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

## A extensão de parkour (v0.12, x = 40..63)

O mapa cresceu **24 colunas a leste** (40 → 64 células de largura) para uma
área de teste de movimentação, ligada à ilha leste por uma **trilha** de 2
células de altura 1 que atravessa a água em `x = 38..39`, `y = 11..12`. O
resto do mapa (oeste) **não mudou**.

Peças novas na legenda (só para esta área; a arte de verdade ainda não existe):

| char | nome | altura | serve para |
|---|---|---|---|
| `p` | trilha | 1 | chão de percurso, ligado à areia por `pode_andar` |
| `b` | passarela | 2 | um nível acima; a face sul mostra a parede |
| `r` | rampa alta | 2,5 | liga 2 e 3 **andando** (diferença 0,5) |
| `q` | plataforma | 3 | dois níveis acima do chão |

O percurso de ida (oeste→leste), tudo sobre água:

1. **pátio** `p` (x 40..43, y 10..13) — entrada.
2. **vão de 1 célula** (`x = 44`) e **passarela** `b` (x 45..47, y 10..13):
   sobe 1 nível **pulando**; à direita, no mesmo vão, a **rampa** `/` em
   (44,13) oferece o caminho **andando** (1 → 1,5 → 2).
3. **passarela estreita** `b` (x 48..50, y 11) — caminho de 1 célula de largura.
4. **vão de 2 células** (`x = 51..52`) e **plataforma** `q` (x 53..55,
   y 10..12): o vão de 2 células pede **pulo emendado** (dois toques) ou
   sprint; o pouso é 1 nível acima.
5. **pescoço** `q` (x 56, y 11), **rampa alta** `r` (x 56, y 12) e **degrau**
   `b` (x 57..59, y 10..12): dá para **descer andando** pela rampa (3 → 2,5 →
   2) ou **pular** o desnível de 3 para 2 pelo pescoço.
6. **rampa** `/` (x 60, y 12) e **pátio final** `p` (x 61..63, y 10..13): a
   descida andando (2 → 1,5 → 1); no `y = 11` o mesmo trecho é um **vão de 1
   célula** para descer pulando.
7. **volta** em `y = 16`, do pátio final ao inicial (leste→oeste): trilha `p`
   (x 62..63, y 14..16) desce ao chão; a sequência é `p` (62..63), **vão de 1**
   (61), `p` (59..60), **vão de 2** (57..58), `p` (55..56), **vão de 1** (54),
   `b` (52..53), **vão de 1** (51), `q` (49..50), **vão de 1** (48), `b`
   (46..47), **vão de 1** (45), `p` (43..44), **vão de 1** (42) e `p`
   (40..41) — degraus 1→2→3→2→1, com um vão de 2 células no meio. O pátio
   inicial fecha o laço pela trilha `p` em x 40..41, y 14..15.

**O que testa:** andar xadrez/ladeira, pulo simples sobre 1 célula, pulo
emendado (ou sprint) sobre 2, subida de 1 nível e descida de 1 nível (andar
não vence; o pulo sim), rampas que substituem o pulo, e caminhar em cima de
plataforma com a câmera acompanhando. A regra é a de `sim/mundo.gd` — a
extensão só usa alturas e vãos, sem código novo de movimento. Com o **PULO
AUTO** ligado (botão da HUD, v0.13), os degraus de **1 nível** com o caminho
continuando sobem sozinhos — inclusive os que têm um vão de **1 célula** antes
(pátio→passarela e a volta p→b→q); os vãos de **2 células** continuam exigindo
pulo emendado ou sprint (com sprint o pulo alonga e o automático cruza).

**Como chegar:** o jogo começa na ilha oeste. A ilha leste é alcançável pelo
túnel (terra fofa) ou pelo pulo sobre o canal central; a trilha de parkour
entra pela borda leste dela, em `y = 11..12`.

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
