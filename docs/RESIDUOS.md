# Resíduos — o que o lote viu e não consertou

> Toda versão deixa uma linha aqui antes do push, mesmo que seja "nenhum".

| versão | onde | o quê | tamanho |
|---|---|---|---|
| v0.1.0 | `jogo/main.gd` `_draw` | traço de 1 px sai com falhas nas diagonais (snap de vértice + `draw_polyline` largura 1) | pequeno — trocar por desenho por pixel (Bresenham) ou largura 2 quando a arena chegar (P3) |
| v0.1.0 | `ci.yml` | ~~oráculo llvmpipe/x86_64 não provado~~ — **resolvido**: CI #1 (`cfdbb34`) verde com o passo de quadros | — |
