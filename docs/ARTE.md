# Pipeline de arte

## Ferramenta: PixelLab (MCP)

> **Como usar cada ferramenta:** [`PIXELLAB.md`](PIXELLAB.md). Lista completa
> gerada da fonte: [`pixellab/CATALOGO.md`](pixellab/CATALOGO.md).

PixelLab gera pixel art de jogo: personagens 4/8 direções (com *templates* de
quadrúpede: `dog`, `cat`, `horse`, `lion`, `bear`, ou `custom` sem esqueleto),
animações, **estados/variantes de um mesmo personagem**
(`create_character_state`, mantém identidade e proporções), tilesets, mapas,
objetos, edição/inpaint, efeitos sonoros e música. Referência das ferramentas:
<https://api.pixellab.ai/mcp/docs>. Tudo é **assíncrono** (job → ~2–5 min →
`get_*`) e **cobrado em gerações** — o custo de cada chamada está na doc; as
ferramentas `get_*_capabilities` cotam de graça antes de gastar.

### Conexão (pacote P1 — feita em 2026-11-20, v0.1.1)

- Chave: conta do operador, em <https://api.pixellab.ai/mcp>. Mora **só** no
  cofre do harness: `~/.dsh/.credentials.yaml`, `refs.PIXELLAB_TOKEN` (600).
  Nunca em chat, commit ou documento.
- Entrada `id: mcp-pixellab` (`@deepseek-ai/dsh-mcp-client`,
  `transport: streamable-http`, `url: https://api.pixellab.ai/mcp`) num
  `- insert:` ao fim de `~/.dsh/profiles/web/cordis.patch.yml`. O cabeçalho
  `Authorization` é um `!!js` que lê o cofre com
  `process.getBuiltinModule("fs")` — o cofre NÃO vira `process.env`, e o `!!js`
  roda no escopo global do Node (`with (ctx) eval(expr)`), por isso dá.
- O DSH recarregou o patch a quente: as ferramentas `mcp__pixellab__*`
  apareceram na mesma sessão. **Trocar a chave** = editar a ref no cofre e
  reiniciar o motor (a expressão só é avaliada ao montar a entrada).
- Prova: `get_balance` pela integração + 1 geração `create_image_pixen`
  (`arte/fonte/p1-cao-base-pixen.png`, seed 20261120).
- Conta: **trial, 40 gerações** + bônus diário de 5 (acumula até 20), que só é
  gasto depois das 40. Planejar cada chamada.

### Custo de referência (doc da PixelLab, 2026-11-20)

| ferramenta | custo | uso |
|---|---|---|
| `create_image_pixen` / `create_image_pixflux` | 1 | exploração barata, peças avulsas |
| `create_image_pro_flash` 64×64 | 5 | imagem de qualidade, aceita `palette` |
| `create_character_pro_flash` 64×64 (8 direções, `template_id=dog`) | 6 | criatura com esqueleto animável |
| `create_character_state` (arte ≤70 px) | 10 | variante/evolução mantendo identidade |
| `animate_character` template ≤92 px | 1 por direção | animações de esqueleto |
| `pixelart_workbench`, `reduce_colors` | grátis / 0,1 | inspeção, limpeza, paleta — feitos por nós |

`search_help(tool="<nome>")` dá a referência completa de graça.

## Regras de produção

1. **Uma âncora de estilo por projeto.** Paleta-mestra fixa (`arte/paleta.json`,
   a criar no P6) passada em `palette` em toda geração; uma imagem de estilo
   aprovada pelo operador reutilizada em `style_image`/`style_character_id`.
   Consistência entre evoluções é o problema difícil — ela se COMPRA com âncora
   fixa, não se espera da IA.
2. **Evolução = variante + peças.** Forma-base gerada uma vez; as evoluções
   saem como `create_character_state` da base (identidade preservada) e/ou
   peças trocáveis (asas, galhada, cauda) compostas na `jogo/`.
   Envelhecimento, elemento e aura saem de **shader de paleta** e partículas,
   não de sprite novo.
3. **Câmera única:** **low top-down (20°)** para a arena 2,5D — decidido em
   2026-11-23 (v0.29.0); não misturar. O cão desenha o esqueleto 3D projetado
   nessa câmera (`sim/esqueleto3d.gd`, `dados/rig/canino3d.json`); a pele de
   pixel art em camadas é o alvo seguinte (fila P9).
4. **Todo asset entra por script de validação** (`tools/`, a criar no P6):
   tamanho múltiplo de 4, cores ⊂ paleta-mestra, fundo transparente, nome no
   padrão. A IA erra em silêncio; o script não.
5. **O operador aprova a âncora** (prévia em `/sdcard/Download/DSH-Go/`),
   o agente produz as variações.

## Gerado até agora

| arquivo | ferramenta | custo | uso |
|---|---|---|---|
| `arte/fonte/p1-cao-base-pixen.png` | `create_image_pixen` 64, side, seed 20261120 | 1 | prova P1; cópia provisória em `arte/criaturas/cao_base_prova.png` |
| `arte/cenarios/tilesets/mar_areia.*` | `create_topdown_tileset` standard 32 px, transição 0,25 | 1 | ilha de teste |
| `arte/cenarios/tilesets/areia_grama.*` | idem, `lower_base_tile_id` = areia | 1 | ilha de teste |
| `arte/cenarios/tilesets/grama_planalto.*` | idem, transição 0,5 (penhasco) | 1 | ilha de teste |
| `arte/cenarios/objetos/arvore.png` · `rocha.png` · `estacao.png` | `create_image_pixen` high top-down, seeds 3001–3003 | 3 | ilha de teste |

Os `.json` dos tilesets guardam o `pixellab_id` e os `base_tile_ids` (para
encadear novos terrenos sem emenda).

## Piloto de natureza 3D — direção em avaliação (2026-11-26)

A direção pedida pelo operador é **low-poly moderadamente detalhado, com
proporções naturais**: nem o extremo econômico de poucos polígonos, nem
cartoon/caricatura, nem fotorrealismo. O ensaio busca mata úmida densa, árvores
esguias irregulares com galhos afilados e folhas recortadas, samambaias,
sub-bosque, raízes, troncos caídos, rochas e riacho sinuoso; uma trilha/clareira
preserva a leitura do chão. É uma **proposta visual**, não uma âncora já aprovada
pelo operador, e não muda o jogo padrão nem o rig congelado.

- Cena separada: [piloto](../jogo/mundo3d/natureza/piloto.tscn), montada por
  [piloto.gd](../jogo/mundo3d/natureza/piloto.gd). Retrato 720×1280, 3D liso
  por padrão, câmera fixa inclusive em `--demo`. A perspectiva próxima examina
  detalhes; `--vista-geral` é ortográfica alta/3-4, para julgar leitura de mapa.
- [Biblioteca autoral](../jogo/mundo3d/natureza/malhas.gd): quatro variantes de
  árvores, ramos curvos de três segmentos, ramúsculos com folhas geométricas
  menores, ponteiro vivo; três variantes de samambaias, plantas largas,
  gramíneas e rochas, além de tronco caído com cerne e musgo geométrico. Não há
  esferas de copa, cards transparentes ou downloads. Geração procedural local,
  **sem custo de PixelLab**; licença do próprio projeto, sem atribuir CC0.
- [Mapa](../jogo/mundo3d/natureza/mapa.gd): seed fixa **20261126**, relevo e
  cores contínuos por vértice (terra/folhas/musgo, sem xadrez), leito rebaixado,
  margens e trilha seca. Materiais StandardMaterial3D baratos com luz/sombra
  contínuas; nenhum toon ou contorno grosso. Reutiliza apenas a instância local
  de Vista como compositor; o contorno dela fica sem camada de render.
- **Medido na seed padrão:** 82 árvores; 1.393 instâncias de malha (madeira e
  folhas de uma árvore são duas instâncias); 21 MultiMeshes e 25 nós no mapa;
  600.503 triângulos instanciados e 126.633 vértices armazenados nas malhas
  compartilhadas. Não são contagens de triângulos visíveis nem de draw calls.
- [Testes headless](../testes/test_natureza.gd): seed/replay de distribuição e
  cores em todos os lotes, reconstrução sem acumular, orçamento, cena/câmeras,
  normais/vértices finitos, winding horário coerente, ausência de triângulos
  degenerados e validação do leito/margens/trilha. Nenhum teste exige render.

**Limites deliberados:** standalone visual, **sem navegação, colisões ou
integração com gameplay**. Água opaca estática com filetes geométricos, sem
reflexo de tela/refração, vento ou animação. Não há FPS mobile comprovado: os
MultiMeshes ainda cobrem o mapa inteiro, sem divisão por setores; render por
software não mede desempenho de aparelho. Comandos e ressalvas de render no
[oráculo](ORACULO.md#piloto-de-natureza-3d-standalone).

## Pastas

```
arte/
  fonte/       # saídas brutas da IA (PNG + json do job), versionadas
  criaturas/   # sprites aprovados e validados, prontos para o Godot
  cenarios/
```
