<!-- pixellab://docs/python/sidescroller-tilesets — copiado por tools/pixellab-catalogo.mjs; não editar -->

# Python Sidescroller Tileset Quick Guide

Minimal implementation for using PixelLab sidescroller tilesets in Python 2D platformer games.

## Tileset Format

```json
{
  "tileset_data": {
    "tiles": [
      {
        "id": "uuid",
        "index": 0,
        "corners": {"NW": "lower", "NE": "lower", "SW": "upper", "SE": "upper"},
        "bounding_box": {"x": 0, "y": 0, "width": 16, "height": 16},
        "image": {"base64": "..."}
      }
    ]
  },
  "tile_size": {"width": 16, "height": 16},
  "metadata": {
    "terrain_prompts": {
      "lower": "rock",
      "upper": "transparent background"
    }
  }
}
```

## Core Implementation

```python
import json
from PIL import Image
import io

def load_sidescroller_tileset(metadata_path: str, sprite_sheet_path: str) -> dict:
    """Load PixelLab sidescroller tileset and prepare for 2D platformer use."""
    
    # Load metadata JSON
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    
    # Load sprite sheet PNG
    sprite_sheet = Image.open(sprite_sheet_path)
    
    # Extract tiles with their bounding boxes
    tiles = metadata['tileset_data']['tiles']
    tile_size = metadata['tile_size']
    
    # Extract individual tile images
    tile_images = {}
    
    for tile in tiles:
        bbox = tile['bounding_box']
        
        # Extract tile from sprite sheet using bounding box
        tile_image = sprite_sheet.crop((
            bbox['x'], bbox['y'],
            bbox['x'] + bbox['width'], bbox['y'] + bbox['height']
        ))
        
        tile_images[tile['id']] = {
            'image': tile_image,
            'name': tile.get('name', ''),
            'type': tile.get('type', 'platform'),
            'edges': tile.get('edges', {}),
            'collision': tile.get('collision', {'type': 'solid', 'shape': 'rectangle'})
        }
    
    return {
        'tiles': tile_images,
        'tile_size': tile_size,
        'metadata': metadata
    }


def render_platformer_level(tileset: dict, level_layout: list) -> bytes:
    """Render a 2D platformer level using sidescroller tileset.
    
    Args:
        tileset: Loaded tileset from load_sidescroller_tileset()
        level_layout: 2D array where 1=platform, 0=air
    """
    
    tiles = tileset['tiles']
    tile_size = tileset['tile_size']
    
    # Get available tile IDs
    tile_ids = list(tiles.keys())
    
    # Level dimensions
    level_width = len(level_layout[0])
    level_height = len(level_layout)
    
    # Create level image
    map_width = level_width * tile_size['width']
    map_height = level_height * tile_size['height']
    level_image = Image.new('RGBA', (map_width, map_height), (0, 0, 0, 0))
    
    # Place tiles based on layout
    for y in range(level_height):
        for x in range(level_width):
            if level_layout[y][x] == 1:  # Platform
                # Select tile based on neighbors (simplified edge-matching)
                tile_index = select_platform_tile(level_layout, x, y, len(tile_ids))
                tile_id = tile_ids[tile_index % len(tile_ids)]
                
                tile_image = tiles[tile_id]['image']
                
                # Place tile on level
                level_image.paste(
                    tile_image,
                    (x * tile_size['width'], y * tile_size['height']),
                    tile_image if tile_image.mode == 'RGBA' else None
                )
    
    # Convert to PNG bytes
    img_buffer = io.BytesIO()
    level_image.save(img_buffer, format='PNG')
    return img_buffer.getvalue()


def select_platform_tile(layout: list, x: int, y: int, tile_count: int) -> int:
    """Select appropriate platform tile based on neighbors.
    
    This is a simplified example - real games would use more sophisticated
    edge-matching logic based on the specific tileset structure.
    """
    level_height = len(layout)
    level_width = len(layout[0])
    
    # Check neighbors
    has_left = x > 0 and layout[y][x - 1] == 1
    has_right = x < level_width - 1 and layout[y][x + 1] == 1
    has_above = y > 0 and layout[y - 1][x] == 1
    has_below = y < level_height - 1 and layout[y + 1][x] == 1
    
    # Simple tile selection based on neighboring platforms
    # This would be more complex in a real tileset with specific edge tiles
    
    if not has_above and has_below:
        return 0  # Top edge
    elif has_above and not has_below:
        return 1  # Bottom edge
    elif not has_left and has_right:
        return 2  # Left edge
    elif has_left and not has_right:
        return 3  # Right edge
    elif not has_above and not has_left:
        return 4  # Top-left corner
    elif not has_above and not has_right:
        return 5  # Top-right corner
    elif not has_below and not has_left:
        return 6  # Bottom-left corner
    elif not has_below and not has_right:
        return 7  # Bottom-right corner
    else:
        return 8  # Interior platform
    
    # Fallback to cycling through available tiles
    return (x + y) % tile_count
```

## Example Usage

```python
# Load your sidescroller tileset
tileset = load_sidescroller_tileset(
    'stone_platform_metadata.json',
    'stone_platform_sprite.png'
)

# Define a simple 2D platformer level (1=platform, 0=air)
level_layout = [
    [0, 0, 0, 0, 0, 0, 0, 0],  # Sky
    [0, 0, 0, 1, 1, 0, 0, 0],  # Floating platform
    [0, 0, 0, 0, 0, 0, 0, 0],  # Air
    [1, 1, 1, 1, 1, 1, 1, 1],  # Ground
]

# Render the level
level_png_bytes = render_platformer_level(tileset, level_layout)

# Save or use the rendered level
with open('my_level.png', 'wb') as f:
    f.write(level_png_bytes)
```

## Advanced Collision Detection

```python
def get_tile_collision_data(tileset: dict, tile_id: str) -> dict:
    """Get collision information for a specific tile."""
    tile = tileset['tiles'][tile_id]
    collision = tile.get('collision', {})
    
    return {
        'type': collision.get('type', 'solid'),  # solid, one_way, none
        'shape': collision.get('shape', 'rectangle'),  # rectangle, slope, custom
        'bounds': collision.get('bounds', {
            'x': 0, 'y': 0,
            'width': tileset['tile_size']['width'],
            'height': tileset['tile_size']['height']
        })
    }


def check_collision(tileset: dict, level_layout: list, player_x: float, player_y: float) -> bool:
    """Simple collision checking for player against tileset."""
    tile_size = tileset['tile_size']
    
    # Convert player position to tile coordinates
    tile_x = int(player_x // tile_size['width'])
    tile_y = int(player_y // tile_size['height'])
    
    # Check bounds
    if (tile_x < 0 or tile_x >= len(level_layout[0]) or 
        tile_y < 0 or tile_y >= len(level_layout)):
        return False
    
    # Check if there's a platform tile at this position
    return level_layout[tile_y][tile_x] == 1
```

## Game Engine Integration

### Pygame Example
```python
import pygame

def load_tileset_for_pygame(metadata_path: str, sprite_sheet_path: str):
    """Load tileset optimized for Pygame."""
    tileset = load_sidescroller_tileset(metadata_path, sprite_sheet_path)
    
    # Convert PIL images to Pygame surfaces
    pygame_tiles = {}
    for tile_id, tile_data in tileset['tiles'].items():
        pil_image = tile_data['image']
        
        # Convert PIL to Pygame surface
        pygame_surface = pygame.image.fromstring(
            pil_image.tobytes(), pil_image.size, pil_image.mode
        )
        
        pygame_tiles[tile_id] = {
            'surface': pygame_surface,
            'collision': tile_data['collision']
        }
    
    return {
        'tiles': pygame_tiles,
        'tile_size': tileset['tile_size']
    }
```

## Key Differences from Wang Tilesets

### JSON Structure Differences
1. **Sidescroller**: Nested structure `{"tileset_data": {"tiles": [...]}, "lower_description": "..."}`
2. **Wang**: Nested structure `{"tileset_data": {"tiles": [...]}, "metadata": {...}}`
3. **Terrain Names**: Sidescroller uses `lower_description`/`transition_description`, Wang uses `terrain_prompts`

### Gameplay Differences  
1. **Perspective**: Sidescroller = side-view, Wang = top-down
2. **Background**: Sidescroller = transparent, Wang = terrain-based
3. **Tile Selection**: Sidescroller = edge-based, Wang = corner vertex-based
4. **Use Case**: Sidescroller = 2D platformers, Wang = strategy/RPG games

### Format Adapter (if you need Wang format)
```python
def convert_sidescroller_to_wang_format(sidescroller_metadata: dict) -> dict:
    """Convert sidescroller format to Wang tileset format for compatibility."""
    return {
        "tileset_data": {
            "tiles": sidescroller_metadata["tiles"],
            "tile_size": sidescroller_metadata["tile_size"]
        },
        "metadata": {
            "terrain_prompts": {
                "lower": sidescroller_metadata.get("lower_description", ""),
                "upper": sidescroller_metadata.get("transition_description", "")
            },
            "view": "side",
            "tileset_type": "sidescroller"
        }
    }
```

