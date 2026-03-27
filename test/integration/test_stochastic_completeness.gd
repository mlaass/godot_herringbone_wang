extends GutTest


func test_validate_null_macro_set() -> void:
  var result: Dictionary = HerringboneValidator.validate(null)
  assert_false(result["is_valid"])
  var errors: PackedStringArray = result["errors"]
  assert_true(errors.size() > 0)


func test_validate_empty_set_has_warnings() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])
  var result: Dictionary = HerringboneValidator.validate(ms)
  assert_true(result["is_valid"], "empty but valid structure")
  var warnings: PackedStringArray = result["warnings"]
  assert_true(warnings.size() > 0, "should warn about missing tiles")
  var pct: float = result["completion_pct"]
  assert_eq(pct, 0.0, "0% complete when empty")


func test_validate_detects_missing_combos() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])
  var result: Dictionary = HerringboneValidator.validate(ms)
  var missing_h: Array = result["missing_h"]
  var missing_v: Array = result["missing_v"]
  assert_eq(missing_h.size(), 64, "should detect 64 missing H tiles")
  assert_eq(missing_v.size(), 64, "should detect 64 missing V tiles")


func test_validate_complete_set() -> void:
  var ms: HerringboneMacroSet = _create_complete_2222()
  var result: Dictionary = HerringboneValidator.validate(ms)
  assert_true(result["is_valid"])
  var missing_h: Array = result["missing_h"]
  var missing_v: Array = result["missing_v"]
  assert_eq(missing_h.size(), 0, "no missing H tiles")
  assert_eq(missing_v.size(), 0, "no missing V tiles")
  var pct: float = result["completion_pct"]
  assert_almost_eq(pct, 100.0, 0.01)


func test_validate_detects_invalid_tiles() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])
  var bad_tile: HerringboneMacroData = HerringboneMacroData.new()
  bad_tile.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  bad_tile.constraints = PackedInt32Array([0, 0])
  ms.h_tiles.append(bad_tile)
  var result: Dictionary = HerringboneValidator.validate(ms)
  assert_false(result["is_valid"])


func test_statistical_coverage() -> void:
  var ms: HerringboneMacroSet = _create_complete_2222()
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))

  var defs: Array = _macro_set_to_defs(ms)
  gen.load_tile_definitions(defs)
  gen.build_tileset()

  var seen_ids: Dictionary = {}
  for run: int in range(50):
    var result: Array = gen.generate_abstract_map(30, 30, run + 1)
    for i: int in range(result.size()):
      var entry: Dictionary = result[i]
      seen_ids[entry["tile_id"]] = true

  var unique_count: int = seen_ids.size()
  var total_defs: int = ms.h_tiles.size() + ms.v_tiles.size()
  assert_true(
    unique_count > total_defs / 2,
    "should see >50%% of tile types across 50 runs, saw %d/%d"
    % [unique_count, total_defs]
  )


func _create_complete_2222() -> HerringboneMacroSet:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.base_unit_size = 4
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])

  var tid: int = 0
  for a: int in range(2):
    for b: int in range(2):
      for c: int in range(2):
        for d: int in range(2):
          for e: int in range(2):
            for f: int in range(2):
              var data: HerringboneMacroData = HerringboneMacroData.new()
              data.orientation = HerringboneMacroData.Orientation.HORIZONTAL
              data.tile_id = tid % 255
              data.constraints = PackedInt32Array([a, b, c, d, e, f])
              data.init_cells(8, 4)
              ms.h_tiles.append(data)
              tid += 1

  for a: int in range(2):
    for b: int in range(2):
      for c: int in range(2):
        for d: int in range(2):
          for e: int in range(2):
            for f: int in range(2):
              var data: HerringboneMacroData = HerringboneMacroData.new()
              data.orientation = HerringboneMacroData.Orientation.VERTICAL
              data.tile_id = tid % 255
              data.constraints = PackedInt32Array([a, b, c, d, e, f])
              data.init_cells(4, 8)
              ms.v_tiles.append(data)
              tid += 1

  return ms


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
