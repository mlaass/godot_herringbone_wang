extends SceneTree

## Run once to generate the 2-tile atlas texture for the dungeon example.
## Usage: godot46 --headless --script res://example/generate_atlas.gd
##
## Tile (0,0): wall — center pixel is pure black (matches Barrett's chunks)
## Tile (1,0): floor — center pixel is pure white (matches Barrett's chunks)


func _init() -> void:
  var size: int = 8
  var img: Image = Image.create(size * 2, size, false, Image.FORMAT_RGB8)

  # Tile (0,0): wall — dark with black center
  var wall_dark: Color = Color(0.12, 0.10, 0.15, 1)
  var wall_center: Color = Color(0, 0, 0, 1)
  for y: int in range(size):
    for x: int in range(size):
      img.set_pixel(x, y, wall_dark)
  # Black center region (positions 2-5 in both axes)
  for y: int in range(2, 6):
    for x: int in range(2, 6):
      img.set_pixel(x, y, wall_center)

  # Tile (1,0): floor — light with white center
  var floor_edge: Color = Color(0.75, 0.68, 0.55, 1)
  var floor_center: Color = Color(1, 1, 1, 1)
  for y: int in range(size):
    for x: int in range(size, size * 2):
      img.set_pixel(x, y, floor_edge)
  # White center region
  for y: int in range(2, 6):
    for x: int in range(size + 2, size + 6):
      img.set_pixel(x, y, floor_center)

  var path: String = ProjectSettings.globalize_path(
    "res://example/dungeon_tiles.png"
  )
  img.save_png(path)
  print("Saved atlas to %s" % path)
  quit()
