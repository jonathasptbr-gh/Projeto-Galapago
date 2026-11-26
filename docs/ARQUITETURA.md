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
toque → gesto de TELA + caminho AO VIVO (sim/gestos)
      → FORMA do desenho (sim/formas: o laço virou onda em área até a v0.11.5 —
        desligado em `formas.laco_ataque`; hoje só caminho)
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

**Mobile (Vulkan)** é o alvo: o celular médio, e o renderizador do APK
(decisão do operador, 2026-11-25, P24; era `gl_compatibility`). **Compatibility**
(OpenGL 3.3 / GLES 3) fica em dois papéis: **fallback** do aparelho sem Vulkan
(`rendering_device/fallback_to_opengl3`) e **prévia local** do oráculo, o único
que renderiza neste celular sem GPU; a verdade visual é o oráculo em Vulkan
(lavapipe) no CI — ver [`ORACULO`](ORACULO.md). Consequência: shader, material
e efeito do projeto têm de compilar e funcionar **nos dois** renderizadores
(nada exclusivo do RenderingDevice, como compute shader; nada que só fique
certo em cor linear ou só em sRGB; o toon converte o nível com
`OUTPUT_IS_SRGB`). **Tela em alta resolução e RETRATO** (720×1280,
`canvas_items`, `expand`).

**Mundo 3D (P24):** a ilha, os objetos e os atores são 3D
(`jogo/mundo3d/`), vistos por uma câmera **ortográfica orbital** pura
(`sim/camera3d.gd`: foco, yaw livre 360°, vistas `alta` — padrão — e
`intima`, snap de texel, chão⇄tela como `Transform2D` afim). O **Pixel Pass**
é a última camada e desliga: SubViewport em baixa resolução + quantização +
Bayer ancorado no mundo + ampliação *nearest* + compensação de subpixel.
Trilha, mira, áreas de perigo e a onda desenham em px de mundo da sim num
**mapa do chão** (SubViewport 2D, `jogo/mundo3d/chao.gd`) que o material do
terreno pinta no topo das células, antes da luz: ficam NO chão, sob copas,
paredes e atores. Projéteis no ar e HUD continuam 2D, lisos, por cima do 3D
(os projéteis sob um `Node2D` cuja transformação é a afim da câmera).
Detalhes em [`GODOT.md`](GODOT.md#6-pixel-art-no-godot).

## Pele e esqueleto (v0.22.0)

> **P24 (2026-11-25):** no jogo a criatura e o inimigo são **atores 3D
> provisórios** (`jogo/mundo3d/ator.gd`) que só leem a sim. A pele
> esquelética 2D abaixo saiu do jogo; o rig da sim fica **congelado** (P9/P10)
> e só `tools/folha_*` e os testes ainda o desenham.

O desenho da criatura pode vir de dois lados, com o MESMO contrato: o mock de
xadrez ou a **pele esquelética** (`jogo/pele_geometrica.gd`), que desenha o rig
de `dados/rig/<familia>.json` validado por `sim/esqueleto.gd` (pose por fase e
âncora por nome, 8 direções) como ossos em linhas brancas e juntas em pontos
vermelhos — sem corpo preenchido. `sim/direcao.gd` mapeia o olhar em setores;
`jogo/rigs.gd` carrega e cacheia o rig, fail-closed. A pele de sprite do
PixelLab entra no mesmo lugar quando a arte for aprovada — a regra de jogo
nunca pergunta qual pele está ativa.

**Animação (v0.23.0):** `dados/animacoes.json` é o catálogo (camada, loop,
duração, prioridade, janelas de evento por tempo e socket) e
`sim/animacao.gd` é a máquina pura que transforma o retrato do corpo no clipe
a desenhar. A prioridade decide quem corta quem; a base troca entre andar e
parado. Nenhum dano, alcance ou tempo mora aqui.

**Módulos e efeitos (v0.24.0):** `dados/modulos.json` descreve peças
cosméticas presas a um socket por **nome** e efeitos por evento; `sim/modulos.gd`
resolve posição/z no rig e recusa qualquer item que declare
`concede_habilidade`. Efeito nasce nas janelas de tempo do clipe
(`sim/animacao.janela_ativa`), nunca por índice de quadro.

## Mundo e mapa

O mapa vem de **dados**: `dados/mapas/<nome>.json` (cantos de terreno + objetos)
→ `sim/mapa.gd` (pura: valida o desenho e escolhe a peça Wang de cada célula)
→ hoje `jogo/mundo3d/ilha.gd` monta a ilha 3D a partir de `sim/mundo.gd` (o `TileMapLayer` Wang do v0.3 saiu no P24).
Objetos e criatura ficam num `Node2D` com `y_sort_enabled`, origem nos pés.
Design: [`gdd/mapa.md`](gdd/mapa.md).

## Atualização do app

`sim/atualizacao.gd` (pura: manifesto, host travado, decisão, tamanho) +
`jogo/atualizador.gd` (HTTP, download, instalador). O método do IASD: [`BUILD.md`](BUILD.md#atualização-automática-do-app).
