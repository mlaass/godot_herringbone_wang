extends GutTest


func test_barrett_factory_values() -> void:
  var preset: HerringboneImportPreset = (
    HerringboneImportPreset.create_barrett()
  )
  assert_eq(preset.short_side_len, 10)
  assert_eq(preset.transparency_color, Color(1, 0, 1, 1))
  assert_eq(preset.v_section_origin, Vector2i(0, 0))
  assert_eq(preset.v_section_cols, 16)
  assert_eq(preset.v_section_rows, 4)
  assert_eq(preset.h_section_origin, Vector2i(0, 96))
  assert_eq(preset.h_section_cols, 8)
  assert_eq(preset.h_section_rows, 8)


func test_barrett_preset_name() -> void:
  var preset: HerringboneImportPreset = (
    HerringboneImportPreset.create_barrett()
  )
  assert_eq(preset.preset_name, "Barrett chunks.png")


func test_default_values() -> void:
  var preset: HerringboneImportPreset = HerringboneImportPreset.new()
  assert_eq(preset.preset_name, "")
  assert_eq(preset.short_side_len, 10)
  assert_eq(preset.transparency_color, Color(1, 0, 1, 1))
  assert_eq(preset.v_section_origin, Vector2i(0, 0))
  assert_eq(preset.v_section_cols, 16)
  assert_eq(preset.v_section_rows, 4)
  assert_eq(preset.h_section_origin, Vector2i(0, 96))
  assert_eq(preset.h_section_cols, 8)
  assert_eq(preset.h_section_rows, 8)


func test_custom_values() -> void:
  var preset: HerringboneImportPreset = HerringboneImportPreset.new()
  preset.preset_name = "Custom"
  preset.short_side_len = 5
  preset.v_section_origin = Vector2i(10, 20)
  preset.v_section_cols = 8
  preset.v_section_rows = 2
  preset.h_section_origin = Vector2i(30, 40)
  preset.h_section_cols = 4
  preset.h_section_rows = 4
  assert_eq(preset.short_side_len, 5)
  assert_eq(preset.v_section_origin, Vector2i(10, 20))
  assert_eq(preset.h_section_cols, 4)


func test_resource_serialization_roundtrip() -> void:
  var preset: HerringboneImportPreset = HerringboneImportPreset.new()
  preset.preset_name = "Test Roundtrip"
  preset.short_side_len = 7
  preset.transparency_color = Color(0, 1, 0, 1)
  preset.v_section_origin = Vector2i(5, 10)
  preset.v_section_cols = 12
  preset.v_section_rows = 3
  preset.h_section_origin = Vector2i(15, 50)
  preset.h_section_cols = 6
  preset.h_section_rows = 6

  var path: String = "res://test/tmp_test_preset.tres"
  var err: int = ResourceSaver.save(preset, path)
  assert_eq(err, OK, "save should succeed")

  var loaded: HerringboneImportPreset = (
    load(path) as HerringboneImportPreset
  )
  assert_not_null(loaded)
  assert_eq(loaded.preset_name, "Test Roundtrip")
  assert_eq(loaded.short_side_len, 7)
  assert_eq(loaded.transparency_color, Color(0, 1, 0, 1))
  assert_eq(loaded.v_section_origin, Vector2i(5, 10))
  assert_eq(loaded.v_section_cols, 12)
  assert_eq(loaded.v_section_rows, 3)
  assert_eq(loaded.h_section_origin, Vector2i(15, 50))
  assert_eq(loaded.h_section_cols, 6)
  assert_eq(loaded.h_section_rows, 6)

  # Cleanup
  DirAccess.remove_absolute(
    ProjectSettings.globalize_path(path),
  )
