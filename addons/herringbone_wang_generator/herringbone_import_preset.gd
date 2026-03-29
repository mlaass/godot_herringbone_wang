class_name HerringboneImportPreset
extends Resource

@export var preset_name: String = ""
@export var short_side_len: int = 10
@export var transparency_color: Color = Color(1, 0, 1, 1)
@export var v_section_origin: Vector2i = Vector2i(0, 0)
@export var v_section_cols: int = 16
@export var v_section_rows: int = 4
@export var h_section_origin: Vector2i = Vector2i(0, 96)
@export var h_section_cols: int = 8
@export var h_section_rows: int = 8


static func create_barrett() -> HerringboneImportPreset:
  var preset: HerringboneImportPreset = HerringboneImportPreset.new()
  preset.preset_name = "Barrett chunks.png"
  preset.short_side_len = 10
  preset.transparency_color = Color(1, 0, 1, 1)
  preset.v_section_origin = Vector2i(0, 0)
  preset.v_section_cols = 16
  preset.v_section_rows = 4
  preset.h_section_origin = Vector2i(0, 96)
  preset.h_section_cols = 8
  preset.h_section_rows = 8
  return preset
