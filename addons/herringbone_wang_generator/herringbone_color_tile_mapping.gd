class_name HerringboneColorTileMapping
extends Resource

@export var entries: Array[Dictionary] = []
@export var transparency_color: Color = Color(1, 0, 1, 1)

const COLOR_TOLERANCE: float = 2.0 / 255.0


func find_entry(color: Color) -> Dictionary:
  if _colors_match(color, transparency_color):
    return _empty_cell()
  for entry: Dictionary in entries:
    var entry_color: Color = entry.get("color", Color.BLACK)
    if _colors_match(color, entry_color):
      return entry
  return _empty_cell()


func _colors_match(a: Color, b: Color) -> bool:
  return (
    absf(a.r - b.r) <= COLOR_TOLERANCE
    and absf(a.g - b.g) <= COLOR_TOLERANCE
    and absf(a.b - b.b) <= COLOR_TOLERANCE
  )


func populate_from_atlas(
  texture: Texture2D,
  tile_size: Vector2i,
  source_id: int = 0,
) -> void:
  entries.clear()
  if texture == null:
    return
  var image: Image = texture.get_image()
  if image == null:
    return
  var cols: int = image.get_width() / tile_size.x
  var rows: int = image.get_height() / tile_size.y
  for row: int in range(rows):
    for col: int in range(cols):
      var cx: int = col * tile_size.x + tile_size.x / 2
      var cy: int = row * tile_size.y + tile_size.y / 2
      var color: Color = image.get_pixel(cx, cy)
      if _colors_match(color, transparency_color):
        continue
      entries.append({
        "color": color,
        "source_id": source_id,
        "atlas_coords": Vector2i(col, row),
        "alternative_tile": 0,
      })


func detect_colors_from_image(
  image: Image,
  transparency_col: Color = Color(1, 0, 1, 1),
  tolerance: float = 5.0 / 255.0,
) -> void:
  entries.clear()
  transparency_color = transparency_col
  if image == null:
    return
  var representatives: Array[Color] = []
  for y: int in range(image.get_height()):
    for x: int in range(image.get_width()):
      var color: Color = image.get_pixel(x, y)
      if _colors_within_tolerance(color, transparency_col, tolerance):
        continue
      var found: bool = false
      for rep: Color in representatives:
        if _colors_within_tolerance(color, rep, tolerance):
          found = true
          break
      if found:
        continue
      representatives.append(color)
      entries.append({
        "color": color,
        "source_id": -1,
        "atlas_coords": Vector2i(-1, -1),
        "alternative_tile": 0,
      })


static func _colors_within_tolerance(
  a: Color, b: Color, tol: float,
) -> bool:
  return (
    absf(a.r - b.r) <= tol
    and absf(a.g - b.g) <= tol
    and absf(a.b - b.b) <= tol
  )


static func _empty_cell() -> Dictionary:
  return {
    "source_id": -1,
    "atlas_coords": Vector2i(-1, -1),
    "alternative_tile": 0,
  }
