@tool
class_name HerringboneAuthoringLayer
extends TileMapLayer

@export var catalog: HerringboneConstraintCatalog:
  set(value):
    catalog = value
    _rebuild_grid()
    queue_redraw()

@export var base_unit_size: int = 4:
  set(value):
    base_unit_size = maxi(1, value)
    _rebuild_grid()
    queue_redraw()

@export var grid_columns: int = 8:
  set(value):
    grid_columns = maxi(1, value)
    _rebuild_grid()
    queue_redraw()

@export var constraint_colors: Array[Color] = [
  Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
]:
  set(value):
    constraint_colors = value
    queue_redraw()

@export var show_grid: bool = true:
  set(value):
    show_grid = value
    queue_redraw()

var _macro_constraints: Dictionary = {}
var _grid_rects: Array[Dictionary] = []


func _ready() -> void:
  _rebuild_grid()


func _get_configuration_warnings() -> PackedStringArray:
  var warnings: PackedStringArray = PackedStringArray()
  if catalog == null:
    warnings.append("No HerringboneConstraintCatalog assigned")
  if tile_set == null:
    warnings.append("No TileSet assigned")
  return warnings


func _rebuild_grid() -> void:
  _grid_rects.clear()
  if catalog == null:
    return

  var n: int = base_unit_size
  var h_w: int = 2 * n
  var h_h: int = n
  var v_w: int = n
  var v_h: int = 2 * n

  var missing_h: Array[PackedInt32Array] = []
  var missing_v: Array[PackedInt32Array] = []

  var ms: HerringboneMacroSet = catalog.create_empty_macro_set(base_unit_size)
  missing_h = ms.get_missing_h_constraints()
  missing_v = ms.get_missing_v_constraints()

  var col: int = 0
  var row_y: int = 0
  var row_max_h: int = 0

  for combo: PackedInt32Array in missing_h:
    if col >= grid_columns:
      col = 0
      row_y += row_max_h + 1
      row_max_h = 0
    _grid_rects.append({
      "x": col * (h_w + 1),
      "y": row_y,
      "w": h_w,
      "h": h_h,
      "orientation": HerringboneMacroData.Orientation.HORIZONTAL,
      "constraints": combo,
    })
    row_max_h = maxi(row_max_h, h_h)
    col += 1

  if col > 0:
    col = 0
    row_y += row_max_h + 1
    row_max_h = 0

  for combo: PackedInt32Array in missing_v:
    if col >= grid_columns:
      col = 0
      row_y += row_max_h + 1
      row_max_h = 0
    _grid_rects.append({
      "x": col * (v_w + 1),
      "y": row_y,
      "w": v_w,
      "h": v_h,
      "orientation": HerringboneMacroData.Orientation.VERTICAL,
      "constraints": combo,
    })
    row_max_h = maxi(row_max_h, v_h)
    col += 1


func _draw() -> void:
  if not show_grid:
    return
  if tile_set == null:
    return
  var cell_size: Vector2 = Vector2(tile_set.tile_size)
  for rect: Dictionary in _grid_rects:
    var pos: Vector2 = Vector2(rect["x"], rect["y"]) * cell_size
    var size: Vector2 = Vector2(rect["w"], rect["h"]) * cell_size
    draw_rect(Rect2(pos, size), Color.WHITE, false, 2.0)

    var cons: PackedInt32Array = rect["constraints"]
    var orient: int = rect["orientation"]
    _draw_constraint_vertices(pos, size, cons, orient, cell_size)


func _draw_constraint_vertices(
  pos: Vector2,
  size: Vector2,
  cons: PackedInt32Array,
  orient: int,
  cell_size: Vector2,
) -> void:
  if cons.size() != 6:
    return

  var radius: float = minf(cell_size.x, cell_size.y) * 0.3
  var positions: Array[Vector2] = _get_vertex_positions(pos, size, orient)

  for i: int in range(mini(6, positions.size())):
    var color_idx: int = cons[i]
    var color: Color = Color.GRAY
    if color_idx >= 0 and color_idx < constraint_colors.size():
      color = constraint_colors[color_idx]
    draw_circle(positions[i], radius, color)


func _get_vertex_positions(
  pos: Vector2,
  size: Vector2,
  orient: int,
) -> Array[Vector2]:
  var verts: Array[Vector2] = []
  if orient == HerringboneMacroData.Orientation.HORIZONTAL:
    # a---b---c
    # |       |
    # d---e---f
    verts.append(pos)
    verts.append(pos + Vector2(size.x * 0.5, 0))
    verts.append(pos + Vector2(size.x, 0))
    verts.append(pos + Vector2(0, size.y))
    verts.append(pos + Vector2(size.x * 0.5, size.y))
    verts.append(pos + size)
  else:
    # a---d
    # |   |
    # b   e
    # |   |
    # c---f
    verts.append(pos)
    verts.append(pos + Vector2(0, size.y * 0.5))
    verts.append(pos + Vector2(0, size.y))
    verts.append(pos + Vector2(size.x, 0))
    verts.append(pos + Vector2(size.x, size.y * 0.5))
    verts.append(pos + size)
  return verts


func bake_macro_set() -> HerringboneMacroSet:
  if catalog == null:
    return null
  if tile_set == null:
    return null

  var ms: HerringboneMacroSet = catalog.create_empty_macro_set(base_unit_size)
  var tile_id: int = 0

  for rect: Dictionary in _grid_rects:
    var data: HerringboneMacroData = HerringboneMacroData.new()
    data.orientation = rect["orientation"]
    data.constraints = rect["constraints"]
    data.tile_id = tile_id
    data.init_cells(rect["w"], rect["h"])

    var rx: int = rect["x"]
    var ry: int = rect["y"]
    for cy: int in range(rect["h"]):
      for cx: int in range(rect["w"]):
        var map_x: int = rx + cx
        var map_y: int = ry + cy
        var src: int = get_cell_source_id(Vector2i(map_x, map_y))
        var atlas: Vector2i = get_cell_atlas_coords(Vector2i(map_x, map_y))
        var alt: int = get_cell_alternative_tile(Vector2i(map_x, map_y))
        data.set_cell(cx, cy, {
          "source_id": src,
          "atlas_coords": atlas,
          "alternative_tile": alt,
        })

    if data.orientation == HerringboneMacroData.Orientation.HORIZONTAL:
      ms.h_tiles.append(data)
    else:
      ms.v_tiles.append(data)
    tile_id = (tile_id + 1) % 255

  return ms


static func populate_tilemap(
  target: TileMapLayer,
  abstract_map: Array,
  macro_set: HerringboneMacroSet,
  fallback_cell: Dictionary = {},
) -> void:
  if target == null or macro_set == null:
    return

  var n: int = macro_set.base_unit_size
  var has_fallback: bool = fallback_cell.has("source_id")

  for i: int in range(abstract_map.size()):
    var entry: Dictionary = abstract_map[i]
    var tile_id: int = entry["tile_id"]
    var orient: int = entry["orientation"]
    var gx: int = entry["grid_x"]
    var gy: int = entry["grid_y"]

    var tiles: Array[HerringboneMacroData] = (
      macro_set.h_tiles
      if orient == HerringboneMacroData.Orientation.HORIZONTAL
      else macro_set.v_tiles
    )

    var data: HerringboneMacroData = null
    for t: HerringboneMacroData in tiles:
      if t.tile_id == tile_id:
        data = t
        break

    var base_x: int = gx * n
    var base_y: int = gy * n

    if data == null:
      if has_fallback:
        var tw: int = 2 * n if orient == 0 else n
        var th: int = n if orient == 0 else 2 * n
        var fb_src: int = fallback_cell.get("source_id", 0)
        var fb_atlas: Vector2i = fallback_cell.get(
          "atlas_coords", Vector2i(0, 0),
        )
        var fb_alt: int = fallback_cell.get("alternative_tile", 0)
        for cy: int in range(th):
          for cx: int in range(tw):
            target.set_cell(
              Vector2i(base_x + cx, base_y + cy),
              fb_src, fb_atlas, fb_alt,
            )
      continue

    for cy: int in range(data.height):
      for cx: int in range(data.width):
        var cell: Dictionary = data.get_cell(cx, cy)
        var src_id: int = cell.get("source_id", -1)
        if src_id < 0:
          continue
        var atlas: Vector2i = cell.get("atlas_coords", Vector2i(-1, -1))
        var alt: int = cell.get("alternative_tile", 0)
        target.set_cell(
          Vector2i(base_x + cx, base_y + cy),
          src_id,
          atlas,
          alt,
        )
