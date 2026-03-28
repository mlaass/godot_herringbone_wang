extends GutTest

var _gen: RefCounted


func before_each() -> void:
  _gen = ClassDB.instantiate(&"HerringboneGenerator")


func test_default_constraint_mode_is_corner() -> void:
  assert_true(_gen.get_constraint_mode(), "default should be corner mode")


func test_set_constraint_mode_edge() -> void:
  _gen.set_constraint_mode(false)
  assert_false(_gen.get_constraint_mode())


func test_set_constraint_mode_corner() -> void:
  _gen.set_constraint_mode(false)
  _gen.set_constraint_mode(true)
  assert_true(_gen.get_constraint_mode())


func test_set_edge_colors() -> void:
  var colors: PackedInt32Array = PackedInt32Array([2, 2, 2, 2, 2, 2])
  _gen.set_edge_colors(colors)
  var result: PackedInt32Array = _gen.get_edge_colors()
  assert_eq(result.size(), 6)
  for i: int in range(6):
    assert_eq(result[i], 2)


func test_set_edge_colors_wrong_count() -> void:
  _gen.set_edge_colors(PackedInt32Array([2, 2, 2, 2]))
  assert_true(
    _gen.get_last_error().length() > 0,
    "should report error for wrong count",
  )


func test_set_edge_colors_out_of_range() -> void:
  _gen.set_edge_colors(PackedInt32Array([2, 2, 9, 2, 2, 2]))
  assert_true(
    _gen.get_last_error().length() > 0,
    "should report error for out of range",
  )


func test_build_edge_tileset() -> void:
  _gen.set_constraint_mode(false)
  _gen.set_edge_colors(PackedInt32Array([2, 2, 2, 2, 2, 2]))
  var defs: Array = _make_edge_defs()
  _gen.load_tile_definitions(defs)
  var ok: bool = _gen.build_tileset()
  assert_true(ok, "edge-mode build should succeed: %s" % _gen.get_last_error())
  assert_true(_gen.is_ready())


func test_corner_mode_still_works() -> void:
  _gen.set_constraint_mode(true)
  _gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))
  var defs: Array = _make_corner_defs()
  _gen.load_tile_definitions(defs)
  var ok: bool = _gen.build_tileset()
  assert_true(ok, "corner-mode build should succeed: %s" % _gen.get_last_error())
  assert_true(_gen.is_ready())


func test_generate_before_build_returns_empty() -> void:
  _gen.set_constraint_mode(false)
  var result: Array = _gen.generate_abstract_map(10, 10, 42)
  assert_eq(result.size(), 0)


func _make_edge_defs() -> Array:
  # Generate all 128 edge-mode tile definitions with [2,2,2,2,2,2]
  # PRD canonical ordering — permuted to stb order by load_tile_definitions
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


func _make_corner_defs() -> Array:
  # Full 2222 corner-mode definitions (replicates existing test helper)
  var defs: Array = []
  var h_class: Array[int] = [1, 2, 3, 0, 1, 2]
  var v_class: Array[int] = [0, 3, 2, 1, 0, 3]
  var nc: PackedInt32Array = PackedInt32Array([2, 2, 2, 2])
  var tid: int = 0
  for orient: int in range(2):
    var cmap: Array[int] = h_class if orient == 0 else v_class
    var combos: Array = _enumerate(cmap, nc)
    for combo: PackedInt32Array in combos:
      defs.append({
        "tile_id": tid % 255,
        "orientation": orient,
        "constraints": combo,
      })
      tid += 1
  return defs


func _enumerate(
  class_map: Array[int],
  nc: PackedInt32Array,
) -> Array:
  var result: Array = []
  _enum_rec(class_map, nc, 0, PackedInt32Array(), result)
  return result


func _enum_rec(
  class_map: Array[int],
  nc: PackedInt32Array,
  depth: int,
  current: PackedInt32Array,
  result: Array,
) -> void:
  if depth == 6:
    result.append(current.duplicate())
    return
  var cls: int = class_map[depth]
  for c: int in range(nc[cls]):
    var next: PackedInt32Array = current.duplicate()
    next.append(c)
    _enum_rec(class_map, nc, depth + 1, next, result)
