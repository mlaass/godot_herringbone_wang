extends GutTest

const PINK: Color = Color(1, 0, 1, 1)
const YELLOW: Color = Color(1, 1, 0, 1)
const GREEN: Color = Color(0, 1, 0, 1)
const BLACK: Color = Color(0, 0, 0, 1)
const WHITE: Color = Color(1, 1, 1, 1)

var _importer: HerringboneChunkImporter
var _mapping: HerringboneColorTileMapping


func before_each() -> void:
  _importer = HerringboneChunkImporter.new()
  _mapping = HerringboneColorTileMapping.new()
  _mapping.transparency_color = PINK
  _mapping.entries = [
    {
      "color": BLACK,
      "source_id": 0,
      "atlas_coords": Vector2i(0, 0),
      "alternative_tile": 0,
    },
    {
      "color": WHITE,
      "source_id": 0,
      "atlas_coords": Vector2i(1, 0),
      "alternative_tile": 0,
    },
  ]


func _create_v_tile_image(
  n: int,
  constraint_colors: Array[Color],
) -> Image:
  # V tile slot: (N+2) wide x (2N+4) tall
  # Border: 1px left/right, 2px top/bottom
  # Content: N x 2N at offset (1, 2)
  var w: int = n + 2
  var h: int = 2 * n + 4
  var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
  img.fill(PINK)

  # Fill content area with black
  for y: int in range(2, 2 + 2 * n):
    for x: int in range(1, 1 + n):
      img.set_pixel(x, y, BLACK)

  # Place 6 constraint pixels in V tile border area:
  # a = top edge (in row 1, center x)
  var mid_x: int = w / 2
  img.set_pixel(mid_x, 1, constraint_colors[0])
  # b = left upper
  var upper_y: int = 2 + n / 2
  img.set_pixel(0, upper_y, constraint_colors[1])
  # c = left lower
  var lower_y: int = 2 + 3 * n / 2
  img.set_pixel(0, lower_y, constraint_colors[2])
  # d = bottom edge (in row h-2, center x)
  img.set_pixel(mid_x, h - 2, constraint_colors[3])
  # e = right upper
  img.set_pixel(w - 1, upper_y, constraint_colors[4])
  # f = right lower
  img.set_pixel(w - 1, lower_y, constraint_colors[5])

  return img


func _create_h_tile_image(
  n: int,
  constraint_colors: Array[Color],
) -> Image:
  # H tile slot: (2N+4) wide x (N+2) tall
  # Border: 2px left/right, 1px top/bottom
  # Content: 2N x N at offset (2, 1)
  var w: int = 2 * n + 4
  var h: int = n + 2
  var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
  img.fill(PINK)

  # Fill content area with white
  for y: int in range(1, 1 + n):
    for x: int in range(2, 2 + 2 * n):
      img.set_pixel(x, y, WHITE)

  # Place 6 constraint pixels in H tile border area:
  # a = left edge (in col 1, center y)
  var mid_y: int = h / 2
  img.set_pixel(1, mid_y, constraint_colors[0])
  # b = top left
  var left_x: int = 2 + n / 2
  img.set_pixel(left_x, 0, constraint_colors[1])
  # c = top right
  var right_x: int = 2 + 3 * n / 2
  img.set_pixel(right_x, 0, constraint_colors[2])
  # d = right edge (in col w-2, center y)
  img.set_pixel(w - 2, mid_y, constraint_colors[3])
  # e = bottom left
  img.set_pixel(left_x, h - 1, constraint_colors[4])
  # f = bottom right
  img.set_pixel(right_x, h - 1, constraint_colors[5])

  return img


func test_error_on_null_image() -> void:
  var result: Dictionary = _importer.import_chunk_map(
    null, 10, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 22), 1, 1,
    _mapping,
  )
  assert_false(result["success"])
  assert_true(result["errors"].size() > 0)


func test_error_on_zero_side_len() -> void:
  var img: Image = Image.create(10, 10, false, Image.FORMAT_RGB8)
  var result: Dictionary = _importer.import_chunk_map(
    img, 0, PINK,
    Vector2i(0, 0), 0, 0,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_false(result["success"])


func test_result_structure() -> void:
  var img: Image = Image.create(10, 10, false, Image.FORMAT_RGB8)
  img.fill(PINK)
  var result: Dictionary = _importer.import_chunk_map(
    img, 2, PINK,
    Vector2i(0, 0), 0, 0,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_has(result, "success")
  assert_has(result, "macro_set")
  assert_has(result, "errors")
  assert_has(result, "warnings")
  assert_has(result, "tiles_imported")
  assert_has(result, "tiles_skipped")
  assert_has(result, "unique_content_colors")
  assert_has(result, "unique_constraint_colors")


func test_import_single_v_tile() -> void:
  var n: int = 4
  var colors: Array[Color] = [
    YELLOW, GREEN, YELLOW, GREEN, YELLOW, GREEN,
  ]
  var img: Image = _create_v_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_true(result["success"])
  assert_eq(result["tiles_imported"], 1)
  assert_eq(result["tiles_skipped"], 0)

  var ms: HerringboneMacroSet = result["macro_set"]
  assert_eq(ms.v_tiles.size(), 1)
  assert_eq(ms.h_tiles.size(), 0)

  var tile: HerringboneMacroData = ms.v_tiles[0]
  assert_eq(tile.width, n)
  assert_eq(tile.height, 2 * n)
  assert_eq(tile.constraints.size(), 6)


func test_import_single_h_tile() -> void:
  var n: int = 4
  var colors: Array[Color] = [
    YELLOW, GREEN, YELLOW, GREEN, YELLOW, GREEN,
  ]
  var img: Image = _create_h_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 0, 0,
    Vector2i(0, 0), 1, 1,
    _mapping,
  )
  assert_true(result["success"])
  assert_eq(result["tiles_imported"], 1)

  var ms: HerringboneMacroSet = result["macro_set"]
  assert_eq(ms.h_tiles.size(), 1)

  var tile: HerringboneMacroData = ms.h_tiles[0]
  assert_eq(tile.width, 2 * n)
  assert_eq(tile.height, n)


func test_constraint_color_assignment() -> void:
  var n: int = 4
  # All yellow constraints
  var colors: Array[Color] = [
    YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW,
  ]
  var img: Image = _create_v_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_eq(result["unique_constraint_colors"], 1)
  var tile: HerringboneMacroData = result["macro_set"].v_tiles[0]
  # All constraints should be 0 (first color seen)
  for i: int in range(6):
    assert_eq(tile.constraints[i], 0, "constraint %d should be 0" % i)


func test_two_constraint_colors() -> void:
  var n: int = 4
  var colors: Array[Color] = [
    YELLOW, GREEN, YELLOW, GREEN, YELLOW, GREEN,
  ]
  var img: Image = _create_v_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_eq(result["unique_constraint_colors"], 2)
  var tile: HerringboneMacroData = result["macro_set"].v_tiles[0]
  # Alternating: first color = 0, second color = 1
  assert_eq(tile.constraints[0], 0)  # yellow
  assert_eq(tile.constraints[1], 1)  # green
  assert_eq(tile.constraints[2], 0)  # yellow
  assert_eq(tile.constraints[3], 1)  # green


func test_content_extraction() -> void:
  var n: int = 4
  var colors: Array[Color] = [
    YELLOW, YELLOW, YELLOW, YELLOW, YELLOW, YELLOW,
  ]
  var img: Image = _create_v_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  var tile: HerringboneMacroData = result["macro_set"].v_tiles[0]
  # Interior was filled with BLACK, which maps to source_id=0, atlas=(0,0)
  var cell: Dictionary = tile.cells[0]
  assert_eq(cell["source_id"], 0)
  assert_eq(cell["atlas_coords"], Vector2i(0, 0))


func test_wrong_constraint_count_skips_tile() -> void:
  var n: int = 4
  var w: int = n + 2
  var h: int = 2 * n + 4
  var img: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
  img.fill(PINK)
  # Only place 3 constraint pixels instead of 6
  img.set_pixel(w / 2, 1, YELLOW)
  img.set_pixel(0, 2 + n / 2, YELLOW)
  img.set_pixel(w / 2, h - 2, YELLOW)
  # Fill content area
  for y: int in range(2, 2 + 2 * n):
    for x: int in range(1, 1 + n):
      img.set_pixel(x, y, BLACK)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  assert_true(result["success"])
  assert_eq(result["tiles_imported"], 0)
  assert_eq(result["tiles_skipped"], 1)
  assert_true(result["warnings"].size() > 0)


func test_macro_set_is_edge_mode() -> void:
  var n: int = 4
  var colors: Array[Color] = [
    YELLOW, GREEN, YELLOW, GREEN, YELLOW, GREEN,
  ]
  var img: Image = _create_v_tile_image(n, colors)

  var result: Dictionary = _importer.import_chunk_map(
    img, n, PINK,
    Vector2i(0, 0), 1, 1,
    Vector2i(0, 0), 0, 0,
    _mapping,
  )
  var ms: HerringboneMacroSet = result["macro_set"]
  assert_false(ms.is_corner, "imported set should be edge mode")
  assert_eq(ms.num_colors.size(), 6)
  assert_eq(ms.base_unit_size, n)
