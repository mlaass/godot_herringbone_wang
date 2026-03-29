@tool
class_name HerringboneEditorPanel
extends PanelContainer

# -- Target tracking --
var _target_layer: TileMapLayer = null

# -- Shared state --
var _chunk_map_path: String = ""
var _mapping_path: String = ""
var _macro_set: HerringboneMacroSet = null
var _last_map_width: int = 0
var _last_map_height: int = 0

# -- Header --
var _target_label: Label

# -- Section 1: Detect Colors --
var _chunk_map_line_edit: LineEdit
var _transparency_picker: ColorPickerButton
var _detect_btn: Button
var _detect_status: Label

# -- Section 2: Import --
var _import_chunk_label: Label
var _mapping_line_edit: LineEdit
var _preset_option: OptionButton
var _short_side_spin: SpinBox
var _import_transparency_picker: ColorPickerButton
var _v_origin_x_spin: SpinBox
var _v_origin_y_spin: SpinBox
var _v_cols_spin: SpinBox
var _v_rows_spin: SpinBox
var _h_origin_x_spin: SpinBox
var _h_origin_y_spin: SpinBox
var _h_cols_spin: SpinBox
var _h_rows_spin: SpinBox
var _import_btn: Button
var _load_file_btn: Button
var _save_preset_btn: Button
var _import_status: Label
var _validation_status: Label

# -- Section 3: Generate & Place --
var _map_width_spin: SpinBox
var _map_height_spin: SpinBox
var _seed_spin: SpinBox
var _fallback_source_spin: SpinBox
var _fallback_x_spin: SpinBox
var _fallback_y_spin: SpinBox
var _generate_btn: Button
var _clear_btn: Button
var _generate_status: Label


func _ready() -> void:
  _build_ui()
  _update_button_states()


# -- Public API (called by plugin) --


func set_target_layer(layer: TileMapLayer) -> void:
  _target_layer = layer
  _update_target_display()
  _update_button_states()


# -- UI Construction --


func _build_ui() -> void:
  var scroll: ScrollContainer = ScrollContainer.new()
  scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
  add_child(scroll)

  var root: VBoxContainer = VBoxContainer.new()
  root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  root.size_flags_vertical = Control.SIZE_EXPAND_FILL
  scroll.add_child(root)

  # Header
  _target_label = Label.new()
  _target_label.text = "No TileMapLayer selected"
  root.add_child(_target_label)
  root.add_child(HSeparator.new())

  # Section 1: Detect Colors
  var detect_content: VBoxContainer = _build_detect_section()
  var detect_header: Button = _build_section_header(
    "Detect Colors", detect_content,
  )
  root.add_child(detect_header)
  root.add_child(detect_content)
  root.add_child(HSeparator.new())

  # Section 2: Import
  var import_content: VBoxContainer = _build_import_section()
  var import_header: Button = _build_section_header(
    "Import", import_content,
  )
  root.add_child(import_header)
  root.add_child(import_content)
  root.add_child(HSeparator.new())

  # Section 3: Generate & Place
  var gen_content: VBoxContainer = _build_generate_section()
  var gen_header: Button = _build_section_header(
    "Generate & Place", gen_content,
  )
  root.add_child(gen_header)
  root.add_child(gen_content)


func _build_section_header(
  text: String, section: Control,
) -> Button:
  var btn: Button = Button.new()
  btn.text = text
  btn.toggle_mode = true
  btn.button_pressed = true
  btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
  btn.toggled.connect(func(pressed: bool) -> void:
    section.visible = pressed
  )
  return btn


func _build_detect_section() -> VBoxContainer:
  var vbox: VBoxContainer = VBoxContainer.new()

  # Chunk map row
  var chunk_row: HBoxContainer = HBoxContainer.new()
  chunk_row.add_child(_create_label("Chunk Map:"))
  _chunk_map_line_edit = LineEdit.new()
  _chunk_map_line_edit.editable = false
  _chunk_map_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _chunk_map_line_edit.placeholder_text = "Select a PNG image..."
  chunk_row.add_child(_chunk_map_line_edit)
  var browse_btn: Button = Button.new()
  browse_btn.text = "Browse..."
  browse_btn.pressed.connect(_on_chunk_browse_pressed)
  chunk_row.add_child(browse_btn)
  vbox.add_child(chunk_row)

  # Transparency row
  var trans_row: HBoxContainer = HBoxContainer.new()
  trans_row.add_child(_create_label("Transparency:"))
  _transparency_picker = ColorPickerButton.new()
  _transparency_picker.color = Color(1, 0, 1, 1)
  _transparency_picker.custom_minimum_size = Vector2(60, 0)
  trans_row.add_child(_transparency_picker)
  vbox.add_child(trans_row)

  # Detect button
  _detect_btn = Button.new()
  _detect_btn.text = "Detect Colors"
  _detect_btn.pressed.connect(_on_detect_pressed)
  vbox.add_child(_detect_btn)

  # Status
  _detect_status = Label.new()
  _detect_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  vbox.add_child(_detect_status)

  return vbox


func _build_import_section() -> VBoxContainer:
  var vbox: VBoxContainer = VBoxContainer.new()

  # Chunk map row (read-only, shared path)
  var chunk_row: HBoxContainer = HBoxContainer.new()
  chunk_row.add_child(_create_label("Chunk Map:"))
  _import_chunk_label = Label.new()
  _import_chunk_label.text = "(none)"
  _import_chunk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _import_chunk_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  chunk_row.add_child(_import_chunk_label)
  var chunk_browse: Button = Button.new()
  chunk_browse.text = "Browse..."
  chunk_browse.pressed.connect(_on_chunk_browse_pressed)
  chunk_row.add_child(chunk_browse)
  vbox.add_child(chunk_row)

  # Color mapping row
  var map_row: HBoxContainer = HBoxContainer.new()
  map_row.add_child(_create_label("Color Mapping:"))
  _mapping_line_edit = LineEdit.new()
  _mapping_line_edit.editable = false
  _mapping_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _mapping_line_edit.placeholder_text = "Select a .tres mapping..."
  map_row.add_child(_mapping_line_edit)
  var map_browse: Button = Button.new()
  map_browse.text = "Browse..."
  map_browse.pressed.connect(_on_mapping_browse_pressed)
  map_row.add_child(map_browse)
  vbox.add_child(map_row)

  # Preset row
  var preset_row: HBoxContainer = HBoxContainer.new()
  preset_row.add_child(_create_label("Preset:"))
  _preset_option = OptionButton.new()
  _preset_option.add_item("Barrett chunks.png", 0)
  _preset_option.add_item("Custom", 1)
  _preset_option.item_selected.connect(_on_preset_selected)
  preset_row.add_child(_preset_option)
  vbox.add_child(preset_row)

  vbox.add_child(HSeparator.new())

  # Parameter row 1: N + transparency
  var param_row1: HBoxContainer = HBoxContainer.new()
  param_row1.add_child(_create_label("Short Side (N):"))
  _short_side_spin = _create_spin(1, 100, 10)
  param_row1.add_child(_short_side_spin)
  param_row1.add_child(_create_label("Transparency:"))
  _import_transparency_picker = ColorPickerButton.new()
  _import_transparency_picker.color = Color(1, 0, 1, 1)
  _import_transparency_picker.custom_minimum_size = Vector2(60, 0)
  param_row1.add_child(_import_transparency_picker)
  vbox.add_child(param_row1)

  # V section row
  var v_row: HBoxContainer = HBoxContainer.new()
  v_row.add_child(_create_label("V Origin:"))
  _v_origin_x_spin = _create_spin(0, 9999, 0)
  _v_origin_y_spin = _create_spin(0, 9999, 0)
  v_row.add_child(_v_origin_x_spin)
  v_row.add_child(_v_origin_y_spin)
  v_row.add_child(_create_label("Cols:"))
  _v_cols_spin = _create_spin(1, 999, 16)
  v_row.add_child(_v_cols_spin)
  v_row.add_child(_create_label("Rows:"))
  _v_rows_spin = _create_spin(1, 999, 4)
  v_row.add_child(_v_rows_spin)
  vbox.add_child(v_row)

  # H section row
  var h_row: HBoxContainer = HBoxContainer.new()
  h_row.add_child(_create_label("H Origin:"))
  _h_origin_x_spin = _create_spin(0, 9999, 0)
  _h_origin_y_spin = _create_spin(0, 9999, 96)
  h_row.add_child(_h_origin_x_spin)
  h_row.add_child(_h_origin_y_spin)
  h_row.add_child(_create_label("Cols:"))
  _h_cols_spin = _create_spin(1, 999, 8)
  h_row.add_child(_h_cols_spin)
  h_row.add_child(_create_label("Rows:"))
  _h_rows_spin = _create_spin(1, 999, 8)
  h_row.add_child(_h_rows_spin)
  vbox.add_child(h_row)

  vbox.add_child(HSeparator.new())

  # Action buttons row
  var btn_row: HBoxContainer = HBoxContainer.new()
  _import_btn = Button.new()
  _import_btn.text = "Import from Chunk Map"
  _import_btn.pressed.connect(_on_import_pressed)
  btn_row.add_child(_import_btn)
  _load_file_btn = Button.new()
  _load_file_btn.text = "Load from File..."
  _load_file_btn.pressed.connect(_on_load_file_pressed)
  btn_row.add_child(_load_file_btn)
  _save_preset_btn = Button.new()
  _save_preset_btn.text = "Save Preset..."
  _save_preset_btn.pressed.connect(_on_save_preset_pressed)
  btn_row.add_child(_save_preset_btn)
  vbox.add_child(btn_row)

  # Status labels
  _import_status = Label.new()
  _import_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  vbox.add_child(_import_status)
  _validation_status = Label.new()
  _validation_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  vbox.add_child(_validation_status)

  return vbox


func _build_generate_section() -> VBoxContainer:
  var vbox: VBoxContainer = VBoxContainer.new()

  # Size + seed row
  var size_row: HBoxContainer = HBoxContainer.new()
  size_row.add_child(_create_label("Map Width:"))
  _map_width_spin = _create_spin(1, 500, 20)
  size_row.add_child(_map_width_spin)
  size_row.add_child(_create_label("Map Height:"))
  _map_height_spin = _create_spin(1, 500, 20)
  size_row.add_child(_map_height_spin)
  size_row.add_child(_create_label("Seed:"))
  _seed_spin = _create_spin(0, 999999, 42)
  size_row.add_child(_seed_spin)
  vbox.add_child(size_row)

  # Fallback tile row
  var fb_row: HBoxContainer = HBoxContainer.new()
  fb_row.add_child(_create_label("Fallback Tile: source"))
  _fallback_source_spin = _create_spin(0, 100, 0)
  fb_row.add_child(_fallback_source_spin)
  fb_row.add_child(_create_label("atlas_x"))
  _fallback_x_spin = _create_spin(0, 100, 0)
  fb_row.add_child(_fallback_x_spin)
  fb_row.add_child(_create_label("atlas_y"))
  _fallback_y_spin = _create_spin(0, 100, 0)
  fb_row.add_child(_fallback_y_spin)
  vbox.add_child(fb_row)

  # Action buttons
  var btn_row: HBoxContainer = HBoxContainer.new()
  _generate_btn = Button.new()
  _generate_btn.text = "Generate & Place"
  _generate_btn.pressed.connect(_on_generate_pressed)
  btn_row.add_child(_generate_btn)
  _clear_btn = Button.new()
  _clear_btn.text = "Clear Generated Region"
  _clear_btn.disabled = true
  _clear_btn.pressed.connect(_on_clear_pressed)
  btn_row.add_child(_clear_btn)
  vbox.add_child(btn_row)

  # Status
  _generate_status = Label.new()
  _generate_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  vbox.add_child(_generate_status)

  return vbox


# -- Helpers --


func _create_label(text: String) -> Label:
  var lbl: Label = Label.new()
  lbl.text = text
  return lbl


func _create_spin(
  min_val: float, max_val: float, default_val: float,
) -> SpinBox:
  var spin: SpinBox = SpinBox.new()
  spin.min_value = min_val
  spin.max_value = max_val
  spin.value = default_val
  spin.step = 1.0
  spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  return spin


func _set_status(
  label: Label, text: String, type: String = "info",
) -> void:
  match type:
    "success":
      label.add_theme_color_override(
        "font_color", Color(0.5, 1.0, 0.5),
      )
      label.text = text
    "error":
      label.add_theme_color_override(
        "font_color", Color(1.0, 0.4, 0.4),
      )
      label.text = text
    "warning":
      label.add_theme_color_override(
        "font_color", Color(1.0, 1.0, 0.4),
      )
      label.text = text
    _:
      label.add_theme_color_override(
        "font_color", Color(0.8, 0.8, 0.8),
      )
      label.text = text


func _update_target_display() -> void:
  if _target_label == null:
    return
  if is_instance_valid(_target_layer):
    _target_label.text = "Target: %s" % _target_layer.name
  else:
    _target_layer = null
    _target_label.text = "No TileMapLayer selected"


func _update_button_states() -> void:
  var has_target: bool = is_instance_valid(_target_layer)
  if _generate_btn != null:
    _generate_btn.disabled = not has_target
  if _clear_btn != null and _clear_btn.disabled == false:
    _clear_btn.disabled = not has_target


func _set_chunk_map_path(path: String) -> void:
  _chunk_map_path = path
  if _chunk_map_line_edit != null:
    _chunk_map_line_edit.text = path
  if _import_chunk_label != null:
    _import_chunk_label.text = path if path != "" else "(none)"


func _open_file_dialog(
  mode: int,
  filters: PackedStringArray,
  callback: Callable,
) -> void:
  var dialog: EditorFileDialog = EditorFileDialog.new()
  dialog.file_mode = mode
  dialog.access = EditorFileDialog.ACCESS_RESOURCES
  for f: String in filters:
    dialog.add_filter(f)
  dialog.file_selected.connect(func(path: String) -> void:
    callback.call(path)
    dialog.queue_free()
  )
  dialog.canceled.connect(dialog.queue_free)
  EditorInterface.get_base_control().add_child(dialog)
  dialog.popup_centered(Vector2i(800, 500))


# -- Section 1: Detect Colors handlers --


func _on_chunk_browse_pressed() -> void:
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_OPEN_FILE,
    PackedStringArray(["*.png ; PNG Images"]),
    _set_chunk_map_path,
  )


func _on_detect_pressed() -> void:
  if _chunk_map_path == "":
    _set_status(_detect_status, "Select a chunk map image first", "error")
    return

  var image: Image = Image.load_from_file(
    ProjectSettings.globalize_path(_chunk_map_path),
  )
  if image == null:
    _set_status(
      _detect_status,
      "Failed to load image: %s" % _chunk_map_path,
      "error",
    )
    return

  var mapping: HerringboneColorTileMapping = (
    HerringboneColorTileMapping.new()
  )
  mapping.detect_colors_from_image(
    image, _transparency_picker.color,
  )

  var count: int = mapping.entries.size()
  print("PANEL: Detected %d content colors" % count)

  # Open save dialog
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_SAVE_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      var err: int = ResourceSaver.save(mapping, path)
      if err != OK:
        _set_status(
          _detect_status,
          "Failed to save resource: error %d" % err,
          "error",
        )
        return
      _set_status(
        _detect_status,
        "Found %d content colors. Saved to %s" % [count, path],
        "success",
      ),
  )


# -- Section 2: Import handlers --


func _on_mapping_browse_pressed() -> void:
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_OPEN_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      _mapping_path = path
      _mapping_line_edit.text = path,
  )


func _on_preset_selected(index: int) -> void:
  if index == 0:
    _apply_preset(HerringboneImportPreset.create_barrett())


func _apply_preset(preset: HerringboneImportPreset) -> void:
  _short_side_spin.value = preset.short_side_len
  _import_transparency_picker.color = preset.transparency_color
  _v_origin_x_spin.value = preset.v_section_origin.x
  _v_origin_y_spin.value = preset.v_section_origin.y
  _v_cols_spin.value = preset.v_section_cols
  _v_rows_spin.value = preset.v_section_rows
  _h_origin_x_spin.value = preset.h_section_origin.x
  _h_origin_y_spin.value = preset.h_section_origin.y
  _h_cols_spin.value = preset.h_section_cols
  _h_rows_spin.value = preset.h_section_rows
  print("PANEL: Applied preset '%s'" % preset.preset_name)


func _on_import_pressed() -> void:
  if _chunk_map_path == "":
    _set_status(_import_status, "Select a chunk map image first", "error")
    return
  if _mapping_path == "":
    _set_status(
      _import_status, "Select a color mapping resource first", "error",
    )
    return

  var image: Image = Image.load_from_file(
    ProjectSettings.globalize_path(_chunk_map_path),
  )
  if image == null:
    _set_status(
      _import_status,
      "Failed to load image: %s" % _chunk_map_path,
      "error",
    )
    return

  var mapping: HerringboneColorTileMapping = ResourceLoader.load(
    _mapping_path, "", ResourceLoader.CACHE_MODE_IGNORE,
  ) as HerringboneColorTileMapping
  if mapping == null:
    _set_status(
      _import_status,
      "Failed to load mapping: %s" % _mapping_path,
      "error",
    )
    return

  # Warn about unmapped colors
  var unmapped: int = 0
  for entry: Dictionary in mapping.entries:
    var sid: int = entry.get("source_id", -1)
    if sid < 0:
      unmapped += 1
  if unmapped > 0:
    _set_status(
      _validation_status,
      "%d colors in mapping have no atlas assignment" % unmapped,
      "warning",
    )

  var importer: HerringboneChunkImporter = HerringboneChunkImporter.new()
  var result: Dictionary = importer.import_chunk_map(
    image,
    int(_short_side_spin.value),
    _import_transparency_picker.color,
    Vector2i(
      int(_v_origin_x_spin.value), int(_v_origin_y_spin.value),
    ),
    int(_v_cols_spin.value),
    int(_v_rows_spin.value),
    Vector2i(
      int(_h_origin_x_spin.value), int(_h_origin_y_spin.value),
    ),
    int(_h_cols_spin.value),
    int(_h_rows_spin.value),
    mapping,
  )

  if not result["success"]:
    var errs: PackedStringArray = result["errors"]
    _set_status(
      _import_status, "Import failed: %s" % ", ".join(errs), "error",
    )
    return

  _macro_set = result["macro_set"]
  var imported: int = result["tiles_imported"]
  var skipped: int = result["tiles_skipped"]
  var h_count: int = _macro_set.h_tiles.size()
  var v_count: int = _macro_set.v_tiles.size()
  _set_status(
    _import_status,
    "Imported %d tiles (%d H + %d V), %d skipped"
    % [imported, h_count, v_count, skipped],
    "success",
  )

  # Warnings from importer
  var warnings: PackedStringArray = result["warnings"]
  if not warnings.is_empty():
    print("PANEL: Import warnings: %s" % ", ".join(warnings))

  # Validate
  var validation: Dictionary = HerringboneValidator.validate(_macro_set)
  var pct: float = validation["completion_pct"]
  if validation["is_valid"] and pct >= 100.0:
    _set_status(
      _validation_status,
      "Validation: %.1f%% complete" % pct,
      "success",
    )
  elif validation["is_valid"]:
    _set_status(
      _validation_status,
      "Validation: %.1f%% complete" % pct,
      "warning",
    )
  else:
    var val_errs: PackedStringArray = validation["errors"]
    _set_status(
      _validation_status,
      "Validation errors: %s" % ", ".join(val_errs),
      "error",
    )

  _update_button_states()
  print(
    "PANEL: Imported %d tiles, validation %.1f%%"
    % [imported, pct]
  )


func _on_load_file_pressed() -> void:
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_OPEN_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      var res: Resource = ResourceLoader.load(
        path, "", ResourceLoader.CACHE_MODE_IGNORE,
      )
      if not res is HerringboneMacroSet:
        _set_status(
          _import_status,
          "Not a HerringboneMacroSet: %s" % path,
          "error",
        )
        return
      _macro_set = res as HerringboneMacroSet
      var h_count: int = _macro_set.h_tiles.size()
      var v_count: int = _macro_set.v_tiles.size()
      _set_status(
        _import_status,
        "Loaded %d tiles (%d H + %d V) from %s"
        % [h_count + v_count, h_count, v_count, path],
        "success",
      )
      var validation: Dictionary = (
        HerringboneValidator.validate(_macro_set)
      )
      var pct: float = validation["completion_pct"]
      _set_status(
        _validation_status,
        "Validation: %.1f%% complete" % pct,
        "success" if pct >= 100.0 else "warning",
      )
      _update_button_states()
      print("PANEL: Loaded macro set from %s" % path),
  )


func _on_save_preset_pressed() -> void:
  var preset: HerringboneImportPreset = HerringboneImportPreset.new()
  preset.short_side_len = int(_short_side_spin.value)
  preset.transparency_color = _import_transparency_picker.color
  preset.v_section_origin = Vector2i(
    int(_v_origin_x_spin.value), int(_v_origin_y_spin.value),
  )
  preset.v_section_cols = int(_v_cols_spin.value)
  preset.v_section_rows = int(_v_rows_spin.value)
  preset.h_section_origin = Vector2i(
    int(_h_origin_x_spin.value), int(_h_origin_y_spin.value),
  )
  preset.h_section_cols = int(_h_cols_spin.value)
  preset.h_section_rows = int(_h_rows_spin.value)

  _open_file_dialog(
    EditorFileDialog.FILE_MODE_SAVE_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      preset.preset_name = path.get_file().get_basename()
      var err: int = ResourceSaver.save(preset, path)
      if err != OK:
        _set_status(
          _import_status,
          "Failed to save preset: error %d" % err,
          "error",
        )
        return
      _set_status(
        _import_status,
        "Preset saved to %s" % path,
        "success",
      )
      # Add to dropdown if not already there
      var idx: int = _preset_option.item_count
      _preset_option.add_item(preset.preset_name, idx)
      _preset_option.select(idx),
  )


# -- Section 3: Generate & Place handlers --


func _on_generate_pressed() -> void:
  if _macro_set == null:
    _set_status(_generate_status, "Import tiles first", "error")
    return
  if not is_instance_valid(_target_layer):
    _target_layer = null
    _update_target_display()
    _set_status(
      _generate_status, "No TileMapLayer selected", "error",
    )
    return
  if _target_layer.tile_set == null:
    _set_status(
      _generate_status,
      "TileMapLayer has no TileSet assigned",
      "error",
    )
    return

  var width: int = int(_map_width_spin.value)
  var height: int = int(_map_height_spin.value)
  var seed_val: int = int(_seed_spin.value)
  var n: int = _macro_set.base_unit_size

  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_constraint_mode(_macro_set.is_corner)
  if _macro_set.is_corner:
    gen.set_corner_colors(_macro_set.num_colors)
  else:
    gen.set_edge_colors(_macro_set.num_colors)
  gen.load_tile_definitions(_macro_set.to_generator_defs())

  if not gen.build_tileset():
    _set_status(
      _generate_status,
      "Generator build failed: %s" % gen.get_last_error(),
      "error",
    )
    return

  var abstract_map: Array = gen.generate_abstract_map(
    width, height, seed_val,
  )
  print("PANEL: Generated %d tile placements" % abstract_map.size())

  # Clear only the generated region
  _clear_generated_region(width, height, n)

  # Build fallback cell
  var fallback: Dictionary = {
    "source_id": int(_fallback_source_spin.value),
    "atlas_coords": Vector2i(
      int(_fallback_x_spin.value), int(_fallback_y_spin.value),
    ),
    "alternative_tile": 0,
  }

  HerringboneAuthoringLayer.populate_tilemap(
    _target_layer, abstract_map, _macro_set, fallback,
  )

  _last_map_width = width
  _last_map_height = height
  _clear_btn.disabled = false

  _set_status(
    _generate_status,
    "Generated %d placements, populated TileMapLayer \"%s\""
    % [abstract_map.size(), _target_layer.name],
    "success",
  )


func _on_clear_pressed() -> void:
  if not is_instance_valid(_target_layer) or _macro_set == null:
    return
  _clear_generated_region(
    _last_map_width, _last_map_height, _macro_set.base_unit_size,
  )
  _set_status(_generate_status, "Cleared generated region", "info")


func _clear_generated_region(
  map_width: int, map_height: int, base_unit: int,
) -> void:
  if not is_instance_valid(_target_layer):
    return
  var pixel_w: int = map_width * base_unit
  var pixel_h: int = map_height * base_unit
  for y: int in range(pixel_h):
    for x: int in range(pixel_w):
      _target_layer.erase_cell(Vector2i(x, y))
