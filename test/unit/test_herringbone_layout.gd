extends GutTest


func test_set_corner_colors() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))
  var colors: PackedInt32Array = gen.get_corner_colors()
  assert_eq(colors, PackedInt32Array([2, 2, 2, 2]))


func test_set_invalid_corner_colors_count() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_corner_colors(PackedInt32Array([2, 2]))
  var err: String = gen.get_last_error()
  assert_true(err.length() > 0, "should report error for wrong count")


func test_build_without_definitions() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))
  var ok: bool = gen.build_tileset()
  assert_true(ok, "build should succeed even with no definitions")
  assert_true(gen.is_ready(), "should be ready after build")


func test_load_tile_definitions() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  var defs: Array = []
  defs.append({
    "tile_id": 0,
    "orientation": 0,
    "constraints": PackedInt32Array([0, 0, 0, 0, 0, 0]),
  })
  gen.load_tile_definitions(defs)
  assert_eq(gen.get_last_error(), "", "should have no error")


func test_load_invalid_definitions() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  var defs: Array = []
  defs.append({
    "tile_id": 0,
    "orientation": 0,
    "constraints": PackedInt32Array([0, 0]),
  })
  gen.load_tile_definitions(defs)
  var err: String = gen.get_last_error()
  assert_true(err.length() > 0, "should report error for wrong constraints")


func test_build_tileset_with_definitions() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_corner_colors(PackedInt32Array([2, 2, 2, 2]))
  var defs: Array = _make_full_2222_defs()
  gen.load_tile_definitions(defs)
  var ok: bool = gen.build_tileset()
  assert_true(ok, "build should succeed with full definitions")
  assert_true(gen.is_ready())


func test_generate_before_build_returns_empty() -> void:
  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  var result: Array = gen.generate_abstract_map(10, 10, 42)
  assert_eq(result.size(), 0, "should return empty before build")


func _make_full_2222_defs() -> Array:
  var defs: Array = []
  var tid: int = 0
  # H tiles: corner classes [1,2,3,0,1,2]
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
  # V tiles: corner classes [0,3,2,1,0,3]
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
