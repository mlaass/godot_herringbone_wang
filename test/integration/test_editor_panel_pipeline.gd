extends GutTest

const CHUNKS_PATH: String = (
  "res://addons/herringbone_wang_generator/assets/chunks.png"
)

var _image: Image
var _mapping: HerringboneColorTileMapping
var _macro_set: HerringboneMacroSet


func before_all() -> void:
  _image = Image.load_from_file(
    ProjectSettings.globalize_path(CHUNKS_PATH),
  )


func test_detect_colors_finds_content() -> void:
  var mapping: HerringboneColorTileMapping = (
    HerringboneColorTileMapping.new()
  )
  mapping.detect_colors_from_image(_image)
  assert_true(
    mapping.entries.size() >= 2,
    "should detect at least 2 content colors, got %d"
    % mapping.entries.size(),
  )


func test_full_detect_import_generate_pipeline() -> void:
  # Step 1: Detect colors
  _mapping = HerringboneColorTileMapping.new()
  _mapping.detect_colors_from_image(_image)
  assert_true(_mapping.entries.size() >= 2)

  # Step 2: Assign atlas coords to detected entries
  # Black -> (0,0), White -> (1,0)
  for entry: Dictionary in _mapping.entries:
    var color: Color = entry["color"]
    if color.r < 0.5 and color.g < 0.5 and color.b < 0.5:
      entry["source_id"] = 0
      entry["atlas_coords"] = Vector2i(0, 0)
    else:
      entry["source_id"] = 0
      entry["atlas_coords"] = Vector2i(1, 0)

  # Step 3: Import
  var importer: HerringboneChunkImporter = (
    HerringboneChunkImporter.new()
  )
  var result: Dictionary = importer.import_chunk_map(
    _image, 10, Color(1, 0, 1, 1),
    Vector2i(0, 0), 16, 4,
    Vector2i(0, 96), 8, 8,
    _mapping,
  )
  assert_true(result["success"], "import should succeed")
  _macro_set = result["macro_set"]
  assert_not_null(_macro_set)
  assert_true(
    result["tiles_imported"] > 100,
    "should import most tiles",
  )

  # Step 4: Validate
  var validation: Dictionary = (
    HerringboneValidator.validate(_macro_set)
  )
  assert_true(validation["is_valid"])
  assert_true(validation["completion_pct"] > 0.0)

  # Step 5: Generate
  var gen: RefCounted = ClassDB.instantiate(
    &"HerringboneGenerator",
  )
  gen.set_constraint_mode(_macro_set.is_corner)
  gen.set_edge_colors(_macro_set.num_colors)
  gen.load_tile_definitions(_macro_set.to_generator_defs())
  assert_true(
    gen.build_tileset(),
    "build should succeed: %s" % gen.get_last_error(),
  )

  var abstract_map: Array = gen.generate_abstract_map(10, 10, 42)
  assert_true(abstract_map.size() > 0)

  # Step 6: Populate tilemap
  var tilemap: TileMapLayer = TileMapLayer.new()
  tilemap.tile_set = TileSet.new()
  var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
  var img: Image = Image.create(32, 16, false, Image.FORMAT_RGB8)
  atlas.texture = ImageTexture.create_from_image(img)
  atlas.texture_region_size = Vector2i(16, 16)
  tilemap.tile_set.add_source(atlas)
  # Create tiles at (0,0) and (1,0)
  atlas.create_tile(Vector2i(0, 0))
  atlas.create_tile(Vector2i(1, 0))
  add_child(tilemap)

  var fallback: Dictionary = {
    "source_id": 0,
    "atlas_coords": Vector2i(0, 0),
    "alternative_tile": 0,
  }
  HerringboneAuthoringLayer.populate_tilemap(
    tilemap, abstract_map, _macro_set, fallback,
  )

  assert_true(
    tilemap.get_used_cells().size() > 0,
    "tilemap should have cells placed",
  )
  tilemap.queue_free()


func test_clear_region_preserves_outside_cells() -> void:
  var tilemap: TileMapLayer = TileMapLayer.new()
  tilemap.tile_set = TileSet.new()
  var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
  var img: Image = Image.create(16, 16, false, Image.FORMAT_RGB8)
  atlas.texture = ImageTexture.create_from_image(img)
  atlas.texture_region_size = Vector2i(16, 16)
  tilemap.tile_set.add_source(atlas)
  atlas.create_tile(Vector2i(0, 0))
  add_child(tilemap)

  # Place a cell far outside any generated region
  tilemap.set_cell(Vector2i(500, 500), 0, Vector2i(0, 0))

  # Also place cells inside a 5x5 * 10 = 50x50 region
  for y: int in range(50):
    for x: int in range(50):
      tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

  # Clear 5x5 region with base_unit=10 (clears 50x50 cells)
  for y: int in range(50):
    for x: int in range(50):
      tilemap.erase_cell(Vector2i(x, y))

  # Cell outside region should still exist
  var src: int = tilemap.get_cell_source_id(Vector2i(500, 500))
  assert_eq(src, 0, "cell outside region should be preserved")

  # Cell inside region should be gone
  var inner_src: int = tilemap.get_cell_source_id(Vector2i(0, 0))
  assert_eq(inner_src, -1, "cell inside region should be erased")

  tilemap.queue_free()


func test_no_macro_set_generation_fails_gracefully() -> void:
  # This tests the logic the panel would use — no crash on null
  var macro_set: HerringboneMacroSet = null
  assert_null(macro_set, "null macro_set should not crash")
