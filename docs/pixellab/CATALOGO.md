# PixelLab — catálogo completo das ferramentas MCP

> **Gerado da fonte** por `node tools/pixellab-catalogo.mjs` em 2026-11-20
> (`tools/list` do servidor `https://api.pixellab.ai/mcp`). Não edite à mão:
> rode o script de novo. Esquemas completos (todos os parâmetros) em
> [`ferramentas.json`](ferramentas.json); referência oficial de uma ferramenta,
> grátis: `mcp__pixellab__search_help(tool="<nome>")`. O guia de USO é o
> [`../PIXELLAB.md`](../PIXELLAB.md).

**Total: 140 ferramentas** · 7 recursos de documentação. No DSH cada uma se chama `mcp__pixellab__<nome>`.

| categoria | qtd |
|---|---|
| Retrato e fala | 7 |
| Personagens, estados e animação | 13 |
| Imagem: criar | 5 |
| Imagem: editar, animar e corrigir | 18 |
| Ferramentas exatas (grátis): workbench e VFX | 2 |
| Tiles, tilesets, mapas e salas | 39 |
| Objetos | 13 |
| Áudio | 13 |
| Interface e fontes | 8 |
| Projetos, sandbox e Game Builder (não usamos) | 9 |
| Conta, jobs, ajuda e exportação | 13 |

## Retrato e fala

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `create_portrait_character` | Convert between a portrait and a character sprite (pro). | — | — |
| `create_talking_gif` | Turn text into a talking GIF using a character's existing mouth positions. | grátis | `text_to_speak` |
| `create_vocal_animation` | Generate a talking mouth-position set ("visemes") for a character's portrait. | 3 generations for the default 7 mouth positions on a portrait up to 64px. Two things scale it — the position count sets how many drawing passes | — |
| `get_lip_sync` | Get the lip-sync frame plan for a line of dialogue — for animating in a game. | grátis | `character_id`, `text_to_speak` |
| `get_portrait_character` | Get a portrait ↔ character result by job id. | — | `job_id` |
| `get_vocal_animation` | Check a vocal-animation job and see which mouth positions have landed. | — | `job_id` |
| `set_character_portrait` | Attach a bust portrait to a character, or remove the portrait or one of its | grátis | `character_id` |

## Personagens, estados e animação

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `animate_character` | Queue an animation for a character. Returns job ids at once; ~2-4 min. | template 1 generation per direction up to ~92px (more above; the receipt gives the ceiling). v3 ceil(w*h*frames/65536) per direction on the generated | `character_id` |
| `animate_with_skeleton_v3` | Animate with skeleton v3 (beta): animate a sprite along a skeleton you pose, one per frame. | priced by generation time, which barely moves with length, so every legal frame count falls in one of three steps — 1 to 3 frames = 2 generations, | `description`, `action`, `direction`, `first_frame_keypoints` |
| `create_character` | Queue a character with 4 or 8 directions. Returns its id at once; poll | standard 1 generation at ANY size. v3 from text by size: 2 for 16-90, 3 for 91-128, 4 for 129-156, 5 for 157-181, 6 for 182-202, 7 for 203-221, 8 for | `description` |
| `create_character_pro_flash` | Create a Pro Flash character from text, including its first image and eight V3 views. | the first image PLUS a rotation charge, billed as two separate charges. The image goes by longest side — 5 generations up to 96px, 6 from | `description` |
| `create_character_state` | Queue a state (variant) of an existing character. The new character keeps | ONE charge for the whole state — every rotation the source has, 4 or 8, is redrawn and billed together, so there is no per-direction price and an | `character_id`, `edit_description` |
| `delete_animation` | Delete animations from a character or object. Removes storage files and database rows. | — | `character_id` |
| `delete_character` | Delete ONE state of a character (the given id) with its rotations, | — | `character_id` |
| `estimate_custom_skeleton` | Estimate a custom skeleton (beta): a rig of any shape (wings, tails, weapons, extra legs, a lid) built for a sprite and placed on 1-16 of its frames. | 1 generation per 8 frames started (1-8 frames = 1, 9-16 = 2), charged when the estimate is done. A fully transparent frame is refused, not charged. | — |
| `estimate_skeleton` | Estimate the skeleton of a humanoid sprite: its 18 joints, in exactly the | 0.1 generations, charged when the estimate is done. | — |
| `get_character` | Get character details, rotation URLs, animations, and download link. | — | `character_id` |
| `list_characters` | List your characters with status. Returns compact one-line-per-character format. | — | — |
| `mirror_animation` | Create an animation's missing opposite direction by flipping one horizontally. Free, immediate. | grátis | `asset_id`, `animation_group_id`, `source_direction` |
| `update_character_tags` | Replace ALL tags on a character (set operation, free, synchronous). | grátis | `character_id`, `tags` |

## Imagem: criar

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `create_image_pixen` | Generate a freeform pixel-art image with the Pixen model. | 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id). | `description` |
| `create_image_pixflux` | Generate a freeform pixel-art image from text (no character/object rig). | 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id). | `description` |
| `create_image_pro` | Create Image (Pro): best-quality pixel art, and one call returns a SET of | 10, 15 or 25 generations for the CALL, never per candidate, so a small canvas buys more tries, not a discount. Price and candidate count are one | `description` |
| `create_image_pro_flash` | Create one Pro Flash pixel-art image with an optional left-box style image. | by LONGEST SIDE — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. A non-square canvas goes by its longer side, so | `description` |
| `create_image_pro_from_style` | Create image from style reference (Pro): new pixel art drawn in the style of | 10, 15 or 25 generations for the CALL, never per candidate, and the price does not track size (a bigger canvas can cost less or more): 32px is 10 generations fo | `description`, `style_images` |

## Imagem: editar, animar e corrigir

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `animate_image` | Animate any image from a text description of the motion. | — | `action` |
| `animate_image_pixminimax` | Animate with text (PixMiniMax): animate any image from a motion description. | priced by generation time, which follows the UPSCALED canvas the model works on — x4 up to 64px, x2 up to 128px, x1 above (longer side). So 64, 128 | `description` |
| `correct_pixelart` | Clean up pixel art — sharpen edges, drop stray and anti-aliased pixels. | 0.1 generations. Generation time: ~20-60 seconds (async). Poll with get_image(job_id). | — |
| `create_normal_map` | Make the normal map of a sprite or an animation, so a game engine can light it | Pro 0.5 generation, Lite 0.1 generation — per CALL, not per frame, so a 32-frame strip maps for the same 0.1 as a single sprite and is by far the | `image` |
| `edit_animation` | Edit an animation with a text instruction (pro): the same change on every | by the whole grid, not the frame count — 2 frames cost the same as 16 at 64x64, so batch them. One ascending ladder by FRAME size, both sides | `frames`, `description` |
| `edit_image` | Edit an existing image with a text instruction or a reference image (pro). | 10 generations for any output canvas up to 256x256, 15 up to 341x341, 25 above — so 64x64, 128x128 and 256x256 all cost the same 10, and the frame | — |
| `edit_image_pixen` | Edit an image with a text instruction on the Pixen model (fast, 1 generation). | 1 generation. Generation time: ~10-40 seconds (async). Poll with get_image(job_id). | `description` |
| `edit_image_pro_flash` | Edit one Pro Flash image at its unchanged native canvas size. | by the SOURCE canvas's longest side — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. The same ladder as Pro Flash | — |
| `image_to_pixelart` | Convert an image, render or photo into pixel art. | 1 generation. Generation time: ~20-60 seconds (async). Poll with get_image(job_id). | — |
| `image_to_pixelart_pro` | Convert a picture, render or photo into pixel art with the Pro converter — | 20 generations at any source size. ~1-3 minutes (async). Poll get_image(job_id). | — |
| `image_to_pixelart_pro_flash` | Convert an image, render or photo into pixel art with Pro Flash. | 6 generations. ~30-60 seconds. Returns one queued image; poll get_image(job_id), then download. | — |
| `inpaint_image` | Regenerate one region of an image, keeping everything else pixel-identical. | 10 generations for any SQUARE canvas up to 256x256 (so 64x64 and 88x88 are both 10), 15 up to 341x341, 25 above. The whole image sets the price, not | `description` |
| `inpaint_image_pro_flash` | Replace white-mask pixels with Pro Flash, preserving unmasked RGBA bytes exactly. | by the SOURCE canvas's longest side, not the mask — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256, for one image. So a 64x64 repair | `description` |
| `reduce_colors` | Quantize images onto a smaller, shared palette. | 0.1 generations. Runs locally in about a second — poll once with get_image(job_id). | — |
| `remove_background` | Remove the background from an image you already have, leaving the subject on | 1 generation. Usually ~10-30 seconds (async). Poll get_image(job_id). | `image` |
| `save_to_asset` | Save pixel art into one of your characters, objects, Creator gallery | grátis | `image`, `target` |
| `transfer_outfit` | Reskin an existing animation with the outfit from a reference image (pro). | billed by the whole grid, not the frame count — 2 frames cost the same as 15 at 64x64, so batch them. One ascending ladder by FRAME size, both sides | — |
| `unzoom_image` | Downscale upscaled pixel art back onto its true pixel grid. The result is | 0.1 generations. Takes a few seconds at most — poll get_image(job_id). | — |

## Ferramentas exatas (grátis): workbench e VFX

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `pixelart_workbench` | Run one pixel-art command on a drawing or image you already made. This is | grátis | — |
| `vfx_workbench` | Make an animated pixel-art effect (spell, hit, explosion, aura, projectile, | — | — |

## Tiles, tilesets, mapas e salas

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `create_building_kit` | Create a BUILDING KIT — floor, connectable walls, doorways, pillar, stairs. | `layout` moves the price more than anything else. layout='materials' is 10 generations at every type and every tile_size, because the swatches it | `wall_description`, `floor_description` |
| `create_isometric_tile` | Create an isometric tile. Returns immediately with tile ID. | — | `description` |
| `create_map` | Create an empty map seeded with a tileset and everything connected to it, | free, and so is every other map operation — edit_map, place_map_tiles, place_map_object, edit_map_object, view_map, get_map — except inpaint_map, | `name` |
| `create_map_object` | Create a pixel art object with transparent background. ~30-90s. Returns an | — | `description` |
| `create_path_tiles` | Create a connectable PATH/ROAD tile set (18 configs). | 10-25 generations, set by the SHEET its road set is drawn on — and that set is never shrunk to reach a cheaper canvas the way create_tiles_pro's | `description` |
| `create_room` | Paint one room (a 7 x 6 grid of 32 px floor cells; top-down 256x256 px, or isometric) as pixel | — | `theme`, `doors` |
| `create_sidescroller_tileset` | Generate a sidescroller tileset for 2D platformer games with side-view perspective. | standard is 1 generation now that it runs on pixen. (The classic model it replaced billed 2 or 3 generations — NOT 1, over 1,186 prod charges, mean | `lower_description`, `transition_description` |
| `create_tiles_pro` | Create pixel art tiles (pro): up to 16 independent tiles of one shape per | priced by the sheet, 16 cells of the tile AS DRAWN, so tile_view, tile_view_angle, tile_depth_ratio and tile_height move it as well as tile_size. | `description` |
| `create_topdown_tileset` | Generate a Wang tileset (corner-based autotiling) joining two terrains for a | standard is 1 generation; mode="pro" costs 15 generations for tiles up to 32 px, 25 above. Failed jobs are not charged. | `lower_description`, `upper_description` |
| `cut_out_room_furniture` | Cut a painted room's furniture out as movable pieces, each with its own shadow, so it can be | grátis | `room_id` |
| `delete_isometric_tile` | Delete an isometric tile by ID. Only the owner can delete their own tiles. | — | `tile_id` |
| `delete_map` | Delete one of your maps. Immediate — there is no undo. | — | `map_id` |
| `delete_room` | Permanently delete a room made with create_room. Refused while it (or its furniture's cut) | — | `room_id` |
| `delete_sidescroller_tileset` | Delete a sidescroller tileset by ID. Only the owner can delete their own sidescroller tilesets. | — | `tileset_id` |
| `delete_tiles_pro` | Delete tiles pro by ID. Only the owner can delete their own tiles. | — | `tile_id` |
| `delete_topdown_tileset` | Delete a topdown tileset by ID. Only the owner can delete their own tilesets. | — | `tileset_id` |
| `edit_map` | Paint terrain on a map: rivers and roads with `path`, areas with `rect`. | free. Painting spends no generations however much you repaint — the tileset it draws with was paid for when it was generated. | `map_id`, `ops` |
| `edit_map_areas` | Declare what blocks movement, as Map Workshop's Gameplay Layers do. | — | `map_id` |
| `get_isometric_tile` | Get an isometric tile by ID. Returns tile image and metadata if completed, or progress if processing. | — | `tile_id` |
| `get_map` | Show a map as an ASCII grid, one character per terrain cell. | — | `map_id` |
| `get_map_object` | Get map object status and data. Returns image if completed. | — | `object_id` |
| `get_room` | A room's state. While it is being made: its stage and progress. When ready: the room | grátis | `room_id` |
| `get_sidescroller_tileset` | Get a sidescroller tileset by ID. Returns status, download links, and tile count. | — | `tileset_id` |
| `get_tiles_pro` | Get tiles pro by ID. Returns tile data and storage URLs if completed, or progress if processing. | — | `tile_id` |
| `get_topdown_tileset` | Get a topdown Wang tileset by ID. Returns status, download links, base tile IDs for chaining, and an example map image. | — | `tileset_id` |
| `import_tiles` | Import your own tiles or tileset sheet (free) — what the website's Import does. | grátis | `kind`, `images` |
| `inpaint_map` | Regenerate one rectangular area of a map with AI — a ramp, a broken wall, a | like inpaint_image_pro_flash, by the area's longest side in pixels — 5 generations up to 96px, 6 up to 208px, 9 up to 256px. Not available on | `map_id` |
| `list_isometric_tiles` | List your isometric tiles. One line per tile with status. | — | — |
| `list_map_objects` | List the objects and characters placed on a map, with their cell positions. | — | `map_id` |
| `list_maps` | List your maps, most recently edited first. | — | — |
| `list_rooms` | List your rooms (made with create_room), newest first: id, status, view, name and | — | — |
| `list_sidescroller_tilesets` | List your sidescroller (platformer) tilesets. One line per tileset with status. | — | — |
| `list_tiles_pro` | List your tiles (pro). One line per tile with status. | — | — |
| `list_topdown_tilesets` | List your top-down Wang tilesets. One line per tileset with status. | — | — |
| `move_map_object` | Move a placed object or character to a different cell or an exact pixel, or | grátis | `map_id`, `placement_id` |
| `place_map_object` | Place objects or characters on a map, at a terrain cell or an exact pixel. | grátis | `map_id` |
| `place_map_tiles` | Place, stack and erase tiles on a map's tile layers — the map editor's tile | — | `map_id`, `ops` |
| `remove_map_object` | Remove placed objects or characters from a map. | — | `map_id` |
| `view_map` | Render the map to an image and return it, terrain and objects together. | — | `map_id` |

## Objetos

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `animate_object` | Add an animation to an existing, completed object. Returns one queued job per | v3 ceil(width x height x frames / 65536) per direction, minimum 1: 48x48 or 64x64 at 8 frames = 1, 96x96, 128x96 or 128x128 = 2; width x height x frames | `object_id` |
| `create_1_direction_object` | Queue a 1-direction object (10 or 15 generations, ~2-3 min). Returns object_id | 10 or 15 generations — NEVER 25, because this tool stops at 256px and the 25 band is out of reach. You pay the tier of the whole candidate sheet (your | `description` |
| `create_8_direction_object` | Queue an 8-direction object rendered from 8 angles (10-25 generations, ~2-4 min). | 168px per side is the hard maximum here — a bigger frame is refused before anything is charged, and create_1_direction_object is the one that | `description` |
| `create_object_pro_flash` | Create a Pro Flash object from text, with one direction or eight V3 views. | n_directions=1 is the image alone, by longest side — 5 generations up to 96px, 6 from 100 to 208, 9 from 212 to 256 — so 32x96 and 64x48 are both | `description` |
| `create_object_state` | Queue a state (variant) of an existing object. Auto-waits up to 30s for the | known before the call, and the receipt repeats it. It is ONE charge for the whole state, covering every direction the source has — there is no | `object_id`, `edit_description` |
| `delete_object` | Permanently delete an object, its rotations/frames, animations, tags, | — | `object_id` |
| `dismiss_review` | Discard a review-status object and delete all its candidate frames. | — | `object_id` |
| `expand_object_to_8_directions` | Turn one of your 1-direction objects into an 8-direction one, keeping the | — | `object_id`, `existing_direction` |
| `get_object` | Get object details. Branches by status: | — | `object_id` |
| `import_object` | Import your own pixel art as a 1-direction object. Free, immediate. | grátis | — |
| `list_objects` | List your objects with status and progress. One line per object. | — | — |
| `select_object_frames` | Promote selected frames of a review object to individual completed objects. | — | `object_id` |
| `update_object_tags` | Replace ALL tags on an object (set operation, free, synchronous). | grátis | `object_id`, `tags` |

## Áudio

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `create_music` | Make music for your game: two takes of a song from a description of its style. | 10 generations, or $0.08 in credits, for the two takes; charged once they are made. Needs a tier 2 subscription or higher. | `style` |
| `create_sound_effect` | Make a sound effect for your game from a description: hits, shots, explosions, | by length, charged once the clip is made: 1 generation up to 1.6 s, 2 up to 3.2 s, 4 at 6 s, 7 at 10 s, 19 at 30 s (0.614 per second, rounded up); in | `prompt` |
| `delete_music` | Delete one of your songs from your library and from your games. Immediate; | — | `song_id` |
| `delete_sound_effect` | Delete one of your sound effects from your library and from your games. | — | `sound_effect_id` |
| `get_music` | Check a song's status and get its audio link (MP3) once it is made. | — | `song_id` |
| `get_sound_effect` | Check a sound effect's status and get its audio link (WAV) once it is made. | — | `sound_effect_id` |
| `improve_music_style` | Write a short music idea out as a full style for create_music. | 0.05 generations, or about $0.002 in credits. Synchronous, ~5-15 seconds. | `style` |
| `list_music` | List your songs and loops, newest first: id \| name \| status \| length \| kind. | — | — |
| `list_sound_effects` | List your sound effects, newest first: id \| name \| status \| length. | — | — |
| `make_music_loop` | Make one of your songs into game music that loops seamlessly. | 4 generations, or $0.033 in credits; charged once the takes are made. Needs a tier 2 subscription or higher. | `song_id` |
| `rename_music` | Rename one of your songs, in your library and in the games it is in. | — | `song_id`, `name` |
| `rename_sound_effect` | Rename one of your sound effects, in your library and in the games it is in. | — | `sound_effect_id`, `name` |
| `write_music_lyrics` | Write lyrics for a song: two versions with [Verse]/[Chorus] section tags. | 0.05 generations, or about $0.002 in credits. Synchronous, ~10-20 seconds. | `topic` |

## Interface e fontes

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `create_font` | Create a pixel-art font (pro). | — | `description` |
| `create_ui_asset` | Queue a pixel-art UI panel (10-25 generations, ~2-4 min). Returns ui_asset_id immediately. | 10 generations for a canvas up to 256x256, 15 up to 341x341, 25 above — so the 256x256 default is the cheap option and 512x512 is 25. A non-square | `description` |
| `create_ui_states` | Make states for UI elements (split from a template with update_ui_asset(split=True)): hover, | — | `element_ids`, `states` |
| `delete_ui_asset` | Permanently delete a UI panel (and, for a template, its split elements + their | — | `ui_asset_id` |
| `get_font` | Get a font result by job id. | — | `job_id` |
| `get_ui_asset` | Get a UI asset. Processing → progress; completed → image URL + download links. | — | `ui_asset_id` |
| `list_ui_assets` | List your UI panels with status. One line per asset. | — | — |
| `update_ui_asset` | Edit a UI asset, free (nothing is generated). One change per call: | grátis | `ui_asset_id` |

## Projetos, sandbox e Game Builder (não usamos)

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `add_to_project` | Let a game project use a character, object, tileset, map, room or UI asset you | — | `project_id`, `asset_id` |
| `agent_feedback` | Report something broken, confusing or missing — a PixelLab tool, the sandbox | — | `tool_name`, `feedback_type`, `message` |
| `agent_inspect` | Debug a deployed agent's LIVE runtime: its state, recent chat, LLM/tool traces (errors first, | — | — |
| `agent_list` | List the deployed AI agents you own (the 'deploy your own agent' projects). Returns each | — | — |
| `agent_talk` | Send a message to a deployed agent (as its owner) and get its reply — to test how it responds | — | `message` |
| `list_projects` | List your projects with IDs: game projects (with branches and git clone URLs) and folders, which only group assets on the website. add_to_project files assets into either; manage_project makes, renames or deletes a folder. | — | — |
| `manage_project` | Manage your projects (list_projects shows them). A folder only groups your assets on | — | `action` |
| `remove_from_project` | Stop a game project from using a character, object, tileset, map, room, UI | — | `project_id`, `asset_id` |
| `search_knowledge` | Search the Phaser/game dev knowledge base for tips, patterns, and code examples. | — | `query` |

## Conta, jobs, ajuda e exportação

| ferramenta | o que faz | custo (da doc) | obrigatórios |
|---|---|---|---|
| `cancel_job` | Cancel a pending or processing background job. | work that has not started costs nothing to cancel, but a job already generating is billed for the work done — an image request already sent | `job_id` |
| `export_asset` | Get a download link for a character or object as ZIP, spritesheet, .aseprite or GIF. Free. | grátis | `asset_id`, `format` |
| `get_balance` | Check your account balance: remaining credits (USD) and subscription generations. | — | — |
| `get_image` | Get a raw-image result by job id, or a gallery image by `gallery:<id>`. | — | `job_id` |
| `get_pro_flash_capabilities` | Get Pro Flash exact native size pairs, controls and one-image output counts. | — | — |
| `get_upload_url` | Get a URL to upload a local image file to, without needing your API token. | grátis | — |
| `list_images` | List the images in your Creator gallery (pixellab.ai/create), newest first, | — | — |
| `list_jobs` | List your active background jobs (pending + processing). | — | — |
| `manage_state` | Copy a character or object state, or split it off into an asset of its own. Free. | grátis | `asset_id`, `action` |
| `rename_asset` | Rename a character, object, tileset, map or UI asset, or one animation. Free, immediate. | grátis | `asset_id` |
| `search_help` | Ask for help using PixelLab MCP tools, workflows, or features. | — | — |
| `set_canvas_size` | Change a character's or object's canvas size by adding or removing transparent margin. Free. | grátis | `asset_id`, `width`, `height` |
| `wait_for_jobs` | Wait for your running generations instead of sleeping and polling. | grátis | — |

## Recursos de documentação (MCP resources)

Ler com `read_mcp_resource(server="pixellab", uri=...)`.

| uri | descrição |
|---|---|
| `pixellab://docs/python/sidescroller-tilesets` | Quick Python implementation guide for PixelLab sidescroller tilesets |
| `pixellab://docs/godot/sidescroller-tilesets` | Complete Godot 4.x sidescroller tileset implementation guide with PixelLab MCP integration and headless GDScript converter |
| `pixellab://docs/unity/isometric-tilemaps-2d` | Complete Unity 2D isometric tilemap implementation guide with elevation support |
| `pixellab://docs/godot/isometric-tiles` | Complete Godot 4.x isometric tiles guide with PixelLab MCP integration and proper TileSet configuration |
| `pixellab://docs/godot/wang-tilesets` | Complete Godot 4.x Wang tileset implementation guide with PixelLab MCP integration and headless GDScript converter |
| `pixellab://docs/python/wang-tilesets` | Quick Python implementation guide for PixelLab Wang tilesets |
| `pixellab://docs/overview` | Complete PixelLab platform overview including all interfaces, MCP tools, and integration methods. |
