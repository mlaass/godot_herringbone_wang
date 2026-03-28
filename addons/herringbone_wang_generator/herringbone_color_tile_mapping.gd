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


static func _empty_cell() -> Dictionary:
  return {
    "source_id": -1,
    "atlas_coords": Vector2i(-1, -1),
    "alternative_tile": 0,
  }
