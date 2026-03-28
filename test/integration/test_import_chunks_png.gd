extends GutTest

var _result: Dictionary
var _macro_set: HerringboneMacroSet


func before_all() -> void:
  var image: Image = Image.load_from_file(
    ProjectSettings.globalize_path(
      "res://addons/herringbone_wang_generator/assets/chunks.png"
    )
  )
  assert_not_null(image, "chunks.png should load")

  var mapping: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
  mapping.transparency_color = Color(1, 0, 1, 1)
  mapping.entries = [
    {
      "color": Color(0, 0, 0, 1),
      "source_id": 0,
      "atlas_coords": Vector2i(0, 0),
      "alternative_tile": 0,
    },
    {
      "color": Color(1, 1, 1, 1),
      "source_id": 0,
      "atlas_coords": Vector2i(1, 0),
      "alternative_tile": 0,
    },
  ]

  var importer: HerringboneChunkImporter = HerringboneChunkImporter.new()
  _result = importer.import_chunk_map(
    image, 10, Color(1, 0, 1, 1),
    Vector2i(0, 0), 16, 4,
    Vector2i(0, 96), 8, 8,
    mapping,
  )
  _macro_set = _result["macro_set"]


func test_import_succeeds() -> void:
  assert_true(_result["success"], "import should succeed")
  assert_eq(
    _result["errors"].size(), 0,
    "no errors: %s" % str(_result["errors"]),
  )


func test_v_tile_count() -> void:
  # Barrett's chunks.png has 3 V tiles with missing constraint pixels
  assert_eq(_macro_set.v_tiles.size(), 61, "should have 61 V tiles (3 skipped)")


func test_h_tile_count() -> void:
  assert_eq(_macro_set.h_tiles.size(), 64, "should have 64 H tiles")


func test_total_imported() -> void:
  assert_eq(_result["tiles_imported"], 125)
  assert_eq(_result["tiles_skipped"], 3)


func test_edge_mode() -> void:
  assert_false(_macro_set.is_corner)
  assert_eq(_macro_set.num_colors.size(), 6)


func test_num_colors_all_two() -> void:
  for i: int in range(6):
    assert_eq(
      _macro_set.num_colors[i], 2,
      "edge type %d should have 2 colors" % i,
    )


func test_unique_constraint_colors() -> void:
  assert_eq(_result["unique_constraint_colors"], 2)


func test_v_tile_dimensions() -> void:
  for tile: HerringboneMacroData in _macro_set.v_tiles:
    assert_eq(tile.width, 10, "V tile width should be N=10")
    assert_eq(tile.height, 20, "V tile height should be 2N=20")


func test_h_tile_dimensions() -> void:
  for tile: HerringboneMacroData in _macro_set.h_tiles:
    assert_eq(tile.width, 20, "H tile width should be 2N=20")
    assert_eq(tile.height, 10, "H tile height should be N=10")


func test_constraints_in_range() -> void:
  for tile: HerringboneMacroData in _macro_set.h_tiles:
    for i: int in range(6):
      assert_true(
        tile.constraints[i] >= 0 and tile.constraints[i] <= 1,
        "H tile constraint should be 0 or 1",
      )
  for tile: HerringboneMacroData in _macro_set.v_tiles:
    for i: int in range(6):
      assert_true(
        tile.constraints[i] >= 0 and tile.constraints[i] <= 1,
        "V tile constraint should be 0 or 1",
      )


func test_unique_v_constraint_count() -> void:
  # Barrett's image has some duplicate constraint patterns
  var keys: Dictionary = {}
  for tile: HerringboneMacroData in _macro_set.v_tiles:
    keys[tile.get_constraint_key()] = true
  assert_eq(keys.size(), 39, "expected 39 unique V keys from Barrett's image")


func test_unique_h_constraint_count() -> void:
  # Barrett's image has some H tiles with duplicate constraint colors
  var keys: Dictionary = {}
  for tile: HerringboneMacroData in _macro_set.h_tiles:
    keys[tile.get_constraint_key()] = true
  assert_true(keys.size() >= 40, "should have at least 40 unique H keys")


func test_validator_reports_no_errors() -> void:
  var validation: Dictionary = HerringboneValidator.validate(_macro_set)
  assert_true(
    validation["is_valid"],
    "validator errors: %s" % str(validation["errors"]),
  )
  assert_true(validation["completion_pct"] > 50.0)


func test_tiles_have_nonempty_cells() -> void:
  # Spot-check a few tiles for non-empty cell content
  var tile: HerringboneMacroData = _macro_set.h_tiles[0]
  var has_content: bool = false
  for cell: Dictionary in tile.cells:
    if cell["source_id"] != -1:
      has_content = true
      break
  assert_true(has_content, "first H tile should have non-empty cells")
