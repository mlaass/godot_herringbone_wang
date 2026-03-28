@tool
class_name HerringboneChunkImporter
extends RefCounted

const COLOR_TOLERANCE: float = 5.0 / 255.0

var _constraint_color_map: Dictionary = {}
var _next_constraint_id: int = 0
var _content_colors_seen: Dictionary = {}


func import_chunk_map(
  chunk_map: Image,
  short_side_len: int,
  transparency_color: Color,
  v_section_origin: Vector2i,
  v_section_cols: int,
  v_section_rows: int,
  h_section_origin: Vector2i,
  h_section_cols: int,
  h_section_rows: int,
  color_mapping: HerringboneColorTileMapping,
) -> Dictionary:
  _reset()

  var errors: PackedStringArray = PackedStringArray()
  var warnings: PackedStringArray = PackedStringArray()

  if chunk_map == null:
    errors.append("chunk_map is null")
    return _make_result(false, null, errors, warnings, 0, 0, 0, 0)

  if short_side_len < 1:
    errors.append("short_side_len must be >= 1")
    return _make_result(false, null, errors, warnings, 0, 0, 0, 0)

  var v_tiles: Array[HerringboneMacroData] = _extract_tiles_from_section(
    chunk_map, v_section_origin, v_section_cols, v_section_rows,
    HerringboneMacroData.Orientation.VERTICAL,
    short_side_len, transparency_color, color_mapping,
    errors, warnings,
  )

  var h_tiles: Array[HerringboneMacroData] = _extract_tiles_from_section(
    chunk_map, h_section_origin, h_section_cols, h_section_rows,
    HerringboneMacroData.Orientation.HORIZONTAL,
    short_side_len, transparency_color, color_mapping,
    errors, warnings,
  )

  var tid: int = 0
  for tile: HerringboneMacroData in v_tiles:
    tile.tile_id = tid % 255
    tid += 1
  for tile: HerringboneMacroData in h_tiles:
    tile.tile_id = tid % 255
    tid += 1

  var macro_set: HerringboneMacroSet = HerringboneMacroSet.new()
  macro_set.is_corner = false
  macro_set.base_unit_size = short_side_len
  macro_set.num_colors = _derive_num_colors(h_tiles, v_tiles)
  macro_set.h_tiles = h_tiles
  macro_set.v_tiles = v_tiles

  var total_expected: int = (
    v_section_cols * v_section_rows + h_section_cols * h_section_rows
  )
  var imported: int = h_tiles.size() + v_tiles.size()
  var skipped: int = total_expected - imported

  return _make_result(
    errors.is_empty(), macro_set, errors, warnings,
    imported, skipped,
    _content_colors_seen.size(), _next_constraint_id,
  )


func _reset() -> void:
  _constraint_color_map = {}
  _next_constraint_id = 0
  _content_colors_seen = {}


func _extract_tiles_from_section(
  image: Image,
  origin: Vector2i,
  cols: int,
  rows: int,
  orientation: int,
  short_side_len: int,
  transparency_color: Color,
  color_mapping: HerringboneColorTileMapping,
  errors: PackedStringArray,
  warnings: PackedStringArray,
) -> Array[HerringboneMacroData]:
  var n: int = short_side_len
  var slot_w: int = 0
  var slot_h: int = 0
  if orientation == HerringboneMacroData.Orientation.VERTICAL:
    # Short side (width): N+2 (1px border each side)
    # Long side (height): 2N+4 (2px border top + bottom)
    slot_w = n + 2
    slot_h = 2 * n + 4
  else:
    # Long side (width): 2N+4 (2px border left + right)
    # Short side (height): N+2 (1px border top + bottom)
    slot_w = 2 * n + 4
    slot_h = n + 2

  var tiles: Array[HerringboneMacroData] = []
  var tile_index: int = 0
  for row: int in range(rows):
    for col: int in range(cols):
      var slot_x: int = origin.x + col * slot_w
      var slot_y: int = origin.y + row * slot_h
      var tile: HerringboneMacroData = _extract_single_tile(
        image, slot_x, slot_y, slot_w, slot_h,
        orientation, short_side_len, transparency_color,
        color_mapping, tile_index, warnings,
      )
      if tile != null:
        tiles.append(tile)
      tile_index += 1
  return tiles


func _extract_single_tile(
  image: Image,
  slot_x: int,
  slot_y: int,
  slot_w: int,
  slot_h: int,
  orientation: int,
  short_side_len: int,
  transparency_color: Color,
  color_mapping: HerringboneColorTileMapping,
  tile_index: int,
  warnings: PackedStringArray,
) -> HerringboneMacroData:
  var border_pixels: Array[Dictionary] = _scan_border_area(
    image, slot_x, slot_y, slot_w, slot_h, orientation,
    transparency_color,
  )

  if border_pixels.size() != 6:
    var orient_str: String = (
      "V" if orientation == HerringboneMacroData.Orientation.VERTICAL
      else "H"
    )
    warnings.append(
      "%s tile %d: expected 6 constraint pixels, found %d — skipped"
      % [orient_str, tile_index, border_pixels.size()]
    )
    return null

  var constraints: PackedInt32Array = _classify_and_order_constraints(
    border_pixels, orientation,
  )

  var n: int = short_side_len
  var content_w: int = 0
  var content_h: int = 0
  var content_x_offset: int = 0
  var content_y_offset: int = 0
  if orientation == HerringboneMacroData.Orientation.VERTICAL:
    content_w = n
    content_h = 2 * n
    content_x_offset = 1
    content_y_offset = 2
  else:
    content_w = 2 * n
    content_h = n
    content_x_offset = 2
    content_y_offset = 1
  var cells: Array[Dictionary] = _extract_content(
    image, slot_x + content_x_offset, slot_y + content_y_offset,
    content_w, content_h, color_mapping,
  )

  var tile: HerringboneMacroData = HerringboneMacroData.new()
  tile.orientation = orientation
  tile.tile_id = 0
  tile.constraints = constraints
  tile.width = content_w
  tile.height = content_h
  tile.cells = cells
  return tile


func _scan_border_area(
  image: Image,
  slot_x: int,
  slot_y: int,
  slot_w: int,
  slot_h: int,
  orientation: int,
  transparency_color: Color,
) -> Array[Dictionary]:
  var pixels: Array[Dictionary] = []
  # Border widths differ by orientation:
  #   V tiles: 1px on short sides (left/right), 2px on long sides (top/bottom)
  #   H tiles: 2px on long sides (left/right), 1px on short sides (top/bottom)
  var top_border: int = 0
  var bottom_border: int = 0
  var left_border: int = 0
  var right_border: int = 0
  if orientation == HerringboneMacroData.Orientation.VERTICAL:
    left_border = 1
    right_border = 1
    top_border = 2
    bottom_border = 2
  else:
    left_border = 2
    right_border = 2
    top_border = 1
    bottom_border = 1

  var content_x0: int = slot_x + left_border
  var content_y0: int = slot_y + top_border
  var content_x1: int = slot_x + slot_w - right_border - 1
  var content_y1: int = slot_y + slot_h - bottom_border - 1

  # Top border area
  for by: int in range(slot_y, content_y0):
    for bx: int in range(slot_x, slot_x + slot_w):
      var color: Color = image.get_pixel(bx, by)
      if not _colors_match(color, transparency_color):
        pixels.append({"color": color, "edge": "top", "pos": bx - slot_x})

  # Bottom border area
  for by: int in range(content_y1 + 1, slot_y + slot_h):
    for bx: int in range(slot_x, slot_x + slot_w):
      var color: Color = image.get_pixel(bx, by)
      if not _colors_match(color, transparency_color):
        pixels.append({"color": color, "edge": "bottom", "pos": bx - slot_x})

  # Left border area (excluding corners already scanned)
  for by: int in range(content_y0, content_y1 + 1):
    for bx: int in range(slot_x, content_x0):
      var color: Color = image.get_pixel(bx, by)
      if not _colors_match(color, transparency_color):
        pixels.append({"color": color, "edge": "left", "pos": by - slot_y})

  # Right border area (excluding corners already scanned)
  for by: int in range(content_y0, content_y1 + 1):
    for bx: int in range(content_x1 + 1, slot_x + slot_w):
      var color: Color = image.get_pixel(bx, by)
      if not _colors_match(color, transparency_color):
        pixels.append({"color": color, "edge": "right", "pos": by - slot_y})

  return pixels


func _classify_and_order_constraints(
  border_pixels: Array[Dictionary],
  orientation: int,
) -> PackedInt32Array:
  var by_edge: Dictionary = {
    "top": [] as Array[Dictionary],
    "bottom": [] as Array[Dictionary],
    "left": [] as Array[Dictionary],
    "right": [] as Array[Dictionary],
  }

  for px: Dictionary in border_pixels:
    var edge: String = px["edge"]
    by_edge[edge].append(px)

  # Sort each edge by position
  for edge: String in by_edge:
    var arr: Array[Dictionary] = by_edge[edge]
    arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
      var pa: int = a["pos"]
      var pb: int = b["pos"]
      return pa < pb
    )

  var constraints: PackedInt32Array = PackedInt32Array()
  constraints.resize(6)

  if orientation == HerringboneMacroData.Orientation.VERTICAL:
    # PRD canonical: [top, left-upper, left-lower, bottom, right-upper,
    #                 right-lower]
    var top: Array[Dictionary] = by_edge["top"]
    var bottom: Array[Dictionary] = by_edge["bottom"]
    var left: Array[Dictionary] = by_edge["left"]
    var right: Array[Dictionary] = by_edge["right"]
    constraints[0] = _get_or_assign_constraint_id(top[0]["color"])
    constraints[1] = _get_or_assign_constraint_id(left[0]["color"])
    constraints[2] = _get_or_assign_constraint_id(left[1]["color"])
    constraints[3] = _get_or_assign_constraint_id(bottom[0]["color"])
    constraints[4] = _get_or_assign_constraint_id(right[0]["color"])
    constraints[5] = _get_or_assign_constraint_id(right[1]["color"])
  else:
    # PRD canonical: [left, top-left, top-right, right, bottom-left,
    #                 bottom-right]
    var top: Array[Dictionary] = by_edge["top"]
    var bottom: Array[Dictionary] = by_edge["bottom"]
    var left: Array[Dictionary] = by_edge["left"]
    var right: Array[Dictionary] = by_edge["right"]
    constraints[0] = _get_or_assign_constraint_id(left[0]["color"])
    constraints[1] = _get_or_assign_constraint_id(top[0]["color"])
    constraints[2] = _get_or_assign_constraint_id(top[1]["color"])
    constraints[3] = _get_or_assign_constraint_id(right[0]["color"])
    constraints[4] = _get_or_assign_constraint_id(bottom[0]["color"])
    constraints[5] = _get_or_assign_constraint_id(bottom[1]["color"])

  return constraints


func _get_or_assign_constraint_id(color: Color) -> int:
  for key: Variant in _constraint_color_map:
    var kc: Color = key as Color
    if _colors_match(color, kc):
      var id: int = _constraint_color_map[kc]
      return id
  _constraint_color_map[color] = _next_constraint_id
  var assigned: int = _next_constraint_id
  _next_constraint_id += 1
  return assigned


func _extract_content(
  image: Image,
  content_x: int,
  content_y: int,
  content_w: int,
  content_h: int,
  color_mapping: HerringboneColorTileMapping,
) -> Array[Dictionary]:
  var cells: Array[Dictionary] = []
  cells.resize(content_w * content_h)
  for cy: int in range(content_h):
    for cx: int in range(content_w):
      var px: int = content_x + cx
      var py: int = content_y + cy
      var color: Color = image.get_pixel(px, py)
      _content_colors_seen[color] = true
      var entry: Dictionary = color_mapping.find_entry(color)
      cells[cy * content_w + cx] = entry
  return cells


func _derive_num_colors(
  h_tiles: Array[HerringboneMacroData],
  v_tiles: Array[HerringboneMacroData],
) -> PackedInt32Array:
  # Track max constraint value seen at each position for each orientation,
  # then map to edge types to determine per-type color count.
  #
  # H tile PRD positions -> edge types: [1, 2, 3, 4, 0, 2]
  # V tile PRD positions -> edge types: [0, 5, 4, 3, 1, 5]
  var h_type_map: Array[int] = [1, 2, 3, 4, 0, 2]
  var v_type_map: Array[int] = [0, 5, 4, 3, 1, 5]

  var max_per_type: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])

  for tile: HerringboneMacroData in h_tiles:
    for i: int in range(6):
      var edge_type: int = h_type_map[i]
      var val: int = tile.constraints[i] + 1
      if val > max_per_type[edge_type]:
        max_per_type[edge_type] = val

  for tile: HerringboneMacroData in v_tiles:
    for i: int in range(6):
      var edge_type: int = v_type_map[i]
      var val: int = tile.constraints[i] + 1
      if val > max_per_type[edge_type]:
        max_per_type[edge_type] = val

  return max_per_type


func _colors_match(a: Color, b: Color) -> bool:
  return (
    absf(a.r - b.r) <= COLOR_TOLERANCE
    and absf(a.g - b.g) <= COLOR_TOLERANCE
    and absf(a.b - b.b) <= COLOR_TOLERANCE
  )


static func _make_result(
  success: bool,
  macro_set: HerringboneMacroSet,
  errors: PackedStringArray,
  warnings: PackedStringArray,
  tiles_imported: int,
  tiles_skipped: int,
  unique_content_colors: int,
  unique_constraint_colors: int,
) -> Dictionary:
  return {
    "success": success,
    "macro_set": macro_set,
    "errors": errors,
    "warnings": warnings,
    "tiles_imported": tiles_imported,
    "tiles_skipped": tiles_skipped,
    "unique_content_colors": unique_content_colors,
    "unique_constraint_colors": unique_constraint_colors,
  }
