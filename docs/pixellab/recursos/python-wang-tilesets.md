<!-- pixellab://docs/python/wang-tilesets — copiado por tools/pixellab-catalogo.mjs; não editar -->

# Python Wang Tileset Quick Guide

Minimal implementation for using PixelLab Wang tilesets in Python projects.

> **Transition (cliff) tilesets:** if the metadata has MORE than 16 tiles
> (transition_size=1.0 → 25 tiles, 4×8 sprite sheet), the 16-slot Wang lookup
> below does NOT apply — jump to the "Transition (cliff) tilesets" section.

## Core Implementation

```python
import json
import io
import requests
from PIL import Image

def load_and_render_tileset(metadata_path: str, sprite_sheet_path: str, terrain_grid: list) -> bytes:
    """Load PixelLab tileset (split format) and render a map using Wang tiling."""
    
    # Load metadata JSON
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    
    # Load sprite sheet PNG
    sprite_sheet = Image.open(sprite_sheet_path)
    
    # Extract tiles and size from correct paths
    tiles = metadata['tileset_data']['tiles']
    tile_size = metadata['tileset_data']['tile_size']
    
    # Pre-index tiles by Wang index for O(1) lookup
    tile_lookup = [None] * 16
    
    for tile in tiles:
        corners = tile['corners']

        # `bounding_box` is the tile's exact slice of the sheet. The metadata
        # endpoint computes it for you (it is not stored in the DB, so querying
        # the database for it finds nothing — read it from the response).
        # Do NOT use `original_position` for this — it describes the original
        # generation layout and its row can exceed the sheet.
        box = tile['bounding_box']
        tile_image = sprite_sheet.crop((
            box['x'], box['y'],
            box['x'] + box['width'], box['y'] + box['height'],
        ))
        
        # Calculate Wang index: NW*8 + NE*4 + SW*2 + SE*1
        wang_index = (
            (8 if corners['NW'] == 'upper' else 0) +
            (4 if corners['NE'] == 'upper' else 0) +
            (2 if corners['SW'] == 'upper' else 0) +
            (1 if corners['SE'] == 'upper' else 0)
        )
        tile_lookup[wang_index] = tile_image
    
    # Create map image (4x4 tiles from 5x5 vertices)
    map_width = 4 * tile_size['width']
    map_height = 4 * tile_size['height']
    map_image = Image.new('RGBA', (map_width, map_height))
    
    # Place tiles based on corner vertices
    for y in range(4):
        for x in range(4):
            # Sample 4 corner vertices
            wang_index = (
                8 * terrain_grid[y][x] +      # NW vertex
                4 * terrain_grid[y][x + 1] +  # NE vertex
                2 * terrain_grid[y + 1][x] +  # SW vertex
                1 * terrain_grid[y + 1][x + 1]  # SE vertex
            )
            
            tile_image = tile_lookup[wang_index]
            if tile_image:
                # Place tile on map
                map_image.paste(
                    tile_image,
                    (x * tile_size['width'], y * tile_size['height'])
                )
    
    # Return as PNG bytes
    output = io.BytesIO()
    map_image.save(output, format='PNG')
    return output.getvalue()
```

## Usage Example

```python
# Define terrain (5x5 vertices = 4x4 tiles)
# 0 = lower terrain (e.g., water), 1 = upper terrain (e.g., land)
terrain = [
    [0, 0, 0, 0, 0],
    [0, 0, 1, 1, 0],
    [0, 1, 1, 1, 0],
    [0, 1, 1, 0, 0],
    [0, 0, 0, 0, 0],
]

# Render map (using split format files)
png_bytes = load_and_render_tileset(
    'ocean_beach_metadata.json', 
    'ocean_beach_image.png', 
    terrain
)

# Save to file
with open('map.png', 'wb') as f:
    f.write(png_bytes)
```

## Key Concepts

1. **Vertices define terrain**: 5x5 grid of terrain values produces 4x4 tile map
2. **Wang index calculation**: `NW*8 + NE*4 + SW*2 + SE*1` (0-15)
3. **Corner sampling**: Each tile samples its 4 corner vertices
4. **Pre-indexing**: Build lookup array once for O(1) tile selection

## Example Terrain Pattern

```python
# River pattern for testing
def river_pattern():
    return [
        [1, 1, 0, 1, 1],
        [1, 1, 0, 1, 1],
        [1, 1, 0, 1, 1],
        [1, 1, 0, 1, 1],
        [1, 1, 0, 1, 1],
    ]
```

## Transition (cliff) tilesets — transition_size=1.0

These sets have **25 tiles** in a **4×8 sprite sheet** (not 4×4). Cliff walls get
dedicated tiles and a cliff visually spans TWO stacked map cells: the wall fills
the cell BELOW the upper→lower boundary. Four wall tiles share their corner
values with a twin, so corner-based Wang lookup is ambiguous — you MUST match on
each tile's `pattern_4x4` instead (encoding: 0=lower, 1=upper, 2=transition,
255=wildcard; `row_0`/`row_3` encode the terrain above/below the tile).

```python
def render_transition_map(metadata_path: str, sprite_sheet_path: str, terrain_grid: list) -> bytes:
    """Render a map from a transition_size=1.0 tileset (25 tiles, cliff walls).

    terrain_grid: (rows+1) x (cols+1) vertex grid of 0 (lower) / 1 (upper).
    Cliffs face SOUTH: leave at least one row of lower terrain below a plateau —
    the wall consumes it.
    """
    import json, io
    from PIL import Image

    with open(metadata_path) as f:
        metadata = json.load(f)
    sheet = Image.open(sprite_sheet_path)
    tiles = metadata['tileset_data']['tiles']
    tile_size = metadata['tileset_data']['tile_size']

    # 1) Derive the 3-terrain vertex grid: a lower vertex directly SOUTH of an
    #    upper vertex becomes 'transition' (2) — that band renders the cliff wall.
    v = [row[:] for row in terrain_grid]
    for r in range(1, len(v)):
        for c in range(len(v[0])):
            if v[r][c] == 0 and v[r - 1][c] == 1:
                v[r][c] = 2

    def vertex(r, c):
        if 0 <= r < len(v) and 0 <= c < len(v[0]):
            return v[r][c]
        return None  # outside the map — matches only wildcards

    # 2) For each cell, sample the 4x4 vertex window around it and pick the
    #    best-scoring tile. Center 2x2 matches dominate the score; ring matches
    #    break ties. Scoring (not exact matching) matters because the 25-tile
    #    vocabulary doesn't cover every terrain shape (e.g. one-cell cliff
    #    staircases) — the best partial match still renders correctly.
    CENTER = {(1, 1), (1, 2), (2, 1), (2, 2)}

    def select_tile(cell_r, cell_c):
        window = [[vertex(cell_r - 1 + i, cell_c - 1 + j) for j in range(4)] for i in range(4)]
        best, best_score = None, None
        for tile in tiles:
            pattern = [tile['pattern_4x4'][f'row_{i}'] for i in range(4)]
            score = 0
            for i in range(4):
                for j in range(4):
                    want = pattern[i][j]
                    have = window[i][j]
                    if want == 255 or have is None:
                        continue
                    if have == want:
                        score += 10 if (i, j) in CENTER else 1
                    else:
                        score -= 30 if (i, j) in CENTER else 1
            if best_score is None or score > best_score:
                best, best_score = tile, score
        return best

    rows, cols = len(v) - 1, len(v[0]) - 1
    out = Image.new('RGBA', (cols * tile_size['width'], rows * tile_size['height']))
    for r in range(rows):
        for c in range(cols):
            tile = select_tile(r, c)
            if tile:
                # Transition sheets are NOT array-ordered (tiles repeat and some
                # are absent), so slicing by index is wrong here — but
                # `bounding_box` is computed per tile for this layout too, and is
                # the exact slice. Note the metadata endpoint strips each tile's
                # `image` object, so there is no per-tile URL to fetch.
                box = tile['bounding_box']
                img = sheet.crop((
                    box['x'], box['y'],
                    box['x'] + box['width'], box['y'] + box['height'],
                ))
                out.paste(img, (c * tile_size['width'], r * tile_size['height']))
    buf = io.BytesIO()
    out.save(buf, format='PNG')
    return buf.getvalue()
```

Key points:
- Every tile is one cell high (no double-height images); the cliff LOOK comes
  from the wall tile placed in the cell south of the boundary.
- Only south-facing cliffs get walls; north/west/east plateau edges use the
  normal edge tiles.
- Ties between wall twins at map borders are harmless — the twins are
  pixel-identical; they differ only in which edge sits above them.
- The vocabulary covers straight walls and wall corners; exotic shapes (e.g.
  a cliff edge stepping sideways by a single cell) have no exact tile — the
  scored matcher picks the closest edge tile, which reads fine visually.

## Loading Multiple Connected Tilesets

```python
def load_terrain_chain(tileset_files: list, terrain_layers: list) -> bytes:
    """Load and apply multiple connected tilesets for different terrain elevations."""
    
    # terrain_layers is a list of 5x5 grids, each representing a terrain level
    # tileset_files is a list of JSON files for transitions between levels
    
    # Example usage:
    # ocean_to_beach = load_tileset('ocean_beach.json')
    # beach_to_grass = load_tileset('beach_grass.json')
    # Apply based on terrain elevation values (0, 1, 2, etc.)
    
    pass  # Implementation depends on specific layering strategy
```

This minimal implementation handles the complete Wang tiling workflow for Python projects using PixelLab tilesets.
