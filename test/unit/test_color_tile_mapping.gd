extends GutTest

var _mapping: HerringboneColorTileMapping


func before_each() -> void:
  _mapping = HerringboneColorTileMapping.new()
  _mapping.entries = [
    {
      "color": Color(0, 0, 0, 1),
      "source_id": 0,
      "atlas_coords": Vector2i(0, 0),
      "alternative_tile": 0,
    },
    {
      "color": Color(1, 1, 1, 1),
      "source_id": 0,
      "atlas_coords": Vector2i(1, 0),
      "alternative_tile": 0,
    },
  ]


func test_default_transparency_color() -> void:
  var m: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
  assert_eq(m.transparency_color, Color(1, 0, 1, 1))


func test_find_entry_exact_match() -> void:
  var result: Dictionary = _mapping.find_entry(Color(0, 0, 0, 1))
  assert_eq(result["source_id"], 0)
  assert_eq(result["atlas_coords"], Vector2i(0, 0))


func test_find_entry_white() -> void:
  var result: Dictionary = _mapping.find_entry(Color(1, 1, 1, 1))
  assert_eq(result["atlas_coords"], Vector2i(1, 0))


func test_find_entry_tolerance() -> void:
  # Offset by 1/255 per channel — within tolerance
  var offset: float = 1.0 / 255.0
  var color: Color = Color(offset, offset, offset, 1)
  var result: Dictionary = _mapping.find_entry(color)
  assert_eq(result["source_id"], 0, "should match black within tolerance")
  assert_eq(result["atlas_coords"], Vector2i(0, 0))


func test_find_entry_beyond_tolerance() -> void:
  # Offset by 3/255 per channel — beyond tolerance
  var offset: float = 3.0 / 255.0
  var color: Color = Color(offset, offset, offset, 1)
  var result: Dictionary = _mapping.find_entry(color)
  assert_eq(result["source_id"], -1, "should not match beyond tolerance")


func test_transparency_returns_empty() -> void:
  var result: Dictionary = _mapping.find_entry(Color(1, 0, 1, 1))
  assert_eq(result["source_id"], -1)
  assert_eq(result["atlas_coords"], Vector2i(-1, -1))


func test_transparency_within_tolerance() -> void:
  var offset: float = 1.0 / 255.0
  var color: Color = Color(1.0 - offset, offset, 1.0 - offset, 1)
  var result: Dictionary = _mapping.find_entry(color)
  assert_eq(result["source_id"], -1, "near-pink should still be transparent")


func test_missing_color_returns_empty() -> void:
  var result: Dictionary = _mapping.find_entry(Color(0.5, 0.5, 0, 1))
  assert_eq(result["source_id"], -1)
  assert_eq(result["alternative_tile"], 0)


func test_empty_cell_structure() -> void:
  var cell: Dictionary = HerringboneColorTileMapping._empty_cell()
  assert_eq(cell["source_id"], -1)
  assert_eq(cell["atlas_coords"], Vector2i(-1, -1))
  assert_eq(cell["alternative_tile"], 0)


func test_custom_transparency_color() -> void:
  _mapping.transparency_color = Color(0, 1, 0, 1)
  # Green is now transparent
  var result: Dictionary = _mapping.find_entry(Color(0, 1, 0, 1))
  assert_eq(result["source_id"], -1)
  # Pink is no longer transparent — but also not in entries, so still empty
  var pink: Dictionary = _mapping.find_entry(Color(1, 0, 1, 1))
  assert_eq(pink["source_id"], -1)


func test_populate_from_atlas() -> void:
  # Create a 2-tile atlas: 8x4 image, tile_size 4x4
  # Tile (0,0) center = red, tile (1,0) center = blue
  var img: Image = Image.create(8, 4, false, Image.FORMAT_RGB8)
  img.fill(Color(0.5, 0.5, 0.5, 1))
  img.set_pixel(2, 2, Color(1, 0, 0, 1))  # tile (0,0) center
  img.set_pixel(6, 2, Color(0, 0, 1, 1))  # tile (1,0) center
  var tex: ImageTexture = ImageTexture.create_from_image(img)

  var m: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
  m.populate_from_atlas(tex, Vector2i(4, 4), 0)
  assert_eq(m.entries.size(), 2)

  var e0: Dictionary = m.entries[0]
  assert_eq(e0["atlas_coords"], Vector2i(0, 0))
  assert_eq(e0["color"], Color(1, 0, 0, 1))
  assert_eq(e0["source_id"], 0)

  var e1: Dictionary = m.entries[1]
  assert_eq(e1["atlas_coords"], Vector2i(1, 0))
  assert_eq(e1["color"], Color(0, 0, 1, 1))


func test_populate_from_atlas_skips_transparency() -> void:
  # Tile (0,0) center = pink (transparent), tile (1,0) center = green
  var img: Image = Image.create(8, 4, false, Image.FORMAT_RGB8)
  img.fill(Color(0.5, 0.5, 0.5, 1))
  img.set_pixel(2, 2, Color(1, 0, 1, 1))  # pink = transparent
  img.set_pixel(6, 2, Color(0, 1, 0, 1))  # green

  var m: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
  var tex: ImageTexture = ImageTexture.create_from_image(img)
  m.populate_from_atlas(tex, Vector2i(4, 4))
  assert_eq(m.entries.size(), 1, "pink tile should be skipped")
  assert_eq(m.entries[0]["atlas_coords"], Vector2i(1, 0))


func test_populate_clears_existing() -> void:
  var img: Image = Image.create(4, 4, false, Image.FORMAT_RGB8)
  img.fill(Color(0, 0, 0, 1))
  var tex: ImageTexture = ImageTexture.create_from_image(img)

  # Start with existing entries
  var m: HerringboneColorTileMapping = HerringboneColorTileMapping.new()
  m.entries = [{"color": Color.RED, "source_id": 99,
    "atlas_coords": Vector2i(99, 99), "alternative_tile": 0}]
  m.populate_from_atlas(tex, Vector2i(4, 4))
  assert_eq(m.entries.size(), 1, "old entries should be replaced")
  assert_eq(m.entries[0]["source_id"], 0)
