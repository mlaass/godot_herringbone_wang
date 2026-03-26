extends GutTest


func test_default_construction() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  assert_eq(
    data.orientation, HerringboneMacroData.Orientation.HORIZONTAL,
    "default orientation should be HORIZONTAL"
  )
  assert_eq(data.tile_id, 0, "default tile_id should be 0")
  assert_eq(data.width, 0, "default width should be 0")
  assert_eq(data.height, 0, "default height should be 0")


func test_init_cells() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.init_cells(8, 4)
  assert_eq(data.width, 8)
  assert_eq(data.height, 4)
  assert_eq(data.cells.size(), 32, "8x4 should have 32 cells")


func test_get_set_cell() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.init_cells(4, 4)
  var cell_data: Dictionary = {
    "source_id": 1,
    "atlas_coords": Vector2i(2, 3),
    "alternative_tile": 0,
  }
  data.set_cell(1, 2, cell_data)
  var result: Dictionary = data.get_cell(1, 2)
  assert_eq(result["source_id"], 1)
  assert_eq(result["atlas_coords"], Vector2i(2, 3))


func test_get_cell_out_of_bounds() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.init_cells(4, 4)
  var result: Dictionary = data.get_cell(10, 10)
  assert_true(result.is_empty(), "out of bounds should return empty dict")


func test_is_valid_with_proper_data() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.init_cells(8, 4)
  data.constraints = PackedInt32Array([0, 1, 0, 1, 1, 0])
  assert_true(data.is_valid())


func test_is_valid_fails_without_constraints() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.init_cells(8, 4)
  assert_false(data.is_valid(), "should be invalid without constraints")


func test_is_valid_fails_with_wrong_cell_count() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.width = 8
  data.height = 4
  data.constraints = PackedInt32Array([0, 1, 0, 1, 1, 0])
  assert_false(data.is_valid(), "should be invalid with mismatched cells")


func test_constraint_key_horizontal() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  data.constraints = PackedInt32Array([0, 1, 0, 1, 1, 0])
  assert_eq(data.get_constraint_key(), "H_0_1_0_1_1_0")


func test_constraint_key_vertical() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.orientation = HerringboneMacroData.Orientation.VERTICAL
  data.constraints = PackedInt32Array([1, 0, 1, 0, 0, 1])
  assert_eq(data.get_constraint_key(), "V_1_0_1_0_0_1")


func test_serialization_round_trip() -> void:
  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.orientation = HerringboneMacroData.Orientation.VERTICAL
  data.tile_id = 42
  data.constraints = PackedInt32Array([1, 0, 1, 0, 0, 1])
  data.init_cells(4, 8)
  data.set_cell(1, 1, {
    "source_id": 5,
    "atlas_coords": Vector2i(3, 7),
    "alternative_tile": 1,
  })

  var path: String = "user://test_macro_data_roundtrip.tres"
  var err: Error = ResourceSaver.save(data, path)
  assert_eq(err, OK, "save should succeed")

  var loaded: HerringboneMacroData = ResourceLoader.load(path) as HerringboneMacroData
  assert_not_null(loaded, "loaded resource should not be null")
  assert_eq(loaded.orientation, HerringboneMacroData.Orientation.VERTICAL)
  assert_eq(loaded.tile_id, 42)
  assert_eq(loaded.constraints, PackedInt32Array([1, 0, 1, 0, 0, 1]))
  assert_eq(loaded.width, 4)
  assert_eq(loaded.height, 8)
  var cell: Dictionary = loaded.get_cell(1, 1)
  assert_eq(cell["source_id"], 5)

  DirAccess.remove_absolute(
    ProjectSettings.globalize_path(path)
  )
