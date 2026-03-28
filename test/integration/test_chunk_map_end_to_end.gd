extends GutTest

var _macro_set: HerringboneMacroSet
var _gen: RefCounted
var _import_ok: bool = false


func before_all() -> void:
  # Step 1: Import chunks.png
  var image: Image = Image.load_from_file(
    ProjectSettings.globalize_path(
      "res://addons/herringbone_wang_generator/assets/chunks.png"
    )
  )
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
  var result: Dictionary = importer.import_chunk_map(
    image, 10, Color(1, 0, 1, 1),
    Vector2i(0, 0), 16, 4,
    Vector2i(0, 96), 8, 8,
    mapping,
  )
  _macro_set = result["macro_set"]
  if _macro_set == null:
    return

  # Step 2: Set up C++ generator
  _gen = ClassDB.instantiate(&"HerringboneGenerator")
  _gen.set_constraint_mode(false)
  _gen.set_edge_colors(_macro_set.num_colors)
  var defs: Array = _macro_set_to_defs(_macro_set)
  _gen.load_tile_definitions(defs)
  _import_ok = _gen.build_tileset()


func test_import_produced_macro_set() -> void:
  assert_not_null(_macro_set)
  assert_true(
    _macro_set.h_tiles.size() + _macro_set.v_tiles.size() > 100,
    "should have imported most tiles",
  )


func test_generator_builds() -> void:
  assert_true(_import_ok, "generator should build: %s" % _gen.get_last_error())
  assert_true(_gen.is_ready())


func test_generate_map_returns_placements() -> void:
  if not _import_ok:
    pass_test("skipped — generator not ready")
    return
  var result: Array = _gen.generate_abstract_map(30, 30, 42)
  assert_true(result.size() > 0, "should produce tile placements")


func test_most_tile_ids_known() -> void:
  if not _import_ok:
    pass_test("skipped — generator not ready")
    return
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  var unknown: int = 0
  for entry: Dictionary in result:
    var tid: int = entry["tile_id"]
    if tid == 255:
      unknown += 1
  # Some unknowns expected since Barrett's set has missing combos
  assert_true(
    unknown < result.size() / 2,
    "most tiles should be known (unknown: %d/%d)" % [unknown, result.size()],
  )


func test_deterministic_pipeline() -> void:
  if not _import_ok:
    pass_test("skipped — generator not ready")
    return
  var a: Array = _gen.generate_abstract_map(15, 15, 999)
  var b: Array = _gen.generate_abstract_map(15, 15, 999)
  assert_eq(a.size(), b.size())
  for i: int in range(a.size()):
    assert_eq(a[i]["tile_id"], b[i]["tile_id"])


func test_both_orientations_in_output() -> void:
  if not _import_ok:
    pass_test("skipped — generator not ready")
    return
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  var has_h: bool = false
  var has_v: bool = false
  for entry: Dictionary in result:
    if entry["orientation"] == 0:
      has_h = true
    elif entry["orientation"] == 1:
      has_v = true
  assert_true(has_h and has_v, "should have both H and V tiles")


func test_tile_ids_match_macro_set() -> void:
  if not _import_ok:
    pass_test("skipped — generator not ready")
    return
  var valid_ids: Dictionary = {}
  for tile: HerringboneMacroData in _macro_set.h_tiles:
    valid_ids[tile.tile_id] = true
  for tile: HerringboneMacroData in _macro_set.v_tiles:
    valid_ids[tile.tile_id] = true

  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  var unknown_count: int = 0
  for entry: Dictionary in result:
    var tid: int = entry["tile_id"]
    if tid == 255 or not valid_ids.has(tid):
      unknown_count += 1
  # Allow some unknown tiles since the set isn't fully complete
  assert_true(
    unknown_count < result.size() / 2,
    "most tile IDs should match macro set definitions",
  )


func _macro_set_to_defs(ms: HerringboneMacroSet) -> Array:
  var defs: Array = []
  for tile: HerringboneMacroData in ms.h_tiles:
    defs.append({
      "tile_id": tile.tile_id,
      "orientation": 0,
      "constraints": tile.constraints,
    })
  for tile: HerringboneMacroData in ms.v_tiles:
    defs.append({
      "tile_id": tile.tile_id,
      "orientation": 1,
      "constraints": tile.constraints,
    })
  return defs
