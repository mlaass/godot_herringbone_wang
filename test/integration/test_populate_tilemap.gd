extends GutTest


func test_populate_with_null_target() -> void:
  HerringboneAuthoringLayer.populate_tilemap(null, [], null)
  assert_true(true, "should not crash with null target")


func test_populate_with_empty_map() -> void:
  var target: TileMapLayer = TileMapLayer.new()
  target.tile_set = TileSet.new()
  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  HerringboneAuthoringLayer.populate_tilemap(target, [], ms)
  var used: Array[Vector2i] = target.get_used_cells()
  assert_eq(used.size(), 0, "empty map should place no cells")
  target.free()


func test_populate_places_cells() -> void:
  var ts: TileSet = TileSet.new()
  ts.tile_size = Vector2i(16, 16)
  var src: TileSetAtlasSource = TileSetAtlasSource.new()
  var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
  var tex: ImageTexture = ImageTexture.create_from_image(img)
  src.texture = tex
  src.texture_region_size = Vector2i(16, 16)
  var src_id: int = ts.add_source(src)
  src.create_tile(Vector2i(0, 0))

  var target: TileMapLayer = TileMapLayer.new()
  target.tile_set = ts

  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.base_unit_size = 2

  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  data.tile_id = 0
  data.constraints = PackedInt32Array([0, 0, 0, 0, 0, 0])
  data.init_cells(4, 2)
  for y: int in range(2):
    for x: int in range(4):
      data.set_cell(x, y, {
        "source_id": src_id,
        "atlas_coords": Vector2i(0, 0),
        "alternative_tile": 0,
      })
  ms.h_tiles.append(data)

  var abstract_map: Array = [
    {"tile_id": 0, "orientation": 0, "grid_x": 0, "grid_y": 0},
  ]

  HerringboneAuthoringLayer.populate_tilemap(target, abstract_map, ms)
  var used: Array[Vector2i] = target.get_used_cells()
  assert_eq(used.size(), 8, "4x2 tile should place 8 cells")
  target.free()


func test_populate_correct_position() -> void:
  var ts: TileSet = TileSet.new()
  ts.tile_size = Vector2i(16, 16)
  var src: TileSetAtlasSource = TileSetAtlasSource.new()
  var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
  var tex: ImageTexture = ImageTexture.create_from_image(img)
  src.texture = tex
  src.texture_region_size = Vector2i(16, 16)
  var src_id: int = ts.add_source(src)
  src.create_tile(Vector2i(0, 0))

  var target: TileMapLayer = TileMapLayer.new()
  target.tile_set = ts

  var ms: HerringboneMacroSet = HerringboneMacroSet.new()
  ms.base_unit_size = 2

  var data: HerringboneMacroData = HerringboneMacroData.new()
  data.orientation = HerringboneMacroData.Orientation.HORIZONTAL
  data.tile_id = 5
  data.constraints = PackedInt32Array([0, 0, 0, 0, 0, 0])
  data.init_cells(4, 2)
  data.set_cell(0, 0, {
    "source_id": src_id,
    "atlas_coords": Vector2i(0, 0),
    "alternative_tile": 0,
  })
  ms.h_tiles.append(data)

  var abstract_map: Array = [
    {"tile_id": 5, "orientation": 0, "grid_x": 3, "grid_y": 2},
  ]

  HerringboneAuthoringLayer.populate_tilemap(target, abstract_map, ms)

  # grid_x=3, grid_y=2, base_unit=2 → cell at (6, 4)
  var cell_src: int = target.get_cell_source_id(Vector2i(6, 4))
  assert_eq(cell_src, src_id, "cell at (6,4) should have correct source_id")
  target.free()
