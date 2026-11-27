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
      → o desenho é caminho (o leitor de formas e a onda do laço saíram em
        2026-11-27; a travessia e o fim no alvo são do sim/corpo)
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
Trilha, mira e áreas de perigo desenham em px de mundo da sim num
**mapa do chão** (SubViewport 2D, `jogo/mundo3d/chao.gd`) que o material do
terreno pinta no topo das células, antes da luz: ficam NO chão, sob copas,
paredes e atores. Projéteis no ar e HUD continuam 2D, lisos, por cima do 3D
(os projéteis sob um `Node2D` cuja transformação é a afim da câmera).
Detalhes em [`GODOT.md`](GODOT.md#6-pixel-art-no-godot).

## Criatura e animação

> **Faxina de 2026-11-26 (decisão do operador):** o rig próprio (2D e 3D:
> `sim/esqueleto*.gd`, `sim/topologia3d.gd`, `sim/locomocao3d.gd`,
> `sim/modulos.gd`, `jogo/rigs*.gd`, `jogo/pele_geometrica*.gd`,
> `jogo/modulos.gd`, `dados/rig/`, `dados/modulos.json`) foi **removido**. O
> padrão de criatura passa a ser **modelo 3D pronto importado do Sketchfab,
> com pequenos ajustes**. O código antigo é recuperável pelo histórico do git
> (o último commit com ele é `f002dfb`).

No jogo a criatura e o inimigo são **atores 3D provisórios**
(`jogo/mundo3d/ator.gd`) que só leem a sim; a regra de jogo nunca pergunta
como a criatura é desenhada.

**Animação:** a máquina de clipes 2D (`sim/animacao.gd` + `dados/animacoes.json`,
v0.23.0) saiu em 2026-11-27 — o jogo não a usava desde a v0.35 (o ator
provisório não toca clipe); os clipes do modelo importado ganham contrato
próprio quando chegarem (o código segue no git até `a27982d`).
`sim/direcao.gd` mapeia o olhar em 8 setores.

## Mundo e mapa

O mapa é a **Natureza** — o ÚNICO desde 2026-11-27 (decisão do operador: "o
mapa principal agora é o Natureza"; a ilha de teste Fundação, com a extensão
de parkour e o baú, saiu do jogo — o código segue no git até `f38962a`).
`sim/natureza.gd` (pura, semente fixa) gera o mesmo layout como grade da sim
(`mundo_dict`, no formato de mapa de `sim/mundo.gd`: células de terreno +
objetos + início + adversários) e como desenho
(`jogo/mundo3d/natureza/mapa.gd`, deslocado por `origem_3d()` para a célula
da sim cair na unidade 3D e o chão andável em y = 0,4). A escala px+níveis →
unidades 3D é de `jogo/mundo3d/espaco.gd`. O mapa Wang 2D do v0.3 saiu no P24
e na faxina de 2026-11-26. Design: [`gdd/mapa.md`](gdd/mapa.md).

## Atualização do app

`sim/atualizacao.gd` (pura: manifesto, host travado, decisão, tamanho) +
`jogo/atualizador.gd` (HTTP, download, instalador). O método do IASD: [`BUILD.md`](BUILD.md#atualização-automática-do-app).
