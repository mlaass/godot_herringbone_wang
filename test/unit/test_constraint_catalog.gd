extends GutTest


func test_create_hbw_2222() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_2222()
  )
  assert_eq(catalog.schema_name, "hbw-2222")
  assert_eq(catalog.num_colors, PackedInt32Array([2, 2, 2, 2]))
  assert_true(catalog.is_corner)


func test_create_hbw_2221() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_2221()
  )
  assert_eq(catalog.schema_name, "hbw-2221")
  assert_eq(catalog.num_colors, PackedInt32Array([2, 2, 2, 1]))


func test_create_hbw_3131() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_3131()
  )
  assert_eq(catalog.schema_name, "hbw-3131")
  assert_eq(catalog.num_colors, PackedInt32Array([3, 1, 3, 1]))


func test_create_empty_macro_set() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_2222()
  )
  var ms: HerringboneMacroSet = catalog.create_empty_macro_set(4)
  assert_not_null(ms)
  assert_eq(ms.base_unit_size, 4)
  assert_eq(ms.num_colors, PackedInt32Array([2, 2, 2, 2]))
  assert_eq(ms.h_tiles.size(), 0, "should start empty")
  assert_eq(ms.v_tiles.size(), 0, "should start empty")


func test_empty_macro_set_knows_required_counts() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_2222()
  )
  var ms: HerringboneMacroSet = catalog.create_empty_macro_set(4)
  assert_eq(ms.get_required_h_count(), 64)
  assert_eq(ms.get_required_v_count(), 64)


func test_3131_required_counts() -> void:
  var catalog: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_3131()
  )
  var ms: HerringboneMacroSet = catalog.create_empty_macro_set(4)
  assert_eq(ms.get_required_h_count(), 27)
  assert_eq(ms.get_required_v_count(), 27)
