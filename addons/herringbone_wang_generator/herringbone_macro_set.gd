class_name HerringboneMacroSet
extends Resource

@export var base_unit_size: int = 4
@export var is_corner: bool = true
@export var num_colors: PackedInt32Array = PackedInt32Array([2, 2, 2, 2])
@export var h_tiles: Array[HerringboneMacroData] = []
@export var v_tiles: Array[HerringboneMacroData] = []


func get_required_h_count() -> int:
  return _get_required_count_for_orientation(
    HerringboneMacroData.Orientation.HORIZONTAL
  )


func get_required_v_count() -> int:
  return _get_required_count_for_orientation(
    HerringboneMacroData.Orientation.VERTICAL
  )


func is_complete() -> bool:
  return (
    h_tiles.size() == get_required_h_count()
    and v_tiles.size() == get_required_v_count()
    and get_missing_h_constraints().is_empty()
    and get_missing_v_constraints().is_empty()
  )


func get_missing_h_constraints() -> Array[PackedInt32Array]:
  return _get_missing_for_orientation(
    HerringboneMacroData.Orientation.HORIZONTAL,
    h_tiles,
  )


func get_missing_v_constraints() -> Array[PackedInt32Array]:
  return _get_missing_for_orientation(
    HerringboneMacroData.Orientation.VERTICAL,
    v_tiles,
  )


func to_generator_defs() -> Array:
  var defs: Array = []
  for tile: HerringboneMacroData in h_tiles:
    defs.append({
      "tile_id": tile.tile_id,
      "orientation": HerringboneMacroData.Orientation.HORIZONTAL,
      "constraints": tile.constraints,
    })
  for tile: HerringboneMacroData in v_tiles:
    defs.append({
      "tile_id": tile.tile_id,
      "orientation": HerringboneMacroData.Orientation.VERTICAL,
      "constraints": tile.constraints,
    })
  return defs


func find_tile_by_constraints(
  orient: int,
  cons: PackedInt32Array,
) -> HerringboneMacroData:
  var tiles: Array[HerringboneMacroData] = (
    h_tiles if orient == HerringboneMacroData.Orientation.HORIZONTAL
    else v_tiles
  )
  for tile: HerringboneMacroData in tiles:
    if tile.constraints == cons:
      return tile
  return null


func _get_required_count_for_orientation(
  orient: int,
) -> int:
  var combos: Array[PackedInt32Array] = _enumerate_constraint_combos(orient)
  return combos.size()


func _get_missing_for_orientation(
  orient: int,
  tiles: Array[HerringboneMacroData],
) -> Array[PackedInt32Array]:
  var existing: Dictionary = {}
  for tile: HerringboneMacroData in tiles:
    existing[tile.get_constraint_key()] = true

  var all_combos: Array[PackedInt32Array] = (
    _enumerate_constraint_combos(orient)
  )
  var missing: Array[PackedInt32Array] = []
  for combo: PackedInt32Array in all_combos:
    var prefix: String = (
      "H" if orient == HerringboneMacroData.Orientation.HORIZONTAL else "V"
    )
    var parts: PackedStringArray = PackedStringArray()
    parts.append(prefix)
    for i: int in range(combo.size()):
      parts.append(str(combo[i]))
    var key: String = "_".join(parts)
    if not existing.has(key):
      missing.append(combo)
  return missing


func _enumerate_constraint_combos(
  orient: int,
) -> Array[PackedInt32Array]:
  var combos: Array[PackedInt32Array] = []
  var color_counts: Array[int] = _get_corner_counts_for_orientation(orient)
  _enumerate_recursive(color_counts, 0, PackedInt32Array(), combos)
  return combos


func _get_corner_counts_for_orientation(
  orient: int,
) -> Array[int]:
  if not is_corner:
    return _get_edge_counts_for_orientation(orient)
  # Herringbone tiles have 6 constraint vertices. Each vertex belongs to
  # one of 4 corner classes. The mapping from vertex index to corner class
  # depends on orientation (H vs V). For a complete stochastic set, every
  # combination of colors at the 6 vertices must be present.
  #
  # Corner class assignments per vertex (from stb source):
  #   H tile: a=type1, b=type2, c=type3, d=type0, e=type1, f=type2
  #   V tile: a=type0, b=type3, c=type2, d=type1, e=type0, f=type3
  var class_map: Array[int] = []
  if orient == HerringboneMacroData.Orientation.HORIZONTAL:
    class_map = [1, 2, 3, 0, 1, 2]
  else:
    class_map = [0, 3, 2, 1, 0, 3]

  var counts: Array[int] = []
  for i: int in range(6):
    var cls: int = class_map[i]
    counts.append(num_colors[cls])
  return counts


func _get_edge_counts_for_orientation(
  orient: int,
) -> Array[int]:
  # Edge mode: each constraint position maps to one of 6 edge types.
  # The mapping depends on orientation and uses PRD canonical ordering.
  #
  # Edge type assignments (from stb source, remapped to PRD order):
  #   H: [left=type1, top-left=type2, top-right=type3,
  #       right=type4, bottom-left=type0, bottom-right=type2]
  #   V: [top=type0, left-upper=type5, left-lower=type4,
  #       bottom=type3, right-upper=type1, right-lower=type5]
  var type_map: Array[int] = []
  if orient == HerringboneMacroData.Orientation.HORIZONTAL:
    type_map = [1, 2, 3, 4, 0, 2]
  else:
    type_map = [0, 5, 4, 3, 1, 5]

  var counts: Array[int] = []
  for i: int in range(6):
    counts.append(num_colors[type_map[i]])
  return counts


func _enumerate_recursive(
  counts: Array[int],
  depth: int,
  current: PackedInt32Array,
  result: Array[PackedInt32Array],
) -> void:
  if depth == counts.size():
    result.append(current.duplicate())
    return
  for c: int in range(counts[depth]):
    var next: PackedInt32Array = current.duplicate()
    next.append(c)
    _enumerate_recursive(counts, depth + 1, next, result)
