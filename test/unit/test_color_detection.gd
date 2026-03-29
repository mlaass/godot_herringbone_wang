extends GutTest

var _mapping: HerringboneColorTileMapping


func before_each() -> void:
  _mapping = HerringboneColorTileMapping.new()


func _make_image(width: int, height: int) -> Image:
  return Image.create(width, height, false, Image.FORMAT_RGB8)


func test_detects_two_distinct_colors() -> void:
  var img: Image = _make_image(4, 4)
  img.fill(Color(1, 0, 1, 1))  # pink = transparent
  img.set_pixel(0, 0, Color(0, 0, 0, 1))  # black
  img.set_pixel(1, 0, Color(1, 1, 1, 1))  # white
  _mapping.detect_colors_from_image(img)
  assert_eq(_mapping.entries.size(), 2)


func test_excludes_transparency_color() -> void:
  var img: Image = _make_image(2, 2)
  img.fill(Color(1, 0, 1, 1))  # all pink
  _mapping.detect_colors_from_image(img)
  assert_eq(_mapping.entries.size(), 0)


func test_groups_colors_within_tolerance() -> void:
  var img: Image = _make_image(2, 1)
  var base: float = 0.5
  img.set_pixel(0, 0, Color(base, base, base, 1))
  img.set_pixel(1, 0, Color(base + 4.0 / 255.0, base, base, 1))
  _mapping.detect_colors_from_image(img)
  assert_eq(
    _mapping.entries.size(), 1,
    "colors within 5/255 tolerance should merge",
  )


func test_separates_colors_beyond_tolerance() -> void:
  var img: Image = _make_image(2, 1)
  var base: float = 0.5
  img.set_pixel(0, 0, Color(base, base, base, 1))
  img.set_pixel(1, 0, Color(base + 6.0 / 255.0, base, base, 1))
  _mapping.detect_colors_from_image(img)
  assert_eq(
    _mapping.entries.size(), 2,
    "colors beyond 5/255 tolerance should be separate",
  )


func test_first_seen_representative_wins() -> void:
  var img: Image = _make_image(2, 1)
  # Use colors that roundtrip cleanly through 8-bit channels
  var first: Color = Color(25.0 / 255.0, 25.0 / 255.0, 25.0 / 255.0, 1)
  var second: Color = Color(
    27.0 / 255.0, 25.0 / 255.0, 25.0 / 255.0, 1,
  )
  img.set_pixel(0, 0, first)
  img.set_pixel(1, 0, second)
  _mapping.detect_colors_from_image(img)
  assert_eq(_mapping.entries.size(), 1)
  var entry_color: Color = _mapping.entries[0]["color"]
  assert_eq(entry_color, first, "representative should be first-seen")


func test_placeholder_atlas_coords() -> void:
  var img: Image = _make_image(1, 1)
  img.set_pixel(0, 0, Color(0, 0, 0, 1))
  _mapping.detect_colors_from_image(img)
  assert_eq(_mapping.entries.size(), 1)
  var entry: Dictionary = _mapping.entries[0]
  assert_eq(entry["source_id"], -1)
  assert_eq(entry["atlas_coords"], Vector2i(-1, -1))
  assert_eq(entry["alternative_tile"], 0)


func test_clears_existing_entries() -> void:
  _mapping.entries = [
    {
      "color": Color.RED,
      "source_id": 99,
      "atlas_coords": Vector2i(99, 99),
      "alternative_tile": 0,
    },
  ]
  var img: Image = _make_image(1, 1)
  img.set_pixel(0, 0, Color(0, 0, 0, 1))
  _mapping.detect_colors_from_image(img)
  assert_eq(
    _mapping.entries.size(), 1,
    "old entries should be replaced",
  )
  assert_eq(_mapping.entries[0]["source_id"], -1)


func test_custom_tolerance() -> void:
  var img: Image = _make_image(2, 1)
  var base: float = 0.5
  img.set_pixel(0, 0, Color(base, base, base, 1))
  img.set_pixel(1, 0, Color(base + 2.0 / 255.0, base, base, 1))
  # With tight tolerance of 1/255, these should be separate
  _mapping.detect_colors_from_image(
    img, Color(1, 0, 1, 1), 1.0 / 255.0,
  )
  assert_eq(
    _mapping.entries.size(), 2,
    "tight tolerance should separate close colors",
  )


func test_custom_transparency_color() -> void:
  var img: Image = _make_image(2, 1)
  img.set_pixel(0, 0, Color(0, 1, 0, 1))  # green = custom transparent
  img.set_pixel(1, 0, Color(1, 0, 1, 1))  # pink = now visible
  _mapping.detect_colors_from_image(img, Color(0, 1, 0, 1))
  assert_eq(_mapping.entries.size(), 1)
  assert_eq(_mapping.entries[0]["color"], Color(1, 0, 1, 1))


func test_sets_transparency_color_on_resource() -> void:
  var img: Image = _make_image(1, 1)
  img.set_pixel(0, 0, Color(0, 0, 0, 1))
  var custom_trans: Color = Color(0, 1, 0, 1)
  _mapping.detect_colors_from_image(img, custom_trans)
  assert_eq(_mapping.transparency_color, custom_trans)


func test_null_image() -> void:
  _mapping.detect_colors_from_image(null)
  assert_eq(_mapping.entries.size(), 0)


func test_single_pixel_transparent() -> void:
  var img: Image = _make_image(1, 1)
  img.set_pixel(0, 0, Color(1, 0, 1, 1))  # pink
  _mapping.detect_colors_from_image(img)
  assert_eq(_mapping.entries.size(), 0)
