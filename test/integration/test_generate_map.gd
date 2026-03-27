extends GutTest

var _gen: RefCounted


func before_each() -> void:
  _gen = ClassDB.instantiate(&"HerringboneGenerator")
  _gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))
  var defs: Array = _make_full_2222_defs()
  _gen.load_tile_definitions(defs)
  var ok: bool = _gen.build_tileset()
  assert_true(ok, "build should succeed in setup")


func test_generate_returns_nonempty() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  assert_true(result.size() > 0, "should return tile placements")


func test_deterministic_seed() -> void:
  var result1: Array = _gen.generate_abstract_map(20, 20, 42)
  var result2: Array = _gen.generate_abstract_map(20, 20, 42)
  assert_eq(result1.size(), result2.size(), "same seed = same count")
  for i: int in range(result1.size()):
    var e1: Dictionary = result1[i]
    var e2: Dictionary = result2[i]
    assert_eq(e1["tile_id"], e2["tile_id"], "same seed = same tile_id")
    assert_eq(e1["orientation"], e2["orientation"])
    assert_eq(e1["grid_x"], e2["grid_x"])
    assert_eq(e1["grid_y"], e2["grid_y"])


func test_different_seed_different_result() -> void:
  var result1: Array = _gen.generate_abstract_map(20, 20, 42)
  var result2: Array = _gen.generate_abstract_map(20, 20, 99)
  var same_count: int = 0
  var min_len: int = mini(result1.size(), result2.size())
  for i: int in range(min_len):
    var e1: Dictionary = result1[i]
    var e2: Dictionary = result2[i]
    if e1["tile_id"] == e2["tile_id"]:
      same_count += 1
  assert_true(
    same_count < min_len,
    "different seeds should produce different results"
  )


func test_result_structure() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  assert_true(result.size() > 0)
  var entry: Dictionary = result[0]
  assert_true(entry.has("tile_id"), "entry should have tile_id")
  assert_true(entry.has("orientation"), "entry should have orientation")
  assert_true(entry.has("grid_x"), "entry should have grid_x")
  assert_true(entry.has("grid_y"), "entry should have grid_y")


func test_tile_id_range() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  for i: int in range(result.size()):
    var entry: Dictionary = result[i]
    var tid: int = entry["tile_id"]
    assert_true(
      tid >= 0 and tid <= 255,
      "tile_id should be 0-255, got %d" % tid
    )


func test_orientation_values() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  var has_h: bool = false
  var has_v: bool = false
  for i: int in range(result.size()):
    var entry: Dictionary = result[i]
    var orient: int = entry["orientation"]
    assert_true(
      orient == 0 or orient == 1,
      "orientation should be 0 (H) or 1 (V)"
    )
    if orient == 0:
      has_h = true
    else:
      has_v = true
  assert_true(has_h, "should have horizontal tiles")
  assert_true(has_v, "should have vertical tiles")


func _make_full_2222_defs() -> Array:
  var defs: Array = []
  var tid: int = 0
  for a: int in range(2):
    for b: int in range(2):
      for c: int in range(2):
        for d: int in range(2):
          for e: int in range(2):
            for f: int in range(2):
              defs.append({
                "tile_id": tid % 255,
                "orientation": 0,
                "constraints": PackedInt32Array([a, b, c, d, e, f]),
              })
              tid += 1
  for a: int in range(2):
    for b: int in range(2):
      for c: int in range(2):
        for d: int in range(2):
          for e: int in range(2):
            for f: int in range(2):
              defs.append({
                "tile_id": tid % 255,
                "orientation": 1,
                "constraints": PackedInt32Array([a, b, c, d, e, f]),
              })
              tid += 1
  return defs
