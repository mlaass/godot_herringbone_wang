@tool
class_name HerringboneEditorPanel
extends PanelContainer

# -- Target tracking --
var _target_layer: TileMapLayer = null

# -- Shared state --
var _chunk_map_path: String = ""
var _mapping_path: String = ""
var _current_mapping: HerringboneColorTileMapping = null
var _macro_set: HerringboneMacroSet = null
var _last_map_width: int = 0
var _last_map_height: int = 0

# -- Header --
var _target_label: Label

# -- Section 1: Detect Colors + Mapping --
var _chunk_map_line_edit: LineEdit
var _transparency_picker: ColorPickerButton
var _detect_btn: Button
var _detect_status: Label
var _mapping_entries_container: VBoxContainer
var _mapping_buttons_row: HBoxContainer
var _save_mapping_btn: Button
var _load_mapping_btn: Button

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

  # Detect button row
  var detect_row: HBoxContainer = HBoxContainer.new()
  _detect_btn = Button.new()
  _detect_btn.text = "Detect Colors"
  _detect_btn.pressed.connect(_on_detect_pressed)
  detect_row.add_child(_detect_btn)
  _load_mapping_btn = Button.new()
  _load_mapping_btn.text = "Load Mapping..."
  _load_mapping_btn.pressed.connect(_on_load_mapping_pressed)
  detect_row.add_child(_load_mapping_btn)
  vbox.add_child(detect_row)

  # Status
  _detect_status = Label.new()
  _detect_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  vbox.add_child(_detect_status)

  # Mapping entries (populated after detection)
  _mapping_entries_container = VBoxContainer.new()
  vbox.add_child(_mapping_entries_container)

  # Save mapping button (hidden until entries exist)
  _mapping_buttons_row = HBoxContainer.new()
  _mapping_buttons_row.visible = false
  _save_mapping_btn = Button.new()
  _save_mapping_btn.text = "Save Mapping..."
  _save_mapping_btn.pressed.connect(_on_save_mapping_pressed)
  _mapping_buttons_row.add_child(_save_mapping_btn)
  vbox.add_child(_mapping_buttons_row)

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

  _current_mapping = HerringboneColorTileMapping.new()
  _current_mapping.detect_colors_from_image(
    image, _transparency_picker.color,
  )

  var count: int = _current_mapping.entries.size()
  print("PANEL: Detected %d content colors" % count)
  _set_status(
    _detect_status,
    "Found %d content colors" % count,
    "success",
  )
  _rebuild_mapping_ui()


func _on_load_mapping_pressed() -> void:
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_OPEN_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      var res: Resource = ResourceLoader.load(
        path, "", ResourceLoader.CACHE_MODE_IGNORE,
      )
      if not res is HerringboneColorTileMapping:
        _set_status(
          _detect_status,
          "Not a color mapping: %s" % path,
          "error",
        )
        return
      _current_mapping = res as HerringboneColorTileMapping
      _mapping_path = path
      _mapping_line_edit.text = path
      _set_status(
        _detect_status,
        "Loaded mapping with %d entries from %s"
        % [_current_mapping.entries.size(), path],
        "success",
      )
      _rebuild_mapping_ui(),
  )


func _on_save_mapping_pressed() -> void:
  if _current_mapping == null:
    return
  _open_file_dialog(
    EditorFileDialog.FILE_MODE_SAVE_FILE,
    PackedStringArray(["*.tres ; Godot Resource"]),
    func(path: String) -> void:
      var err: int = ResourceSaver.save(_current_mapping, path)
      if err != OK:
        _set_status(
          _detect_status,
          "Failed to save: error %d" % err,
          "error",
        )
        return
      _mapping_path = path
      _mapping_line_edit.text = path
      _set_status(
        _detect_status,
        "Mapping saved to %s" % path,
        "success",
      ),
  )


# -- Mapping entry editor --


func _rebuild_mapping_ui() -> void:
  # Clear existing entry rows
  for child: Node in _mapping_entries_container.get_children():
    child.queue_free()

  if _current_mapping == null or _current_mapping.entries.is_empty():
    _mapping_buttons_row.visible = false
    return

  # Header row
  var header: HBoxContainer = HBoxContainer.new()
  var color_lbl: Label = _create_label("Color")
  color_lbl.custom_minimum_size.x = 80
  header.add_child(color_lbl)
  var tile_lbl: Label = _create_label("Tile")
  tile_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  header.add_child(tile_lbl)
  _mapping_entries_container.add_child(header)

  for i: int in range(_current_mapping.entries.size()):
    var entry: Dictionary = _current_mapping.entries[i]
    var row: HBoxContainer = _build_mapping_entry_row(i, entry)
    _mapping_entries_container.add_child(row)

  _mapping_buttons_row.visible = true


func _build_mapping_entry_row(
  index: int, entry: Dictionary,
) -> HBoxContainer:
  var row: HBoxContainer = HBoxContainer.new()

  # Color swatch
  var swatch: ColorRect = ColorRect.new()
  swatch.color = entry["color"]
  swatch.custom_minimum_size = Vector2(24, 24)
  row.add_child(swatch)

  # Color text
  var color: Color = entry["color"]
  var color_text: Label = _create_label(
    "  #%s" % color.to_html(false),
  )
  color_text.custom_minimum_size.x = 70
  row.add_child(color_text)

  # Tile assignment display
  var tile_label: Label = Label.new()
  tile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  _update_tile_label(tile_label, entry)
  row.add_child(tile_label)

  # Tile preview (small texture showing the assigned tile)
  var preview: TextureRect = TextureRect.new()
  preview.custom_minimum_size = Vector2(24, 24)
  preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  _update_tile_preview(preview, entry)
  row.add_child(preview)

  # Pick tile button
  var pick_btn: Button = Button.new()
  pick_btn.text = "Pick Tile..."
  pick_btn.pressed.connect(
    _on_pick_tile_pressed.bind(index, tile_label, preview),
  )
  row.add_child(pick_btn)

  # Remove button
  var remove_btn: Button = Button.new()
  remove_btn.text = "X"
  remove_btn.custom_minimum_size = Vector2(28, 0)
  remove_btn.pressed.connect(func() -> void:
    _current_mapping.entries.remove_at(index)
    _rebuild_mapping_ui()
  )
  row.add_child(remove_btn)

  return row


func _update_tile_label(label: Label, entry: Dictionary) -> void:
  var sid: int = entry.get("source_id", -1)
  if sid < 0:
    label.text = "(unassigned)"
    label.add_theme_color_override(
      "font_color", Color(1.0, 1.0, 0.4),
    )
  else:
    var coords: Vector2i = entry["atlas_coords"]
    label.text = "src:%d (%d, %d)" % [sid, coords.x, coords.y]
    label.remove_theme_color_override("font_color")


func _update_tile_preview(
  preview: TextureRect, entry: Dictionary,
) -> void:
  var sid: int = entry.get("source_id", -1)
  preview.texture = null
  if sid < 0:
    return
  if not is_instance_valid(_target_layer):
    return
  if _target_layer.tile_set == null:
    return
  var coords: Vector2i = entry["atlas_coords"]
  var tex: Texture2D = _get_tile_icon(
    _target_layer.tile_set, sid, coords,
  )
  preview.texture = tex


func _get_tile_icon(
  tileset: TileSet, source_id: int, atlas_coords: Vector2i,
) -> Texture2D:
  if not tileset.has_source(source_id):
    return null
  var source: TileSetSource = tileset.get_source(source_id)
  if not source is TileSetAtlasSource:
    return null
  var atlas: TileSetAtlasSource = source as TileSetAtlasSource
  if atlas.texture == null:
    return null
  var region: Rect2i = atlas.get_tile_texture_region(atlas_coords)
  var atlas_tex: AtlasTexture = AtlasTexture.new()
  atlas_tex.atlas = atlas.texture
  atlas_tex.region = Rect2(region)
  return atlas_tex


# -- Tile picker popup --


func _on_pick_tile_pressed(
  entry_index: int, tile_label: Label, preview: TextureRect,
) -> void:
  if not is_instance_valid(_target_layer):
    _set_status(
      _detect_status,
      "Select a TileMapLayer first to pick tiles",
      "error",
    )
    return
  if _target_layer.tile_set == null:
    _set_status(
      _detect_status,
      "TileMapLayer has no TileSet assigned",
      "error",
    )
    return

  var tileset: TileSet = _target_layer.tile_set
  var dialog: AcceptDialog = AcceptDialog.new()
  dialog.title = "Pick Tile"
  dialog.min_size = Vector2i(400, 350)

  var vbox: VBoxContainer = VBoxContainer.new()
  dialog.add_child(vbox)

  # Source selector (if multiple sources)
  var source_count: int = tileset.get_source_count()
  var source_option: OptionButton = OptionButton.new()
  for si: int in range(source_count):
    var sid: int = tileset.get_source_id(si)
    var src: TileSetSource = tileset.get_source(sid)
    if src is TileSetAtlasSource:
      source_option.add_item("Source %d" % sid, sid)
  if source_option.item_count > 1:
    var src_row: HBoxContainer = HBoxContainer.new()
    src_row.add_child(_create_label("Source:"))
    src_row.add_child(source_option)
    vbox.add_child(src_row)

  # Tile grid
  var tile_list: ItemList = ItemList.new()
  tile_list.icon_mode = ItemList.ICON_MODE_TOP
  tile_list.max_columns = 0
  tile_list.fixed_icon_size = Vector2i(32, 32)
  tile_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
  tile_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  vbox.add_child(tile_list)

  # Populate tiles for the first source
  var populate_fn: Callable = func(source_id: int) -> void:
    tile_list.clear()
    if not tileset.has_source(source_id):
      return
    var src: TileSetSource = tileset.get_source(source_id)
    if not src is TileSetAtlasSource:
      return
    var atlas: TileSetAtlasSource = src as TileSetAtlasSource
    for ti: int in range(atlas.get_tiles_count()):
      var coords: Vector2i = atlas.get_tile_id(ti)
      var icon: Texture2D = _get_tile_icon(
        tileset, source_id, coords,
      )
      var item_idx: int = tile_list.add_item(
        "(%d,%d)" % [coords.x, coords.y], icon,
      )
      tile_list.set_item_metadata(
        item_idx,
        {"source_id": source_id, "atlas_coords": coords},
      )

  if source_option.item_count > 0:
    var first_id: int = source_option.get_item_id(0)
    populate_fn.call(first_id)
    source_option.item_selected.connect(
      func(idx: int) -> void:
        var sid: int = source_option.get_item_id(idx)
        populate_fn.call(sid)
    )

  # On tile selected, update the mapping entry
  tile_list.item_activated.connect(
    func(item_idx: int) -> void:
      var meta: Dictionary = tile_list.get_item_metadata(item_idx)
      var entry: Dictionary = _current_mapping.entries[entry_index]
      entry["source_id"] = meta["source_id"]
      entry["atlas_coords"] = meta["atlas_coords"]
      _update_tile_label(tile_label, entry)
      _update_tile_preview(preview, entry)
      dialog.queue_free()
  )

  dialog.canceled.connect(dialog.queue_free)
  EditorInterface.get_base_control().add_child(dialog)
  dialog.popup_centered(Vector2i(450, 400))


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

  # Use in-memory mapping if available, otherwise load from file
  var mapping: HerringboneColorTileMapping = _current_mapping
  if mapping == null and _mapping_path != "":
    mapping = ResourceLoader.load(
      _mapping_path, "", ResourceLoader.CACHE_MODE_IGNORE,
    ) as HerringboneColorTileMapping
  if mapping == null:
    _set_status(
      _import_status,
      "No color mapping — detect colors or load a .tres first",
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
