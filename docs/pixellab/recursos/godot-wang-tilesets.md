<!-- pixellab://docs/godot/wang-tilesets — copiado por tools/pixellab-catalogo.mjs; não editar -->

# Wang Tilesets in Godot 4.x for Indie Devs

## AI Assistant Workflow (You Do This)
1. [Generate Tilesets](#generate-tilesets-via-pixellab-mcp)
2. [Convert to Godot](#convert-to-godot-format) 
3. [Create Scene Files](#create-complete-scene-files)

## User Workflow (They Do This)
4. [Paint Terrain](#user-paint-terrain-in-editor)

> **Transition (cliff) tilesets:** if the metadata has MORE than 16 tiles
> (transition_size=1.0 → 25 tiles, 4×8 sprite sheet), Godot's corner-based
> terrain system below does NOT apply — four wall tiles share identical corners
> and only differ by vertical context, which peering bits can't express. Use
> the [Transition (cliff) tilesets](#transition-cliff-tilesets-transition_size10)
> section at the end instead.

---

## Generate Tilesets via PixelLab MCP

Create connected terrain systems using base tile IDs:

```python
# Ocean → Beach
ocean_beach = create_tileset(
    lower_description="deep ocean water",
    upper_description="sandy beach",
    transition_description="wet sand with foam"
)

# Beach → Grass (using beach base tile for seamless connection)
beach_grass = create_tileset(
    lower_description="sandy beach", 
    upper_description="lush grass",
    lower_base_tile_id=ocean_beach.base_tiles.upper,
    transition_description="sparse grass on sand"
)
```

Download split format files after generation (~100s):
- `/mcp/tilesets/{id}/metadata` → `ocean_beach_metadata.json`
- `/mcp/tilesets/{id}/image` → `ocean_beach_image.png`

## Convert to Godot Format

Run converter with JSON/PNG pairs:

```bash
godot --headless -s pixellab_tileset_converter.gd ocean_beach_metadata.json ocean_beach_image.png beach_grass_metadata.json beach_grass_image.png
```

Creates `combined_terrain.tres` with all terrains configured for corner-based painting.

---

## Wang Tile System Overview

### Corner Matching
```
┌──┬──┐
│NW│NE│  Each corner can be:
├──┼──┤  - Terrain 0 (e.g., Ocean)
│SW│SE│  - Terrain 1 (e.g., Beach)
└──┴──┘  - Terrain 2 (e.g., Grass)
```

### Tile Count Math
- **2 terrains**: 2^4 = 16 tiles
- **3 terrains**: 3^4 = 81 tiles  
- **4+ terrains**: Use selective transitions to avoid exponential growth

### Binary Index (2 terrains)
```
Index = NW*8 + NE*4 + SW*2 + SE*1
Example: Beach(1) corners NW+NE, Ocean(0) corners SW+SE = Index 12
```

---

## Create Complete Scene Files

Write this `.tscn` file directly (Godot 4.x scene format):

```
[gd_scene load_steps=3 format=3]

[ext_resource type="TileSet" path="res://combined_terrain.tres" id="1"]
[ext_resource type="Script" path="res://terrain_painter.gd" id="2"]

[node name="TerrainPainting" type="Node2D"]
script = ExtResource("2")

[node name="TileMapLayer" type="TileMapLayer" parent="."]
tile_set = ExtResource("1")

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(0.5, 0.5)
```

Optional helper script `terrain_painter.gd`:

```gdscript
extends Node2D

func _ready():
    print("🎨 Terrain painting ready! Select TileMapLayer → TileMap tab → Terrains → Rect Tool (R)")

func _input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        $TileMapLayer.clear()
        print("Map cleared")
```

---

## User: Paint Terrain in Editor

**Complete setup provided above. User opens `terrain_painting.tscn` and:**

1. **Select TileMapLayer** node (left scene panel)
2. **Click TileMap tab** (bottom panel, appears when TileMapLayer selected)  
3. **Click Terrains tab** (next to "Tiles" tab)
4. **Choose terrain** from palette (Ocean, Beach, Grass)
5. **Click Rect Tool (R)** (rectangle icon in toolbar)
6. **Draw rectangles** in viewport → terrain paints automatically!

**Navigation:** Mouse wheel = zoom, Middle mouse + drag = pan

**Important:** Must use Rect Tool (R), not Paint Tool (D) for corner-based terrains.

### Optional: Programmatic Terrain Generation

If the user wants to generate terrain programmatically later:

```gdscript
# Paint terrain areas programmatically
func paint_terrain_area(tile_map: TileMapLayer, cells: Array[Vector2i], terrain_id: int):
    tile_map.set_cells_terrain_connect(0, cells, 0, terrain_id)

# Example: Create an island
func create_island_terrain(tile_map: TileMapLayer, center: Vector2i, radius: int):
    var ocean_cells = []
    var beach_cells = []
    var grass_cells = []
    
    for x in range(-radius, radius + 1):
        for y in range(-radius, radius + 1):
            var pos = center + Vector2i(x, y)
            var distance = Vector2(x, y).length()
            
            if distance > radius * 0.8:
                ocean_cells.append(pos)
            elif distance > radius * 0.5:
                beach_cells.append(pos)
            else:
                grass_cells.append(pos)
    
    # Paint terrains (0=Ocean, 1=Beach, 2=Grass)
    paint_terrain_area(tile_map, ocean_cells, 0)
    paint_terrain_area(tile_map, beach_cells, 1)
    paint_terrain_area(tile_map, grass_cells, 2)
```

## Using the Converter Script

### Purpose of the Converter

The converter transforms PixelLab JSON tilesets into Godot's terrain system format, enabling visual terrain painting in the editor. Without this conversion, the user would need to manually place individual tiles.

### How the Converter Works

The converter:
1. **Accepts JSON files as command-line arguments** - no hardcoded configuration needed
2. **Automatically extracts terrain names** from the JSON descriptions
3. **Detects tile size** from the first tileset (supports 16x16, 32x32, etc.)
4. **Samples terrain colors** from base tiles (where all 4 corners are the same)
5. **Arranges tiles** in a specific corner-based layout for optimal terrain painting
6. **Generates a Godot .tres file** with proper terrain configuration

### Running the Converter

Save the script as `pixellab_tileset_converter.gd` and run with your JSON files:

```bash
# Two-terrain system (simplest):
godot --headless -s pixellab_tileset_converter.gd ocean_beach_metadata.json ocean_beach_image.png

# Three-terrain system (recommended for most games):
godot --headless -s pixellab_tileset_converter.gd ocean_beach_metadata.json ocean_beach_image.png beach_grass_metadata.json beach_grass_image.png

# Four or more terrains (advanced):
godot --headless -s pixellab_tileset_converter.gd ocean_beach_metadata.json ocean_beach_image.png beach_grass_metadata.json beach_grass_image.png grass_forest_metadata.json grass_forest_image.png
```

The converter automatically:
- Extracts terrain names from the JSON files
- Detects tile size from the first tileset
- Samples colors from base tiles (where all corners are the same terrain)
- Arranges tiles in an optimal layout for Godot's terrain system

### Complete Converter Script

Save this as `pixellab_tileset_converter.gd` in your project:

```gdscript
extends SceneTree

# PixelLab to Godot Tileset Converter (Split Format)
# Converts PixelLab metadata JSON + PNG sprite sheets to Godot terrain system
# Usage: godot --headless -s pixellab_tileset_converter.gd metadata1.json image1.png metadata2.json image2.png ...

var output_path = "combined_terrain.tres"
var tile_size = 0
var terrains = {}
var tiles = []

# Corner-based tile layout for optimal terrain painting
# Format: "nw,ne/sw,se" where w=water/lower, s=sand/upper
var corner_layout = [
	# Row 0
	"ss/sw", "ss/ww", "ss/ws", "ww/ws", "ww/sw",
	# Row 1
	"sw/sw", "ww/ww", "ws/ws", "ws/ww", "sw/ww",
	# Row 2
	"sw/ss", "ww/ss", "ws/ss", "ws/sw", "sw/ws",
	# Row 3
	"ww/ww", "ss/ss", "", "", ""
]

func _init():
	print("
🎨 PixelLab to Godot Converter (Split Format)")
	print("==========================================")
	
	# Parse command line arguments to find JSON/PNG pairs
	var tileset_pairs = []
	var args = OS.get_cmdline_args()
	
	for i in range(args.size()):
		if args[i].ends_with("_metadata.json"):
			var json_path = args[i]
			var expected_png = json_path.replace("_metadata.json", "_image.png")
			
			# Look for the corresponding PNG file in arguments
			var png_path = ""
			for j in range(args.size()):
				if args[j] == expected_png:
					png_path = args[j]
					break
			
			if png_path != "":
				tileset_pairs.append({"json": json_path, "png": png_path})
			else:
				print("⚠️  PNG file not found for %s (expected: %s)" % [json_path, expected_png])
	
	if tileset_pairs.is_empty():
		print("❌ No valid JSON/PNG pairs found!")
		print("Usage: godot --headless -s pixellab_tileset_converter.gd metadata1.json image1.png metadata2.json image2.png")
		print("Expected file naming: *_metadata.json and *_image.png")
		quit()
		return
	
	print("📦 Found %d tileset pairs:" % tileset_pairs.size())
	for pair in tileset_pairs:
		print("   %s + %s" % [pair.json, pair.png])
	
	# Process each tileset pair
	for pair in tileset_pairs:
		load_tileset_pair(pair.json, pair.png)
	
	if tiles.is_empty():
		print("❌ No tiles loaded")
		quit()
		return
	
	# Create and save tileset
	create_tileset()
	print("
✅ Created: %s" % output_path)
	print("   Terrains: %s" % ", ".join(terrains.values()))
	print("
📝 Usage in Godot Editor:")
	print("   1. Add a TileMapLayer node to your scene")
	print("   2. Assign %s as the tile_set" % output_path)
	print("   3. Select the TileMapLayer node")
	print("   4. In TileMap panel, click 'Terrains' tab")
	print("   5. Select a terrain (e.g., grass)")
	print("   6. Use Rect Tool (R) to paint terrain")
	print("      Note: Paint Tool (D) won't work with corner-based terrains")
	print("   7. Draw rectangles to automatically blend terrains!")
	quit()

func load_tileset_pair(json_path: String, png_path: String):
	print("
📁 Loading %s + %s..." % [json_path, png_path])
	
	# Read metadata JSON
	if not FileAccess.file_exists(json_path):
		print("  ❌ Metadata file not found")
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("  ❌ Invalid JSON")
		return
	file.close()
	
	var metadata = json.data
	
	# Load PNG sprite sheet
	if not FileAccess.file_exists(png_path):
		print("  ❌ PNG file not found")
		return
	
	var sprite_sheet = Image.new()
	if sprite_sheet.load(png_path) != OK:
		print("  ❌ Failed to load PNG")
		return
	
	# Get tile size (only from first tileset)
	if tile_size == 0:
		var size = metadata.tileset_data.tile_size
		tile_size = size.width
		print("  Tile size: %dx%d" % [tile_size, tile_size])
	
	# Get terrain names from metadata
	var lower_name = metadata.metadata.terrain_prompts.lower
	var upper_name = metadata.metadata.terrain_prompts.upper
	
	# Add terrains to our list
	var lower_id = get_terrain_id(lower_name)
	var upper_id = get_terrain_id(upper_name)
	
	# Index tiles by Wang number
	var wang_tiles = {}
	for i in range(metadata.tileset_data.tiles.size()):
		var tile = metadata.tileset_data.tiles[i]
		var corners = tile.corners

		# `bounding_box` is the tile's exact slice of the sheet. The metadata
		# endpoint computes it for you (it is not stored in the database, so
		# querying the DB for it finds nothing — read it from the response).
		# Do NOT use `original_position`: it describes the original generation
		# layout and its row can exceed this sheet.
		var box = tile.bounding_box
		var width = int(box.width)
		var height = int(box.height)
		var x = int(box.x)
		var y = int(box.y)
		
		var tile_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
		tile_image.blit_rect(sprite_sheet, Rect2i(x, y, width, height), Vector2i.ZERO)
		
		# Calculate Wang index
		var nw = 1 if corners.NW == "upper" else 0
		var ne = 1 if corners.NE == "upper" else 0
		var sw = 1 if corners.SW == "upper" else 0
		var se = 1 if corners.SE == "upper" else 0
		var wang_idx = nw * 8 + ne * 4 + sw * 2 + se
		
		wang_tiles[wang_idx] = {
			"image": tile_image,
			"corners": [
				upper_id if nw == 1 else lower_id,
				upper_id if ne == 1 else lower_id,
				upper_id if sw == 1 else lower_id,
				upper_id if se == 1 else lower_id
			]
		}
	
	# Add tiles in corner pattern layout
	var added = 0
	for pattern in corner_layout:
		if pattern == "":
			tiles.append(null)  # Empty slot
		else:
			# Parse pattern like "ss/sw"
			var parts = pattern.split("/")
			var top = parts[0]
			var bottom = parts[1]
			
			# Convert to Wang index
			var nw = 1 if top[0] == "s" else 0
			var ne = 1 if top[1] == "s" else 0
			var sw = 1 if bottom[0] == "s" else 0
			var se = 1 if bottom[1] == "s" else 0
			var wang_idx = nw * 8 + ne * 4 + sw * 2 + se
			
			if wang_tiles.has(wang_idx):
				tiles.append(wang_tiles[wang_idx])
				added += 1
			else:
				tiles.append(null)
	
	print("  ✅ Added %d tiles" % added)

func get_terrain_id(name: String) -> int:
	for id in terrains:
		if terrains[id] == name:
			return id
	var id = terrains.size()
	terrains[id] = name
	return id

func create_tileset():
	print("
🔨 Creating tileset...")
	
	# Create atlas image
	var cols = 5
	var rows = (tiles.size() + cols - 1) / cols
	var atlas = Image.create(cols * tile_size, rows * tile_size, false, Image.FORMAT_RGBA8)
	
	# Place tiles in atlas
	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		
		var img = tiles[i].image
		
		var x = (i % cols) * tile_size
		var y = (i / cols) * tile_size
		atlas.blit_rect(img, Rect2i(0, 0, tile_size, tile_size), Vector2i(x, y))
	
	# Save preview
	atlas.save_png(output_path.replace(".tres", "_atlas.png"))
	print("  Preview: %s" % output_path.replace(".tres", "_atlas.png"))
	
	# Generate .tres file
	var tile_defs = []
	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		
		var x = i % cols
		var y = i / cols
		var corners = tiles[i].corners
		
		tile_defs.append("%d:%d/0 = 0" % [x, y])
		tile_defs.append("%d:%d/0/terrain_set = 0" % [x, y])
		tile_defs.append("%d:%d/0/terrains_peering_bit/top_left_corner = %d" % [x, y, corners[0]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/top_right_corner = %d" % [x, y, corners[1]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/bottom_left_corner = %d" % [x, y, corners[2]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/bottom_right_corner = %d" % [x, y, corners[3]])
	
	# Build terrain definitions with colors from base tiles
	var terrain_defs = []
	var terrain_colors = {}
	
	# Find base tiles (all corners same terrain) and extract their colors
	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		var corners = tiles[i].corners
		# Check if all corners are the same (base tile)
		if corners[0] == corners[1] and corners[1] == corners[2] and corners[2] == corners[3]:
			var terrain_id = corners[0]
			if not terrain_colors.has(terrain_id):
				# Extract color from center of this base tile
				var img = tiles[i].image
				var center_x = img.get_width() / 2
				var center_y = img.get_height() / 2
				terrain_colors[terrain_id] = img.get_pixel(center_x, center_y)
	
	for id in terrains:
		var name = terrains[id]
		# Use extracted color or default gray
		var color = terrain_colors.get(id, Color(0.5, 0.5, 0.5))
		
		terrain_defs.append('terrain_set_0/terrain_%d/name = "%s"' % [id, name])
		terrain_defs.append('terrain_set_0/terrain_%d/color = Color(%f, %f, %f, 1)' % [id, color.r, color.g, color.b])
	
	# Convert atlas to bytes
	var bytes = []
	for b in atlas.get_data():
		bytes.append(str(b))
	
	# Write .tres file
	var tres = '[gd_resource type="TileSet" load_steps=4 format=3]

'
	tres += '[sub_resource type="Image" id="Image_1"]
'
	tres += 'data = {
'
	tres += '"data": PackedByteArray(%s),
' % ", ".join(bytes)
	tres += '"format": "RGBA8",
'
	tres += '"height": %d,
' % atlas.get_height()
	tres += '"mipmaps": false,
'
	tres += '"width": %d
' % atlas.get_width()
	tres += '}

'
	tres += '[sub_resource type="ImageTexture" id="ImageTexture_1"]
'
	tres += 'image = SubResource("Image_1")

'
	tres += '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]
'
	tres += 'texture = SubResource("ImageTexture_1")
'
	tres += 'texture_region_size = Vector2i(%d, %d)
' % [tile_size, tile_size]
	tres += "
".join(tile_defs) + '

'
	tres += '[resource]
'
	tres += 'tile_size = Vector2i(%d, %d)
' % [tile_size, tile_size]
	tres += 'terrain_set_0/mode = 0
'  # Corner matching mode
	tres += "
".join(terrain_defs) + '
'
	tres += 'sources/0 = SubResource("TileSetAtlasSource_1")
'
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(tres)
	file.close()
```

## Quick Reference for AI Assistants

### Complete Setup Process

```bash
# 1. Generate tilesets via MCP
create_tileset(lower_description="ocean", upper_description="beach", ...)
create_tileset(lower_description="beach", upper_description="grass", lower_base_tile_id=...)

# 2. Download metadata and images
get_tileset(tileset_id) # Get tileset info and download URLs
# Download: /mcp/tilesets/{id}/metadata -> ocean_beach_metadata.json
# Download: /mcp/tilesets/{id}/image -> ocean_beach_image.png

# 3. Run converter with metadata JSON and PNG files
godot --headless -s pixellab_tileset_converter.gd ocean_beach_metadata.json ocean_beach_image.png beach_grass_metadata.json beach_grass_image.png

# 4. Set up Godot scene
# - Create TileMapLayer node
# - Assign combined_terrain.tres
# - Save as TerrainPainter.tscn
```

### Enabling Visual Painting for the User

Tell the user:
```
"Your terrain painting system is ready! 

To paint your map visually:
1. Open TerrainPainter.tscn in Godot
2. Select the TileMapLayer
3. Click the TileMap editor tab at the bottom
4. Click the Terrains button (connected tiles icon)
5. Select a terrain type (Ocean, Beach, Grass)
6. Use the Rect Tool (R) to draw rectangles

The system automatically handles all tile transitions."
```

### Important Implementation Notes

1. **Rect Tool (R) is Required**: The Paint Tool (D) doesn't work with corner-based terrains (mode 0)
2. **No Configuration Needed**: The converter automatically extracts all information from JSON files
3. **Automatic Color Extraction**: Terrain colors are sampled from base tiles, no manual configuration
4. **Flexible Input**: Supports any number of JSON files as command-line arguments
5. **Visual Editing is the Primary Goal**: The entire system exists to let users paint maps with the Rect Tool in Godot's editor

## Transition (cliff) tilesets (transition_size=1.0)

These sets have **25 tiles** in a **4×8 sheet**. A cliff spans TWO stacked map
cells: the wall tile fills the cell BELOW the upper→lower boundary. Do NOT use
Godot's terrain peering bits for these — select tiles at runtime by matching
each tile's `pattern_4x4` from the metadata (0=lower, 1=upper, 2=transition,
255=wildcard; row_0/row_3 = terrain above/below).

```gdscript
# Runtime autotiler for transition_size=1.0 tilesets.
# terrain: 2D array of vertices, (rows+1) x (cols+1), values 0 (lower) / 1 (upper).
# tiles: parsed "tiles" array from the metadata JSON (pattern_4x4 + corners +
#        bounding_box). The metadata endpoint strips each tile's `image` object,
#        so there is no per-tile URL — slice the sheet with bounding_box.

const CENTER := [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)]

func derive_vertices(terrain: Array) -> Array:
    # A lower vertex directly SOUTH of an upper vertex becomes transition (2):
    # that band renders the cliff wall. Leave a row of lower terrain south of
    # every plateau — the wall consumes it.
    var v := terrain.duplicate(true)
    for r in range(1, v.size()):
        for c in range(v[0].size()):
            if v[r][c] == 0 and v[r - 1][c] == 1:
                v[r][c] = 2
    return v

func vertex_at(v: Array, r: int, c: int) -> int:
    if r >= 0 and r < v.size() and c >= 0 and c < v[0].size():
        return v[r][c]
    return -1  # outside the map

func select_tile(tiles: Array, v: Array, cell_r: int, cell_c: int) -> Dictionary:
    # Best-scoring tile: center 2x2 matches dominate; ring matches break ties.
    # Scoring (not exact matching) matters because the 25-tile vocabulary does
    # not cover every shape (e.g. one-cell cliff staircases).
    var best := {}
    var best_score := -999999
    for tile in tiles:
        var pattern := [
            tile.pattern_4x4.row_0, tile.pattern_4x4.row_1,
            tile.pattern_4x4.row_2, tile.pattern_4x4.row_3,
        ]
        var score := 0
        for i in range(4):
            for j in range(4):
                var want: int = pattern[i][j]
                var have := vertex_at(v, cell_r - 1 + i, cell_c - 1 + j)
                if want == 255 or have == -1:
                    continue
                var is_center := Vector2i(i, j) in CENTER
                if have == want:
                    score += 10 if is_center else 1
                else:
                    score -= 30 if is_center else 1
        if score > best_score:
            best_score = score
            best = tile
    return best

# Placement: transition sheets are NOT array-ordered (tiles repeat, and some are
# absent from the sheet), so index slicing is wrong here — blit each tile from its
# own `bounding_box` rect to (cell_c * tile_w, cell_r * tile_h). Every tile is ONE
# cell high; the cliff look comes from the wall tile in the cell below the edge.
```

Notes:
- Only south-facing plateau edges get walls (north/west/east use normal edges).
- Use one atlas source per tile, taking its rect straight from `bounding_box`
  (valid for the 16-tile sheet AND the 25-tile transition sheet).
- If painting at runtime, re-run selection for cells in a 2-cell radius of the
  change (the wall band shifts with the boundary).

## Summary

### What You've Set Up for the User

After following this guide, the user can:
- **Paint terrains visually** in Godot's editor using the Rect Tool (R)
- **Create game maps** without writing any code
- **See automatic transitions** between different terrain types
- **Layer terrains** by drawing rectangles on top of each other

### The Technical Achievement

You've converted Wang tilesets from an AI generation service into Godot's terrain system with:
- **Automatic terrain name extraction** from JSON descriptions
- **Dynamic tile size detection** from tileset data
- **Smart color sampling** from base tiles for terrain palette
- **Optimized tile arrangement** for corner-based terrain painting
- **Zero configuration** - just pass JSON files as arguments

### Success Indicator

The setup is successful when the user can:
1. Open Godot
2. Select a terrain type from the palette
3. Press R for the Rect Tool
4. Draw rectangles to paint terrain
5. See correct tiles appear with smooth transitions

This transforms complex Wang tilesets into an intuitive visual painting experience.

