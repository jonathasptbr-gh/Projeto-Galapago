<!-- pixellab://docs/unity/isometric-tilemaps-2d — copiado por tools/pixellab-catalogo.mjs; não editar -->

# Unity 2D Isometric Tilemap Implementation Guide

Technical implementation notes for Unity 6.x URP 2D isometric tilemaps with elevation support using 2D sprites and tilemaps.

## Implementation: Individual Mode + Custom Transparency Sort
```csharp
renderer.mode = TilemapRenderer.Mode.Individual;
// Each 2D tile sprite becomes independent draw call - enables spatial sorting
// Trade-off: O(n) draw calls vs O(materials) draw calls
```

**URP 2D Renderer Configuration** (critical):
```yaml
# Assets/Settings/Renderer2D.asset (URP 2D Renderer Data)
m_TransparencySortMode: 3  # CustomAxis  
m_TransparencySortAxis: {x: 0, y: 1, z: -0.26}
```

**Z-axis coefficient selection** (based on desired height difference per level):
- `-0.26`: For gradual elevation changes - like thick tile height per level, smooth transitions
- `-1.0`: For dramatic elevation changes - like full block height per level, strong separation

## Height System Architecture

### Combined Data Format
```csharp
// Optimal: Terrain type + elevation in single structure
string[] mapData = { "G2W0B1P0..." }; // char+int pairs
char terrain = mapData[row][x*2];
int elevation = int.Parse(mapData[row][x*2+1]);
```

**Benefits**: 
- Single source of truth
- Visual debugging capability
- Eliminates synchronization issues between separate arrays

### Tile Placement Algorithm
```csharp
// Multi-pass approach for elevation stacking
for (int level = 0; level <= maxHeight; level++) {
    PlaceElevatedTiles(tilemap, tiles, level);
}

// Water tiles special case - always Z=0 regardless of data
if (tileChar == 'W') {
    position = new Vector3Int(x, y, 0);  // Force ground level
}
```

## Grid Configuration

### IsometricZAsY Layout
```csharp
grid.cellLayout = Grid.CellLayout.IsometricZAsY;
grid.cellSize = new Vector3(1f, 0.5f, 1f);  // Unity standard
```

**Z-to-visual-height mapping**: Unity automatically transforms Z position to visual elevation using isometric projection matrix.

### Coordinate System Transform
```csharp
// Unity tilemap Y-axis inversion for isometric ordering
int unityY = mapHeight - 1 - dataY;
Vector3Int position = new Vector3Int(x, unityY, elevation);
```

## Performance Considerations

### Memory Layout
```csharp
// Efficient tile lookup
Dictionary<char, TileBase> tileCache = LoadTileAssets();
// Pre-computed height sets for sparse elevation data
HashSet<int> activeHeights = ExtractUsedHeights(mapData);
```

## Asset Pipeline Requirements

### 2D Sprite Import Configuration
```csharp
// Required settings for 2D isometric tile sprites
textureImporter.spritePixelsPerUnit = 100f;
textureImporter.filterMode = FilterMode.Point;  // Pixel-perfect 2D sprites
textureImporter.textureCompression = TextureImporterCompression.Uncompressed;
textureImporter.textureType = TextureImporterType.Sprite;  // 2D sprite type
```

**Critical**: Block-shaped 2D sprites required for elevation stacking. Thin/flat 2D sprites will not produce visible height differentiation in isometric view.

## URP 2D Integration Points

### 2D Transparency Sort Implementation
URP 2D Renderer uses custom sort axis for 2D sprite depth calculation:
```
sortKey = dot(position, transparencySortAxis)
```

**Axis coefficient tuning**:
- X=0: No horizontal bias
- Y=1: Back-to-front isometric ordering  
- Z=coefficient: Elevation priority weight

### URP 2D Renderer Asset Modification
```csharp
// Direct URP 2D Renderer asset editing (only reliable approach)
// SerializedObject manipulation fails due to internal property names
string assetPath = "Assets/Settings/Renderer2D.asset";  // URP 2D Renderer Data
string content = File.ReadAllText(assetPath);
content = content.Replace("z: -1", "z: -0.26");
File.WriteAllText(assetPath, content);
AssetDatabase.Refresh();
```

## Map Design Constraints

### Elevation Topology Rules
1. **Gradient constraint**: Max elevation delta = 1 per adjacent tile
2. **Water constraint**: All water tiles fixed at Z=0
3. **Bridge constraint**: Elevation ≥ max(adjacent_water_level + 1)
4. **Connectivity constraint**: Path tiles must form connected components

### Data Structure Invariants
```csharp
// Validation rules for map data
Debug.Assert(heightLevel >= 0 && heightLevel <= 4);
Debug.Assert(waterTiles.All(tile => tile.height == 0));
Debug.Assert(bridgeTiles.All(tile => tile.height > adjacentWaterHeight));
```

## Testing and Validation

### Automated Verification
```csharp
[Test]
public void ValidateElevationStacking() {
    var result = BuildTestMap("G0G1G2G3");
    Assert.True(result.GetTile(new Vector3Int(3,0,3)) != null);
    Assert.True(result.GetTile(new Vector3Int(3,0,0)) != null);
}

[Test] 
public void ValidateTransparencySortAxis() {
    var axis = GetTransparencySortAxis();
    Assert.AreEqual(new Vector3(0, 1, -0.26f), axis);
}
```

### Performance Profiling
Monitor via Unity Profiler:
- Draw calls per frame (Individual mode impact)
- Tilemap.SetTile() batch performance  
- Memory allocation in tile loading

## Common Implementation Failures

### Anti-patterns
```csharp
// DON'T: Custom tile render order (ignored by Unity)
public class CustomTile : TileBase {
    public override void GetTileData(..., ref TileData tileData) {
        tileData.transform = Matrix4x4.identity;  // No effect on sorting
    }
}

// DON'T: Programmatic sprite atlas creation
var atlas = ScriptableObject.CreateInstance<SpriteAtlas>();  // Fails at runtime

// DON'T: Multiple tilemaps for Z-layering  
CreateTilemap("Background");   // Fixed Z-order, no interleaving
CreateTilemap("Foreground");
```

### Debug Strategies
1. Frame Debugger: Verify draw call ordering
2. Scene view wireframe: Confirm Z positions
3. Transparency sort axis visualization via debug gizmos
4. Tile placement validation via automated tests

## Integration with External Tools

### MCP Server Compatibility
- Pixellab integration for block-shaped 2D tile sprite generation
- Programmatic 2D tile placement via editor scripts
- 2D sprite asset import automation via AssetPostprocessor

### Build Pipeline Considerations
- URP 2D Renderer asset validation in CI/CD
- Platform-specific 2D transparency sort performance characteristics
- 2D texture compression settings for target platforms

## PixelLab Integration

### Generating Block-Shaped Tiles
Use PixelLab's isometric tile generation for Unity-compatible assets:

```python
# Via MCP tools
create_isometric_tile(
    description="grass block on dirt",
    size=32,
    tile_shape="block",  # Critical for elevation stacking
    outline="lineless"
)
```

**Key requirements**:
- Use `tile_shape="block"` for proper elevation stacking
- Size 32x32 or higher for clear height differentiation
- PNG with transparency for proper alpha blending

### Automated Tile Import
```csharp
// Unity AssetPostprocessor for PixelLab tiles
public class PixelLabTileProcessor : AssetPostprocessor {
    void OnPreprocessTexture() {
        if (assetPath.Contains("pixellab")) {
            var importer = (TextureImporter)assetImporter;
            importer.spritePixelsPerUnit = 100f;
            importer.filterMode = FilterMode.Point;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
        }
    }
}
```

### Tileset Integration Workflow
1. Generate connected tilesets via PixelLab MCP
2. Import sprites with proper settings
3. Create Unity Tiles from sprites
4. Configure tilemap with Individual mode
5. Set URP transparency sort axis
6. Implement elevation-aware placement logic

This guide provides the complete technical foundation for implementing robust isometric tilemaps in Unity with PixelLab-generated assets.
