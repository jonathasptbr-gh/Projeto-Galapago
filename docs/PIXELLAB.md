# PixelLab — como usar (guia do projeto)

> **Três documentos, três papéis.** Este é o guia de USO: qual ferramenta para
> qual tarefa do Galápago, em que ordem e quanto custa. A LISTA completa
> (140 ferramentas, gerada da fonte) é o [`pixellab/CATALOGO.md`](pixellab/CATALOGO.md),
> com os esquemas em [`pixellab/ferramentas.json`](pixellab/ferramentas.json) e
> os guias oficiais copiados em [`pixellab/recursos/`](pixellab/recursos/). As
> REGRAS de arte (paleta-mestra, âncora, validação) são do [`ARTE.md`](ARTE.md).
>
> Conferido em 2026-11-20: `tools/list` do servidor = 140 = as 140 ferramentas
> visíveis na sessão do agente (diff idêntico). Mudou o PixelLab? Rode
> `node tools/pixellab-catalogo.mjs` e compare.

## 1. Como as ferramentas funcionam

- **Nome no DSH:** `mcp__pixellab__<nome>` (ex.: `mcp__pixellab__get_balance`).
  Conexão, chave e troca de chave: [`ARTE.md`](ARTE.md#conexão-pacote-p1--feita-em-2026-11-20-v011).
- **Tudo que gera é assíncrono.** `create_*`/`animate_*`/`edit_*` devolvem um id
  na hora → `wait_for_jobs` (grátis; espera sem polling; use `timeout_seconds`
  ≤ 55 para não estourar o limite da chamada) → o `get_*` correspondente
  (`get_image`, `get_character`, `get_object`, …) traz imagem e links.
- **Cotar antes, sempre:** `search_help(tool="<nome>")` dá a referência
  completa (opções, preço por tamanho) de graça;
  `get_pro_flash_capabilities(operation=…, width=…, height=…)` cota Pro Flash
  de graça. O preço é por **faixa** de tamanho — não interpole; leia a faixa.
- **Downloads não pedem autenticação:** o UUID é a chave. Os links
  `https://api.pixellab.ai/mcp/images/<job>/download`,
  `/mcp/characters/<id>/download` (ZIP), `/mcp/characters/<id>/spritesheet`
  baixam com `fetch` puro. Trate esses links como semi-privados.
- **Referências de imagem** (onde uma ferramenta pede imagem): prefira id/URL a
  base64 (clientes truncam base64 longo e corrompem a imagem):
  `character:<id>:<direção>`, `character:<id>:<direção>:<animação>`,
  `object:<id>[:<direção>]`, `job:<id>[:<índice>]`, `gallery:<id>`,
  `upload:<id>` (de `get_upload_url` + um POST do arquivo local), URL https.
- **Personagens e objetos ficam guardados na conta** (reusar o id não paga de
  novo). Liste com `list_characters`, `list_objects`, `list_images`.

## 2. A conta (trial) — o que pode e o que não pode

| situação | ferramentas |
|---|---|
| **saldo** | `get_balance`. Trial: 40 gerações + bônus diário de 5 (até 20), gasto só depois das 40 |
| **custo zero** | todos os `get_*`/`list_*`, `wait_for_jobs`, `search_help`, `get_pro_flash_capabilities`, `export_asset`, `mirror_animation`, `import_object`, `import_tiles`, `save_to_asset`, `set_canvas_size`, `manage_state`, renomear/tags, operações de mapa (exceto `inpaint_map`), `create_talking_gif`, `get_lip_sync` |
| **"grátis para assinantes"** | `pixelart_workbench`, `vfx_workbench` — no trial **não testado**; testar com um comando de leitura antes de planejar em cima |
| **exige Tier 1** (não trial) | `create_tiles_pro`, `create_room`, `cut_out_room_furniture`, `edit_animation`, `transfer_outfit`, `image_to_pixelart_pro`, e o `mode="pro"` de `create_topdown_tileset` e `create_sidescroller_tileset` |
| **exige Tier 2** | `create_music`, `make_music_loop`, `create_sound_effect`; `inpaint_image` acima de 256 px |

## 3. Qual ferramenta para qual tarefa do Galápago

Preços: doc da PixelLab em 2026-11-20 (64×64 salvo indicação). Confirme com
`search_help` antes de gerar em quantidade.

### Explorar uma ideia (barato)

| tarefa | ferramenta | custo |
|---|---|---|
| esboço de criatura/objeto/cenário | `create_image_pixen` (sprites pequenos mais limpos; até 768 px de lado, área ≤ 512×512) | 1 |
| variação de uma imagem existente (img2img) | `create_image_pixflux` com `init_image_*` — **`init_image_strength` é invertido**: 500 quase não muda, 150 é edição real, 50 só guarda a composição | 1 |
| imagem de qualidade, com paleta fixa | `create_image_pro_flash` (`palette`, `style_image`) | 5 até 96 px |
| várias tentativas de uma vez | `create_image_pro` (devolve um LOTE de candidatos; 10 gerações pela chamada) | 10–25 |

### A criatura (o coração do jogo)

1. **Forma-base com esqueleto** — quadrúpedes reais (cão, gato, cavalo, leão,
   urso): `create_character_pro_flash(template_id="dog", width=64, height=64,
   description="… standing on all four legs")` = 6, 8 direções, com esqueleto
   (anima por template). Diga "standing on all four legs": sem isso sai sentado.
   Barato e mais simples: `create_character(mode="standard",
   body_type="quadruped", template="dog")` = 1.
2. **Corpo que nenhum template cobre** (lobo de 6 patas, peixe de gelo, ave de
   folha): `template_id="custom"` — **sem esqueleto**: anima só por
   `mode="v3"` ou `"pixminimax"`. O corpo é fixado na criação; errar o template
   custa a criatura inteira de novo. Alternativa: desenhar o sprite
   (`create_image_pro_flash`) e girar com `create_character(mode="pro",
   reference_image_url=…)`.
3. **Evolução que preserva a identidade** (o cão que vira raposa de fogo):
   `create_character_state(character_id, edit_description=…)` = 10 (arte ≤ 70 px),
   todas as direções redesenhadas juntas. Para asas, `override_width/height`
   (atenção: o preço passa a ser pelo canvas novo — 128×128 = 25). Use
   `use_color_palette_from_reference=true` só quando a evolução NÃO traz cor nova.
4. **Outra espécie no mesmo estilo:** `create_character(mode="pro",
   style_character_id=<base>)` (10 até 85 px) ou Pro Flash com o MESMO
   `style_image` âncora em toda chamada.
5. **Animação:**
   - `animate_character(template_animation_id=…)` — 1 por direção até ~92 px;
     ids inválidos são recusados de graça com a lista (`get_character` mostra
     `available_animations`);
   - `mode="v3"` (movimento descrito; ⌈w·h·quadros/65536⌉ por direção),
     `"pixminimax"` (até 40 quadros, beta), `"skeleton-v3"` (2–4 por direção);
   - `mirror_animation` cria east↔west de graça (cuidado com assimetria);
   - corpo customizado com asas/cauda: `estimate_custom_skeleton` (1 por 8
     quadros) + `animate_with_skeleton_v3`.
6. **Envelhecimento, elemento, aura:** NÃO gere sprite novo — shader de paleta
   e partículas no Godot ([`GODOT.md`](GODOT.md)). Efeito desenhado (fogo,
   faíscas, gelo): `vfx_workbench` (exporta GIF + spritesheet + JSON).
7. **Luz:** `create_normal_map(mode="lite")` = 0,1 **por chamada** (até 32
   quadros) → `CanvasTexture.normal_texture` no Godot, `convention="opengl"`.

### Cenário (ilha, laboratório, microambientes)

| tarefa | ferramenta | custo |
|---|---|---|
| terreno com transição (areia↔mar, grama↔terra) | `create_topdown_tileset` standard (Wang, 16 tiles) — encadear terrenos pelo `base_tile_id` de `get_topdown_tileset` | 1 |
| plataforma em vista lateral | `create_sidescroller_tileset` standard | 1 |
| prop solto (rocha, árvore, máquina) | `create_1_direction_object` (lote de candidatos → `select_object_frames`) | 10–15 |
| montar um mapa | `create_map` → `edit_map` (pinta regiões) → `place_map_object` → `view_map` | 0 |
| **exportar mapa para Godot** | `get_map(map_id, export="godot")` → link de um **projeto Godot 4 em ZIP** | 0 |
| fundo de tela (parallax) | `create_image_pixen` 320×180 (`no_background=false`) | 1 |

Guias oficiais de Godot copiados em `pixellab/recursos/`:
`godot-wang-tilesets.md`, `godot-sidescroller-tilesets.md`,
`godot-isometric-tiles.md` (todos com conversor GDScript headless).

### Consertar e padronizar

| tarefa | ferramenta | custo |
|---|---|---|
| uma região errada (pata, olho) | `inpaint_image_pro_flash` (máscara retangular ou PNG preto/branco puro) | 5 até 96 px |
| edição por texto de uma imagem | `edit_image_pixen` (1 quadro, lados múltiplos de 4) · `edit_image_pro_flash` · `edit_image` (até 16 quadros iguais) | 1 · 5 · 10 |
| mesma paleta em várias imagens/quadros | `reduce_colors` (todas juntas numa chamada; `palette_image_*` força a paleta do jogo) | 0,1 |
| limpar pixels soltos/serrilhado | `correct_pixelart` (strength 0,1) | 0,1 |
| inspecionar/medir/editar pixel a pixel | `pixelart_workbench` (`describe cli`, `lint`, `inspect`, `extract-palette`, `repair`, `split`, `join`, `scale`) | grátis* |
| salvar a correção de volta no asset | `save_to_asset(image, target="character:<id>:<dir>")` | 0 |

### Interface

`create_ui_asset` (painel, 10 até 256×256) → `update_ui_asset(split=true)`
separa botões → `create_ui_states` (hover/pressed) → `update_ui_asset(nine_slice=…)`
para esticar sem borrar (vira `NinePatchRect` no Godot). `create_font` = 15
(atlas + `.ttf`).

## 4. Tirar do PixelLab e pôr no Godot

| o quê | como | no Godot |
|---|---|---|
| imagem avulsa | `get_image(job_id)` → link de download | `Sprite2D`/`TextureRect`, filtro *nearest* |
| personagem completo | `export_asset(asset_id, format="spritesheet")` → ZIP com PNG + JSON (`cell_size`, `rows`: animação × direção) | `SpriteFrames` gerado por script a partir do JSON → `AnimatedSprite2D` |
| personagem por arquivo | `/mcp/characters/<id>/download` → `<estado>/rotations/<dir>.png`, `<estado>/animations/<nome>/<dir>/frame_000.png` + `metadata.json` | idem, um quadro por arquivo |
| Aseprite | `export_asset(format="aseprite")` | editar fora; exportar PNG |
| mapa | `get_map(export="godot")` | projeto Godot 4 pronto (TileSet + cena) |

Onde guardar: bruto da IA em `arte/fonte/` (tem `.gdignore`: o Godot não
importa) com o JSON do job; o aprovado e validado vai para `arte/criaturas/` ou
`arte/cenarios/` (o Godot importa). Ver [`ARTE.md`](ARTE.md).

## 5. O que não usamos (e por quê)

`add_to_project`, `remove_from_project`, `list_projects`, `manage_project`,
`agent_*`, `search_knowledge`: servem ao Game Builder da PixelLab (jogos em
Phaser hospedados lá). O nosso jogo é Godot, no nosso repositório.
`create_vocal_animation`/`create_talking_gif`/`get_lip_sync` (boca falando)
ficam para quando houver diálogo com retrato — decisão de design pendente.

## 6. Disciplina de custo (regra do projeto)

1. `search_help`/`get_pro_flash_capabilities` antes de qualquer ferramenta nova.
2. Explorar no barato (Pixen/Pixflux, 1), decidir com o operador, só então
   gastar no caro (Pro Flash, estados, animações).
3. Nunca gerar em laço sem teto; um lote por decisão.
4. Registrar no `docs/HISTORICO.md` o que foi gerado, com seed e custo.
