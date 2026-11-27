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
  (`arte/fonte/p1-cao-base-pixen.png`, seed 20261120; o PNG saiu na faxina de
  2026-11-26 e fica no histórico do git até `f002dfb`).
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
   a criar; era do P6, descartado em 2026-11-26) passada em `palette` em toda
   geração; uma imagem de estilo aprovada pelo operador reutilizada em
   `style_image`/`style_character_id`.
   Consistência entre evoluções é o problema difícil — ela se COMPRA com âncora
   fixa, não se espera da IA.
2. **Evolução = variante + peças.** Forma-base gerada uma vez; as evoluções
   saem como `create_character_state` da base (identidade preservada) e/ou
   peças trocáveis (asas, galhada, cauda) compostas na `jogo/`.
   Envelhecimento, elemento e aura saem de **shader de paleta** e partículas,
   não de sprite novo.
3. **Câmera única:** **low top-down (20°)** para a arena 2,5D — decidido em
   2026-11-23 (v0.29.0); não misturar. O rig próprio que desenhava o cão nessa
   câmera foi removido em 2026-11-26 (P9/P10 descartados): o padrão de
   criatura passa a ser modelo 3D pronto do Sketchfab com pequenos ajustes —
   fontes, licenças, crédito, prancha e ajustes em [MODELOS-3D](MODELOS-3D.md).
4. **Todo asset entra por script de validação** (`tools/`, a criar; era do
   P6, descartado): tamanho múltiplo de 4, cores ⊂ paleta-mestra, fundo
   transparente, nome no padrão. A IA erra em silêncio; o script não.
5. **O operador aprova a âncora** (prévia em `/sdcard/Download/DSH-Go/`),
   o agente produz as variações.

## Gerado até agora

| arquivo | ferramenta | custo | uso |
|---|---|---|---|
| `arte/fonte/p1-cao-base-pixen.png` | `create_image_pixen` 64, side, seed 20261120 | 1 | prova P1; cópia em `arte/criaturas/cao_base_prova.png` — os dois removidos em 2026-11-26 |
| `arte/cenarios/tilesets/mar_areia.*` | `create_topdown_tileset` standard 32 px, transição 0,25 | 1 | ilha de teste (removido em 2026-11-26) |
| `arte/cenarios/tilesets/areia_grama.*` | idem, `lower_base_tile_id` = areia | 1 | ilha de teste (removido em 2026-11-26) |
| `arte/cenarios/tilesets/grama_planalto.*` | idem, transição 0,5 (penhasco) | 1 | ilha de teste (removido em 2026-11-26) |
| `arte/cenarios/objetos/arvore.png` · `rocha.png` · `estacao.png` | `create_image_pixen` high top-down, seeds 3001–3003 | 3 | ilha de teste (removidos em 2026-11-26) |

Os `.json` dos tilesets guardavam o `pixellab_id` e os `base_tile_ids` (para
encadear novos terrenos sem emenda); tudo isso segue no histórico do git até
`f002dfb`, se o mapa 2D um dia voltar.

## Mata 3D — direção em avaliação (2026-11-26)

A direção pedida pelo operador é **low-poly moderadamente detalhado, com
proporções naturais**: nem o extremo econômico de poucos polígonos, nem
cartoon/caricatura, nem fotorrealismo. Depois do primeiro piloto ele pediu
**cores mais vivas** (verde saturado, água turquesa, terra quente) e que a mata
virasse **mapa de testes jogável** — feito na v0.36.0; desde 2026-11-27 é o
**mapa principal e único** do jogo (a Fundação saiu; ver
[arquitetura](ARQUITETURA.md#mundo-e-mapa)).
Continua uma **proposta visual**, não uma âncora aprovada; o rig próprio foi
removido em 2026-11-26.

- **Uma fonte para regra e desenho:** [sim/natureza.gd](../sim/natureza.gd)
  (pura) dá riacho, trilha, três vaus de cascalho, clareira de terra fofa,
  árvores e troncos caídos, e monta a grade da sim (46×62 células, 1 célula =
  1 unidade); o [mapa](../jogo/mundo3d/natureza/mapa.gd) desenha as MESMAS
  posições e só enfeita (samambaias, sub-bosque, capim, pedras pequenas, folhas
  no chão). Chão andável **plano** (o desenho não diverge dos pés nem do toque);
  só o leito desce. Moldura de mata distante em volta do mapa.
- [Biblioteca autoral](../jogo/mundo3d/natureza/malhas.gd): quatro variantes de
  árvores, ramos curvos de três segmentos, ramúsculos com folhas geométricas,
  ponteiro vivo; três variantes de samambaias, plantas largas, gramíneas e
  rochas, tronco caído com cerne e musgo. Sem esferas de copa, cards
  transparentes ou downloads; **sem custo de PixelLab**; licença do projeto.
- **Materiais próprios** (não toon): [natural](../jogo/mundo3d/natureza/natural.gdshader)
  (sólidos e solo; o solo lê o **mapa do chão** — trilha, mira e perigos ficam
  pintados na terra, como na ilha) e [folha](../jogo/mundo3d/natureza/folha.gdshader)
  (duas faces, luz atravessando). Os dois têm a **copa vazada**: folhas e
  madeira entre a câmera e a criatura somem por dither 4×4, então a criatura
  nunca some sob a mata. Ambientação em `Mapa.ambientar` (tonemap linear,
  saturação +12%, céu azul-claro, sem névoa na vista alta).
- A cena piloto standalone (`--vista-geral`, `--detalhe`, `--verso`) foi
  removida em 2026-11-26: a mata se vê no jogo (é o mapa principal).
- **Medido (seed 500, teste):** 82 árvores, 1.399 instâncias, 21 MultiMeshes,
  615.443 triângulos instanciados, 159.669 vértices armazenados (o solo, em
  passo 0,5, é ~68 mil). Não são triângulos visíveis nem draw calls.
- Testes: [mata](../testes/test_natureza.gd), [regra](../testes/test_natureza_sim.gd)
  (água/troncos bloqueiam, as duas margens alcançáveis a pé pelos vaus) e
  [jogo](../testes/test_mapa_natureza_jogo.gd) (troca de mapa, toque ⇄ chão,
  copa vazada, caminho desenhado andando sem entrar na água).

**Limites deliberados:** água opaca estática (sem reflexo, refração ou
animação); sem vento; o subsolo da mata não existe (só a clareira escava);
FPS no aparelho **não medido** — MultiMeshes cobrem o mapa inteiro, sem setores.
Comandos de render no [oráculo](ORACULO.md#mapa-de-testes-natureza-3d).

## Pastas

```
arte/
  fonte/       # saídas brutas da IA (PNG + json do job), versionadas
  criaturas/   # sprites aprovados e validados, prontos para o Godot
  cenarios/
```
