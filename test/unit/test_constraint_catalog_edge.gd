extends GutTest


func test_create_hbe_222222() -> void:
  var cat: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbe_222222()
  )
  assert_eq(cat.schema_name, "hbe-222222")
  assert_false(cat.is_corner, "edge schema should not be corner mode")
  assert_eq(cat.num_colors.size(), 6)
  for i: int in range(6):
    assert_eq(cat.num_colors[i], 2, "all edge types should have 2 colors")


func test_create_empty_macro_set_edge() -> void:
  var cat: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbe_222222()
  )
  var ms: HerringboneMacroSet = cat.create_empty_macro_set(10)
  assert_false(ms.is_corner, "macro set should inherit edge mode")
  assert_eq(ms.num_colors.size(), 6)
  assert_eq(ms.base_unit_size, 10)


func test_edge_macro_set_required_counts() -> void:
  var cat: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbe_222222()
  )
  var ms: HerringboneMacroSet = cat.create_empty_macro_set(10)
  assert_eq(ms.get_required_h_count(), 64)
  assert_eq(ms.get_required_v_count(), 64)


func test_corner_catalog_still_works() -> void:
  var cat: HerringboneConstraintCatalog = (
    HerringboneConstraintCatalog.create_hbw_2222()
  )
  assert_true(cat.is_corner)
  var ms: HerringboneMacroSet = cat.create_empty_macro_set(4)
  assert_true(ms.is_corner)
  assert_eq(ms.num_colors.size(), 4)
  assert_eq(ms.get_required_h_count(), 64)
