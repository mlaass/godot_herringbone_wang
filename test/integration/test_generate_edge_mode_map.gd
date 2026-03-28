extends GutTest

var _gen: RefCounted


func before_each() -> void:
  _gen = ClassDB.instantiate(&"HerringboneGenerator")
  _gen.set_constraint_mode(false)
  _gen.set_edge_colors(PackedInt32Array([2, 2, 2, 2, 2, 2]))
  var defs: Array = _make_edge_defs()
  _gen.load_tile_definitions(defs)
  var ok: bool = _gen.build_tileset()
  assert_true(ok, "setup: build should succeed: %s" % _gen.get_last_error())


func test_generate_returns_nonempty() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  assert_true(result.size() > 0, "should produce tile placements")


func test_deterministic_seed() -> void:
  var a: Array = _gen.generate_abstract_map(15, 15, 123)
  var b: Array = _gen.generate_abstract_map(15, 15, 123)
  assert_eq(a.size(), b.size(), "same seed should produce same count")
  for i: int in range(a.size()):
    var da: Dictionary = a[i]
    var db: Dictionary = b[i]
    assert_eq(da["tile_id"], db["tile_id"])
    assert_eq(da["orientation"], db["orientation"])
    assert_eq(da["grid_x"], db["grid_x"])
    assert_eq(da["grid_y"], db["grid_y"])


func test_different_seed() -> void:
  var a: Array = _gen.generate_abstract_map(15, 15, 100)
  var b: Array = _gen.generate_abstract_map(15, 15, 200)
  # Could theoretically be the same, but astronomically unlikely
  var any_diff: bool = false
  for i: int in range(mini(a.size(), b.size())):
    if a[i]["tile_id"] != b[i]["tile_id"]:
      any_diff = true
      break
  assert_true(any_diff, "different seeds should produce different output")


func test_result_structure() -> void:
  var result: Array = _gen.generate_abstract_map(10, 10, 42)
  assert_true(result.size() > 0)
  var entry: Dictionary = result[0]
  assert_has(entry, "tile_id")
  assert_has(entry, "orientation")
  assert_has(entry, "grid_x")
  assert_has(entry, "grid_y")


func test_tile_id_range() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  for entry: Dictionary in result:
    var tid: int = entry["tile_id"]
    assert_true(
      tid >= 0 and tid <= 254,
      "tile_id %d out of range" % tid,
    )


func test_both_orientations_present() -> void:
  var result: Array = _gen.generate_abstract_map(20, 20, 42)
  var has_h: bool = false
  var has_v: bool = false
  for entry: Dictionary in result:
    if entry["orientation"] == 0:
      has_h = true
    elif entry["orientation"] == 1:
      has_v = true
  assert_true(has_h, "should have horizontal tiles")
  assert_true(has_v, "should have vertical tiles")


func _make_edge_defs() -> Array:
  var defs: Array = []
  var tid: int = 0
  for orient: int in range(2):
    for a: int in range(2):
      for b: int in range(2):
        for c: int in range(2):
          for d: int in range(2):
            for e: int in range(2):
              for f: int in range(2):
                defs.append({
                  "tile_id": tid % 255,
                  "orientation": orient,
                  "constraints": PackedInt32Array([a, b, c, d, e, f]),
                })
                tid += 1
  return defs
