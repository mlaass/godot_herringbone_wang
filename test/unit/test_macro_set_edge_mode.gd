extends GutTest


func _create_edge_set(
  colors: PackedInt32Array = PackedInt32Array([2, 2, 2, 2, 2, 2]),
) -> HerringboneMacroSet:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.is_corner = false
  ms.num_colors = colors
  ms.base_unit_size = 10
  return ms


func test_default_is_corner_true() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  assert_true(ms.is_corner, "default should be corner mode")


func test_edge_mode_required_h_count_222222() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  assert_eq(ms.get_required_h_count(), 64, "hbe-222222 needs 64 H tiles")


func test_edge_mode_required_v_count_222222() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  assert_eq(ms.get_required_v_count(), 64, "hbe-222222 needs 64 V tiles")


func test_edge_mode_total_128() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  var total: int = ms.get_required_h_count() + ms.get_required_v_count()
  assert_eq(total, 128, "hbe-222222 needs 128 total tiles")


func test_edge_mode_empty_set_all_missing() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  assert_eq(
    ms.get_missing_h_constraints().size(), 64,
    "empty set should miss all 64 H combos"
  )
  assert_eq(
    ms.get_missing_v_constraints().size(), 64,
    "empty set should miss all 64 V combos"
  )


func test_edge_mode_find_tile_by_constraints() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  var tile: HerringboneMacroData = HerringboneMacroData.new()
  tile.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  tile.tile_id = 0
  tile.constraints = PackedInt32Array([0, 0, 0, 0, 0, 0])
  tile.init_cells(20, 10)
  ms.h_tiles.append(tile)

  var found: HerringboneMacroData = ms.find_tile_by_constraints(
    HerringboneMacroData.Orientation.HORIZONTAL,
    PackedInt32Array([0, 0, 0, 0, 0, 0]),
  )
  assert_not_null(found, "should find the tile we added")
  assert_eq(found.tile_id, 0)


func test_edge_mode_is_complete() -> void:
  var ms: HerringboneMacroSet = _create_edge_set()
  var tid: int = 0
  for combo: PackedInt32Array in ms.get_missing_h_constraints():
    var tile: HerringboneMacroData = HerringboneMacroData.new()
    tile.orientation = HerringboneMacroData.Orientation.HORIZONTAL
    tile.tile_id = tid
    tile.constraints = combo
    tile.init_cells(20, 10)
    ms.h_tiles.append(tile)
    tid += 1
  for combo: PackedInt32Array in ms.get_missing_v_constraints():
    var tile: HerringboneMacroData = HerringboneMacroData.new()
    tile.orientation = HerringboneMacroData.Orientation.VERTICAL
    tile.tile_id = tid
    tile.constraints = combo
    tile.init_cells(10, 20)
    ms.v_tiles.append(tile)
    tid += 1
  assert_true(ms.is_complete(), "fully populated edge set should be complete")
  assert_eq(tid, 128, "should have created exactly 128 tiles")


func test_corner_mode_unchanged() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])
  ms.is_corner = true
  assert_eq(ms.get_required_h_count(), 64)
  assert_eq(ms.get_required_v_count(), 64)


func test_edge_mode_asymmetric_colors() -> void:
  # [2,3,2,2,2,2]: type1 has 3 colors instead of 2
  var ms: HerringboneMacroSet = _create_edge_set(
    PackedInt32Array([2, 3, 2, 2, 2, 2])
  )
  # H type_map = [1,2,3,4,0,2] -> counts = [3,2,2,2,2,2] -> product = 96
  assert_eq(ms.get_required_h_count(), 96)
  # V type_map = [0,5,4,3,1,5] -> counts = [2,2,2,2,3,2] -> product = 96
  assert_eq(ms.get_required_v_count(), 96)
