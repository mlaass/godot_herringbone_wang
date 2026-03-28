# Herringbone Wang Tile Generator

A Godot 4.6 addon that generates seamless herringbone Wang tile maps using Sean Barrett's [stb_herringbone_wang_tile](https://nothings.org/gamedev/herringbone/) algorithm.

The generator places rectangular tiles in a herringbone pattern with constraint-based matching at shared edges, producing infinite non-repeating tilemaps suitable for dungeons, terrain, and other procedural content.

## Features

- **Corner-mode constraints** — 4 corner classes with configurable color counts (e.g. hbw-2222: 128 tiles)
- **Edge-mode constraints** — 6 independent edge types (e.g. hbe-222222: 128 tiles, Barrett's dungeon format)
- **Chunk map importer** — import pixel-art chunk maps (like Barrett's `chunks.png`) directly into the pipeline
- **C++ generation** — native GDExtension wrapping stb for fast map generation
- **Deterministic seeding** — reproducible output for any given seed
- **Editor integration** — `HerringboneAuthoringLayer` for visual tile authoring with constraint preview

## Quick Start

### Running the example

Open the project in Godot 4.6+ and run. The example scene (`example/demo_2d.tscn`) imports Barrett's `chunks.png` and generates a herringbone dungeon tilemap.

The example script (`example/dungeon_example.gd`) demonstrates the full pipeline. Adjust `map_width`, `map_height`, and `seed_value` in the inspector and toggle `regenerate` to produce new maps in the editor.

### Importing a chunk map

```gdscript
# 1. Load the chunk map image
var image: Image = Image.load_from_file(
  ProjectSettings.globalize_path("res://path/to/chunks.png")
)

# 2. Define how pixel colors map to TileSet atlas coordinates
var mapping: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
mapping.transparency_color = Color(1, 0, 1, 1)  # pink = empty
mapping.entries = [
  {"color": Color(0, 0, 0, 1), "source_id": 0,
    "atlas_coords": Vector2i(0, 0), "alternative_tile": 0},  # black = wall
  {"color": Color(1, 1, 1, 1), "source_id": 0,
    "atlas_coords": Vector2i(1, 0), "alternative_tile": 0},  # white = floor
]

# 3. Import the chunk map
var importer: HerringboneChunkImporter = HerringboneChunkImporter.new()
var result: Dictionary = importer.import_chunk_map(
  image,
  10,                      # N — short side length in pixels
  Color(1, 0, 1, 1),      # transparency color (pink)
  Vector2i(0, 0), 16, 4,  # V section: origin, columns, rows
  Vector2i(0, 96), 8, 8,  # H section: origin, columns, rows
  mapping,
)

var macro_set: HerringboneMacroSet = result["macro_set"]
```

### Generating a map

```gdscript
# 4. Set up the C++ generator
var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
gen.set_constraint_mode(false)  # edge mode
gen.set_edge_colors(macro_set.num_colors)

# Convert macro set to definitions array
var defs: Array = []
for tile in macro_set.h_tiles:
  defs.append({"tile_id": tile.tile_id, "orientation": 0,
    "constraints": tile.constraints})
for tile in macro_set.v_tiles:
  defs.append({"tile_id": tile.tile_id, "orientation": 1,
    "constraints": tile.constraints})

gen.load_tile_definitions(defs)
gen.build_tileset()

# 5. Generate tile placements
var abstract_map: Array = gen.generate_abstract_map(40, 40, 42)

# 6. Populate a TileMapLayer
HerringboneAuthoringLayer.populate_tilemap(tilemap, abstract_map, macro_set)
```

### Corner-mode authoring (manual tile creation)

```gdscript
# Create a constraint catalog
var catalog: HerringboneConstraintCatalog = (
  HerringboneConstraintCatalog.create_hbw_2222()
)

# Create an empty macro set
var macro_set: HerringboneMacroSet = catalog.create_empty_macro_set(4)

# Use HerringboneAuthoringLayer in the editor to paint tiles visually,
# then bake_macro_set() to extract the completed set
```

## Chunk Map Format

Chunk maps are pixel-art images where each tile slot contains:
- A **border area** with exactly 6 constraint pixels (non-pink colored dots at edge midpoints)
- An **interior** with pixel colors representing game-world cells

Tile slot dimensions:
- **V tiles**: `(N+2)` wide x `(2N+4)` tall (1px border on short sides, 2px on long sides)
- **H tiles**: `(2N+4)` wide x `(N+2)` tall

Barrett's `chunks.png` (included in `assets/`) uses N=10 with yellow and green constraint colors, black for walls, and white for floors.

## Building the GDExtension

Requires [godot-cpp](https://github.com/godotengine/godot-cpp) built at `~/workspace/godot-cpp` and SCons.

```bash
cd addons/herringbone_wang_generator/native_src
scons platform=linux target=release
```

## Running Tests

```bash
# All tests
godot46 -s addons/gut/gut_cmdln.gd --headless

# Specific test file
godot46 -s addons/gut/gut_cmdln.gd --headless -gtest=res://test/unit/test_macro_set.gd
```

## Project Structure

```
addons/herringbone_wang_generator/
  herringbone_macro_data.gd          # Single tile: constraints + cell grid
  herringbone_macro_set.gd           # Tile collection with completeness checks
  herringbone_constraint_catalog.gd  # Schema definitions (corner + edge mode)
  herringbone_validator.gd           # Validation and completeness reporting
  herringbone_authoring_layer.gd     # Editor tool for visual authoring
  herringbone_color_tile_mapping.gd  # Pixel color → TileSet coordinate mapping
  herringbone_chunk_importer.gd      # Chunk map image parser
  herringbone_plugin.gd              # Editor plugin registration
  assets/chunks.png                  # Barrett's 128-tile dungeon chunk map
  native_src/                        # C++ GDExtension source
    src/herringbone_generator.h/cpp  # stb wrapper with pixel proxy encoding
    thirdparty/stb_herringbone_wang_tile.h
example/
  demo_2d.tscn                       # Example dungeon scene
  dungeon_example.gd                 # Full pipeline script
test/
  unit/                              # Unit tests
  integration/                       # Integration + end-to-end tests
  smoke/                             # Addon load tests
```

## References

- [Sean Barrett — Herringbone Wang Tiles (2011)](https://nothings.org/gamedev/herringbone/herringbone_tiles.html)
- [stb_herringbone_wang_tile.h](https://github.com/nothings/stb/blob/master/stb_herringbone_wang_tile.h)

## License

MIT
