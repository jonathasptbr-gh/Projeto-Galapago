<!-- pixellab://docs/godot/isometric-tiles — copiado por tools/pixellab-catalogo.mjs; não editar -->

# Isometric Tiles in Godot 4.x for Indie Devs

## AI Assistant Workflow (You Do This)
1. [Generate Isometric Tiles](#generate-isometric-tiles-via-pixellab-mcp)
2. [Create TileSet Resource](#create-tileset-resource)
3. [Create Isometric Scene](#create-complete-isometric-scene)

## User Workflow (They Do This)  
4. [Paint Isometric Level](#user-paint-isometric-level-in-editor)

---

## Generate Isometric Tiles via PixelLab MCP

Create individual isometric tiles with proper 3D appearance:

```python
# Generate grass block
grass_result = create_isometric_tile(
    description="grass block on top of dirt",
    size=32,
    tile_shape="block",
    shading="basic shading",
    detail="medium detail"
)

# Generate stone wall
stone_result = create_isometric_tile(
    description="stone brick wall", 
    size=32,
    tile_shape="block",
    shading="basic shading",
    detail="medium detail"
)

# Check status and get download URLs
grass_tile = get_isometric_tile(tile_id=grass_result["tile_id"])
stone_tile = get_isometric_tile(tile_id=stone_result["tile_id"])
```

**Key Parameters:**
- `size=32` - Optimal for Godot isometric tiles
- `tile_shape="block"` - ~50% canvas height for good 3D depth
- Generation time: ~1-3 minutes per tile

Download tiles after completion:
```bash
# URLs provided by get_isometric_tile tool
curl --fail -o grass_tile.png {download_url}
curl --fail -o stone_tile.png {download_url}  
```

---

## Isometric vs Regular Tiles

**Critical Differences:**
- **Grid**: Diamond shape instead of square
- **Positioning**: Offset required to prevent floating in grid centers
- **Y-Sort**: Required for proper depth rendering
- **Configuration**: Specific TileSet settings needed

---

## Create TileSet Resource

Write `isometric_tileset.tres` with proper isometric configuration:

```tres
[gd_resource type="TileSet" load_steps=5 format=3]

[ext_resource type="Texture2D" path="res://grass_tile.png" id="1"]
[ext_resource type="Texture2D" path="res://stone_tile.png" id="2"]

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]
texture = ExtResource("1")
texture_region_size = Vector2i(32, 32)
0:0/0 = 0
0:0/0/texture_origin = Vector2i(0, -8)

[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_2"] 
texture = ExtResource("2")
texture_region_size = Vector2i(32, 32)
0:0/0 = 0
0:0/0/texture_origin = Vector2i(0, -8)

[resource]
tile_size = Vector2i(32, 16)
tile_shape = 1
tile_layout = 5  
tile_offset_axis = 0
sources/0 = SubResource("TileSetAtlasSource_1")
sources/1 = SubResource("TileSetAtlasSource_2")
```

**Critical Settings:**
- `tile_size = Vector2i(32, 16)` - Grid cell dimensions (width, height)
- `tile_shape = 1` - Enables isometric mode (0=square, 1=isometric)
- `tile_layout = 5` - Diamond Down arrangement
- `texture_origin = Vector2i(0, -8)` - Offsets tiles up from grid centers

---

## Create Complete Isometric Scene

Write `isometric_tilemap.tscn` with Y-sorting enabled:

```tres
[gd_scene load_steps=3 format=3]

[ext_resource type="TileSet" path="res://isometric_tileset.tres" id="1"]
[ext_resource type="Script" path="res://isometric_tilemap.gd" id="2"]

[node name="IsometricTilemap" type="Node2D"]
script = ExtResource("2")
y_sort_enabled = true

[node name="TileMapLayer" type="TileMapLayer" parent="."]
tile_set = ExtResource("1")
y_sort_enabled = true

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(3, 3)
```

Optional helper script `isometric_tilemap.gd`:

```gdscript
extends Node2D

func _ready():
    print("🎯 Isometric Tilemap Ready!")
    print("   TileSet: grass_tile + stone_tile") 
    print("   Y-sorting enabled for proper depth")
    print("
📝 How to paint isometric tiles:")
    print("   1. Select the TileMapLayer node")
    print("   2. Click TileMap tab at bottom")
    print("   3. Select tiles from palette")
    print("   4. Use Paint Tool to draw!")
    print("   5. Tiles snap to isometric diamond grid")
```

**Y-Sort Configuration:**
- `y_sort_enabled = true` on both Node2D and TileMapLayer
- Ensures back tiles render behind front tiles automatically
- Critical for proper 3D depth appearance

---

## User: Paint Isometric Level in Editor

**Complete setup provided above. User opens `isometric_tilemap.tscn` and:**

1. **Select TileMapLayer** node (left scene panel)
2. **Click TileMap tab** (bottom panel, appears when TileMapLayer selected)
3. **Click "Tiles" tab** (next to "Terrains" tab)
4. **Click a tile** in the palette (you'll see grass_tile.png, stone_tile.png)
5. **IMPORTANT: Click the base tile** in the selected tile's preview (small tile icon)
6. **Use Paint Tool** to draw isometric level
7. **Tiles automatically snap** to diamond grid with proper positioning

**Navigation:** Mouse wheel = zoom, Middle click + drag = pan

**Critical Step:** You MUST click the actual base tile in the tile preview after selecting from palette, otherwise painting won't work.

**Result:** Perfect isometric level with proper depth sorting and 3D appearance!

---

## Configuration Reference

### Essential TileSet Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `tile_size` | `Vector2i(32, 16)` | Grid cell dimensions |
| `tile_shape` | `1` | Isometric mode |
| `tile_layout` | `5` | Diamond Down |
| `texture_origin` | `Vector2i(0, -8)` | Offset tiles up |
| `y_sort_enabled` | `true` | Depth sorting |

### Common Issues Fixed

| Problem | Cause | Solution |
|---------|-------|----------|
| Tiles float in grid centers | Missing texture_origin | Set `Vector2i(0, -8)` |
| Square grid instead of diamond | Wrong tile_shape | Set `tile_shape = 1` |
| Wrong depth rendering | No Y-sorting | Enable on both nodes |
| Grid doesn't match tiles | Wrong tile_size ratio | Use `Vector2i(32, 16)` |

---

## Complete Setup Process

```bash
# 1. Generate isometric tiles via MCP
create_isometric_tile(description="grass block", size=32, tile_shape="block")
create_isometric_tile(description="stone wall", size=32, tile_shape="block")

# 2. Check status and get download URLs
get_isometric_tile(tile_id="uuid-from-creation")

# 3. Download tile images
curl --fail -o grass_tile.png {download_url}
curl --fail -o stone_tile.png {download_url}

# 4. Import assets in Godot
godot --headless --import

# 5. Create TileSet with isometric configuration
# - tile_shape=1, tile_layout=5, texture_origin=(0,-8)

# 6. Create scene with Y-sorting enabled
# - Node2D + TileMapLayer both y_sort_enabled=true
```

---

## Success Indicators

The setup works correctly when:
1. ✅ Tiles snap to diamond grid (not square)
2. ✅ Tiles positioned properly (not floating in centers)  
3. ✅ Back tiles render behind front tiles automatically
4. ✅ User can paint isometric levels in editor immediately
5. ✅ 3D depth appearance with 2D tiles

This transforms AI-generated isometric tiles into a professional Godot tilemap system ready for game development!

---

## PixelLab MCP Integration Notes

### Isometric Tile Creation
- Uses synchronous processing (immediate response with image data)
- No background jobs required unlike tilesets
- Direct download URLs provided in tool response
- Tiles are optimized for isometric 3D appearance

### Available Tile Shapes
- `"thin tile"` - ~10% canvas height
- `"thick tile"` - ~25% canvas height  
- `"block"` - ~50% canvas height (recommended for isometric)

### Quality Settings
- `detail`: "low detail", "medium detail", "high detail"
- `shading`: "flat shading", "basic shading", "medium shading", "detailed shading"
- `outline`: "single color outline", "selective outline", "lineless"

