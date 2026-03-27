extends GutTest


func _create_2222_set() -> HerringboneMacroSet:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.base_unit_size = 4
  ms.num_colors = PackedInt32Array([2, 2, 2, 2])
  return ms


func test_default_construction() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  assert_eq(ms.base_unit_size, 4)
  assert_eq(ms.num_colors, PackedInt32Array([2, 2, 2, 2]))
  assert_eq(ms.h_tiles.size(), 0)
  assert_eq(ms.v_tiles.size(), 0)


func test_required_h_count_2222() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  assert_eq(
    ms.get_required_h_count(), 64,
    "hbw-2222 should require 64 horizontal tiles"
  )


func test_required_v_count_2222() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  assert_eq(
    ms.get_required_v_count(), 64,
    "hbw-2222 should require 64 vertical tiles"
  )


func test_required_counts_2221() -> void:
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.num_colors = PackedInt32Array([2, 2, 2, 1])
  # H vertices use corner classes [1,2,3,0,1,2]
  # with colors [2,1,2,2,2,1] -> 2*1*2*2*2*1 = 16 ... wait
  # Actually: colors[1]=2, colors[2]=2, colors[3]=1,
  #           colors[0]=2, colors[1]=2, colors[2]=2
  # => 2*2*1*2*2*2 = 32
  assert_eq(ms.get_required_h_count(), 32)
  # V vertices use corner classes [0,3,2,1,0,3]
  # colors[0]=2, colors[3]=1, colors[2]=2,
  # colors[1]=2, colors[0]=2, colors[3]=1
  # => 2*1*2*2*2*1 = 16
  assert_eq(ms.get_required_v_count(), 16)


func test_is_complete_empty() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  assert_false(ms.is_complete(), "empty set should not be complete")


func test_missing_constraints_empty() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  var missing_h: Array[PackedInt32Array] = ms.get_missing_h_constraints()
  assert_eq(missing_h.size(), 64, "all 64 H combos should be missing")
  var missing_v: Array[PackedInt32Array] = ms.get_missing_v_constraints()
  assert_eq(missing_v.size(), 64, "all 64 V combos should be missing")


func test_find_tile_by_constraints() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  var tile: HerringboneMacroData = HerringboneMacroData.new()
  tile.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  tile.constraints = PackedInt32Array([0, 1, 0, 1, 1, 0])
  tile.init_cells(8, 4)
  ms.h_tiles.append(tile)

  var found: HerringboneMacroData = ms.find_tile_by_constraints(
    HerringboneMacroData.Orientation.HORIZONTAL,
    PackedInt32Array([0, 1, 0, 1, 1, 0]),
  )
  assert_not_null(found)
  assert_eq(found.get_constraint_key(), "H_0_1_0_1_1_0")


func test_find_tile_not_found() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  var found: HerringboneMacroData = ms.find_tile_by_constraints(
    HerringboneMacroData.Orientation.HORIZONTAL,
    PackedInt32Array([0, 0, 0, 0, 0, 0]),
  )
  assert_null(found, "should return null when no matching tile exists")


func test_adding_tile_reduces_missing() -> void:
  var ms: HerringboneMacroSet = _create_2222_set()
  var missing_before: int = ms.get_missing_h_constraints().size()

  var tile: HerringboneMacroData = HerringboneMacroData.new()
  tile.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  tile.constraints = PackedInt32Array([0, 0, 0, 0, 0, 0])
  tile.init_cells(8, 4)
  ms.h_tiles.append(tile)

  var missing_after: int = ms.get_missing_h_constraints().size()
  assert_eq(
    missing_after, missing_before - 1,
    "adding one tile should reduce missing by 1"
  )
