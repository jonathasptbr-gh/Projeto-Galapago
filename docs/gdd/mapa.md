# Mapa — design básico (v0.3.0)

> Primeiro corte do mundo visto de cima. Decisões de design abertas estão no
> fim; o resto é o que está implementado e como mexer.

## A vista

- **De cima, alta** (o "high top-down" do PixelLab, ~35°): o chão é lido de
  cima; paredes e objetos mostram a face SUL — é daí que vem a profundidade.
- **Níveis de terreno** em ordem: mar 0 · areia 1 · grama 2 · planalto 3. O
  planalto é **elevado**: as bordas voltadas para baixo mostram parede de rocha
  (o tileset grama↔planalto tem `transition_size` 0,5), as de cima não.
- **Ordem de profundidade (y-sort):** árvores, rochas, a estação e a criatura
  são ordenadas pela BASE (os pés): quem está mais abaixo na tela fica na
  frente. Cada um tem a origem no ponto onde toca o chão.
- **Sombras lisas** (não pixeladas) sob criatura e objetos — exceto a árvore,
  cuja arte já traz sombra.

## Escala e resolução

| coisa | valor |
|---|---|
| tela | 1280×720 base, `canvas_items`, aspecto `expand` (telas largas mostram mais mundo, não esticam) |
| célula | 32 px de arte |
| câmera | zoom 2 → 1 px de arte = 2×2 px de tela; vê ~20×11 células |
| ilha de teste | 40×21 células = 1280×672 px de mundo |
| criatura (provisória) | sprite 64×64 (~1,5 célula de corpo) |

A arte é pixelada (filtro nearest); linhas, sombras, efeitos e texto são
desenhados lisos na resolução da tela. O movimento é suave (subpixel).

## Como editar o mapa

Tudo em [`dados/mapas/ilha_teste.json`](../../dados/mapas/ilha_teste.json):

- `pontos`: uma linha de texto por fileira de CANTOS (`~ . , ^`). A célula
  (x, y) tem os cantos (x,y) (x+1,y) (x,y+1) (x+1,y+1). **Cantos de uma célula
  (inclusive na diagonal) só podem diferir em um nível** — mar não encosta em
  grama sem areia no meio. `tools/testes.sh` reprova desenho inválido e aponta
  a célula.
- `tilesets`: os pares, em ordem (`mar_areia`, `areia_grama`, `grama_planalto`).
- `inicio`: célula onde a criatura começa. `objetos`: `{tipo, celula}` com
  `tipo` = nome do PNG em `arte/cenarios/objetos/` (sem o PNG, aparece um
  marcador provisório).

## Ainda NÃO existe (decisões e pacotes futuros)

- **Altura e colisão:** a criatura anda sobre o mar e sobe o planalto como se
  fosse chão. Precisa de: terreno andável por nível, rampas/escadas para o
  planalto, e a trajetória respeitar isso (P3/P4).
- **Câmera da criatura:** o sprite do cão é de LADO (prova do P1); o mapa é de
  CIMA. Decidir a vista das criaturas no P6 (o PixelLab gera 8 direções na
  vista `high top-down`).
- **Microambientes do laboratório:** só há a estação no planalto. Quantos
  ambientes, como se conectam, o que é cada um — GDD do loop diário (P8).
- Água animada, vegetação balançando, ciclo dia/noite — efeitos de shader.
