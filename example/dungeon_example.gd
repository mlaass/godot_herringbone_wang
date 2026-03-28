@tool
extends Node2D

@export var map_width: int = 20
@export var map_height: int = 20
@export var seed_value: int = 42
@export var color_mapping: HerringboneColorTileMapping
@export var fallback_cell: Dictionary = {
  "source_id": 0,
  "atlas_coords": Vector2i(0, 0),
  "alternative_tile": 0,
}
@export var regenerate: bool = false:
  set(value):
    if value:
      _generate()

var _macro_set: HerringboneMacroSet


func _ready() -> void:
  if Engine.is_editor_hint():
    return
  _generate()


func _generate() -> void:
  var tilemap: TileMapLayer = $TileMapLayer
  if tilemap == null:
    push_error("DUNGEON: TileMapLayer child not found")
    return
  if tilemap.tile_set == null:
    push_error("DUNGEON: TileMapLayer has no TileSet assigned")
    return

  _ensure_mapping(tilemap)
  tilemap.clear()

  _macro_set = _import_chunks()
  if _macro_set == null:
    push_error("DUNGEON: chunk import failed")
    return
  print(
    "DUNGEON: Imported %d H + %d V tiles"
    % [_macro_set.h_tiles.size(), _macro_set.v_tiles.size()]
  )

  var gen: RefCounted = ClassDB.instantiate(&"HerringboneGenerator")
  gen.set_constraint_mode(false)
  gen.set_edge_colors(_macro_set.num_colors)
  gen.load_tile_definitions(_macro_set.to_generator_defs())
  if not gen.build_tileset():
    push_error("DUNGEON: build_tileset failed: %s" % gen.get_last_error())
    return

  var abstract_map: Array = gen.generate_abstract_map(
    map_width, map_height, seed_value,
  )
  print("DUNGEON: Generated %d tile placements" % abstract_map.size())

  HerringboneAuthoringLayer.populate_tilemap(
    tilemap, abstract_map, _macro_set, fallback_cell,
  )
  print("DUNGEON: Tilemap populated")


func _ensure_mapping(tilemap: TileMapLayer) -> void:
  if color_mapping != null:
    return
  # Auto-generate mapping from the TileSet's first atlas source
  color_mapping = HerringboneColorTileMapping.new()
  var ts: TileSet = tilemap.tile_set
  if ts.get_source_count() == 0:
    return
  var src_id: int = ts.get_source_id(0)
  var src: TileSetAtlasSource = ts.get_source(src_id) as TileSetAtlasSource
  if src == null or src.texture == null:
    return
  color_mapping.populate_from_atlas(
    src.texture, ts.tile_size, src_id,
  )
  print(
    "DUNGEON: Auto-populated mapping with %d entries from atlas"
    % color_mapping.entries.size()
  )


func _import_chunks() -> HerringboneMacroSet:
  var image: Image = Image.load_from_file(
    ProjectSettings.globalize_path(
      "res://addons/herringbone_wang_generator/assets/chunks.png"
    )
  )
  if image == null:
    return null

  var importer: HerringboneChunkImporter = HerringboneChunkImporter.new()
  var result: Dictionary = importer.import_chunk_map(
    image, 10, Color(1, 0, 1, 1),
    Vector2i(0, 0), 16, 4,
    Vector2i(0, 96), 8, 8,
    color_mapping,
  )

  if not result["success"]:
    push_error("DUNGEON: import errors: %s" % str(result["errors"]))
    return null

  return result["macro_set"]
