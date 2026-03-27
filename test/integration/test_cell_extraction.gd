extends GutTest


func test_bake_returns_null_without_catalog() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_null(result, "should return null without catalog")
  layer.free()


func test_bake_returns_null_without_tileset() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  layer.catalog = HerringboneConstraintCatalog.create_hbw_2222()
  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_null(result, "should return null without tile_set")
  layer.free()


func test_bake_returns_valid_macro_set() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  layer.catalog = HerringboneConstraintCatalog.create_hbw_2222()
  layer.tile_set = TileSet.new()
  layer.base_unit_size = 4

  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_not_null(result, "should return MacroSet with catalog and tileset")
  assert_eq(result.base_unit_size, 4)
  assert_eq(result.num_colors, PackedInt32Array([2, 2, 2, 2]))
  layer.free()


func test_baked_tile_dimensions_horizontal() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  layer.catalog = HerringboneConstraintCatalog.create_hbw_2222()
  layer.tile_set = TileSet.new()
  layer.base_unit_size = 4

  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_true(result.h_tiles.size() > 0, "should have horizontal tiles")
  var first_h: HerringboneMacroData = result.h_tiles[0]
  assert_eq(first_h.width, 8, "H tile width should be 2*N=8")
  assert_eq(first_h.height, 4, "H tile height should be N=4")
  assert_eq(
    first_h.orientation,
    HerringboneMacroData.Orientation.HORIZONTAL,
  )
  layer.free()


func test_baked_tile_dimensions_vertical() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  layer.catalog = HerringboneConstraintCatalog.create_hbw_2222()
  layer.tile_set = TileSet.new()
  layer.base_unit_size = 4

  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_true(result.v_tiles.size() > 0, "should have vertical tiles")
  var first_v: HerringboneMacroData = result.v_tiles[0]
  assert_eq(first_v.width, 4, "V tile width should be N=4")
  assert_eq(first_v.height, 8, "V tile height should be 2*N=8")
  assert_eq(
    first_v.orientation,
    HerringboneMacroData.Orientation.VERTICAL,
  )
  layer.free()


func test_baked_tile_count_2222() -> void:
  var layer: HerringboneAuthoringLayer = HerringboneAuthoringLayer.new()
  layer.catalog = HerringboneConstraintCatalog.create_hbw_2222()
  layer.tile_set = TileSet.new()
  layer.base_unit_size = 4

  var result: HerringboneMacroSet = layer.bake_macro_set()
  assert_eq(result.h_tiles.size(), 64, "hbw-2222 should have 64 H tiles")
  assert_eq(result.v_tiles.size(), 64, "hbw-2222 should have 64 V tiles")
  layer.free()
