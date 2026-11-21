# Arquitetura

## As duas camadas (a regra que mais se paga)

| camada | pasta | pode | não pode |
|---|---|---|---|
| **simulação** | `sim/` | dados, matemática, sorteio com semente | nó, cena, `Input`, `_process`, tempo real, `randf()` global |
| **apresentação** | `jogo/` | ler toque, desenhar, animar, tocar som, chamar a `sim/` | decidir regra de jogo |

Por quê: tudo o que define o jogo (trajetória, gestos, afinidade,
personalidade, evolução por vivência) fica **testável headless e
reproduzível**. Isso permite:

- testes unitários no CI e aqui (`tools/testes.sh`);
- **simulação em massa** — rodar milhares de "vidas" de criatura com sementes
  diferentes e medir a distribuição dos ramos de evolução (balanceamento por
  estatística, não por palpite). Previsto no pacote P5.

`sim/` usa `RandomNumberGenerator` com semente explícita, passado como
argumento — nunca o sorteio global.

## Dados de design

Espécies-base, traços, gatilhos de vivência e ramos de evolução moram em
**dados** (`dados/*.json` — o mapa já é assim; criaturas no P4/P5), não
em código: mudar o design não exige mexer na lógica.

## Pipeline previsto da criatura (pacotes P3–P6)

```
toque → gesto de TELA + âncora do caminho (sim/gestos)
      → pontos de referência (sim/trajetoria: desconto inicial + Douglas-Peucker)
      → INTENÇÃO
      → decisão da criatura (sim/afinidade: afinidade × temperamento × humor)
        → obedece | hesita | reinterpreta | desobedece
      → ação na arena (jogo/): waypoints + desvio de objetos + overlays
vivência acumulada (sim/vivencia) → perfil de traços → evolução → troca de PEÇAS
```

Sincronia e Autonomia Mestra são **modos do mesmo pipeline**, não sistemas
separados.

## Renderização

`gl_compatibility` (OpenGL 3.3 / GLES 3): roda em celular modesto e é o único
que o oráculo de quadros renderiza sem GPU. **Tela em alta resolução e
RETRATO** (720×1280, `canvas_items`, `expand`) com **arte pixelada** (filtro
*nearest*, câmera com zoom inteiro 2): linhas, sombras, efeitos e texto são
lisos. Detalhes em [`GODOT.md`](GODOT.md#6-pixel-art-no-godot).

## Mundo e mapa

O mapa vem de **dados**: `dados/mapas/<nome>.json` (cantos de terreno + objetos)
→ `sim/mapa.gd` (pura: valida o desenho e escolhe a peça Wang de cada célula)
→ `jogo/mapa.gd` (monta o `TileMapLayer` com os tilesets do PixelLab).
Objetos e criatura ficam num `Node2D` com `y_sort_enabled`, origem nos pés.
Design: [`gdd/mapa.md`](gdd/mapa.md).

## Atualização do app

`sim/atualizacao.gd` (pura: manifesto, host travado, decisão, tamanho) +
`jogo/atualizador.gd` (HTTP, download, instalador). O método do IASD: [`BUILD.md`](BUILD.md#atualização-automática-do-app).
