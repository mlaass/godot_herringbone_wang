class_name HerringboneMacroSet
extends Resource

@export var base_unit_size: int = 4
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


func find_tile_by_constraints(
  orient: HerringboneMacroData.Orientation,
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
  orient: HerringboneMacroData.Orientation,
) -> int:
  var combos: Array[PackedInt32Array] = _enumerate_constraint_combos(orient)
  return combos.size()


func _get_missing_for_orientation(
  orient: HerringboneMacroData.Orientation,
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
  orient: HerringboneMacroData.Orientation,
) -> Array[PackedInt32Array]:
  var combos: Array[PackedInt32Array] = []
  var color_counts: Array[int] = _get_corner_counts_for_orientation(orient)
  _enumerate_recursive(color_counts, 0, PackedInt32Array(), combos)
  return combos


func _get_corner_counts_for_orientation(
  orient: HerringboneMacroData.Orientation,
) -> Array[int]:
  # Herringbone tiles have 6 constraint vertices. Each vertex belongs to
  # one of 4 corner classes. The mapping from vertex index to corner class
  # depends on orientation (H vs V). For a complete stochastic set, every
  # combination of colors at the 6 vertices must be present.
  #
  # Corner class assignments per vertex (0-indexed):
  # Horizontal tile vertices: classes [0, 1, 2, 3, 0, 1]
  # Vertical tile vertices:   classes [2, 3, 0, 1, 2, 3]
  var class_map: Array[int] = []
  if orient == HerringboneMacroData.Orientation.HORIZONTAL:
    class_map = [0, 1, 2, 3, 0, 1]
  else:
    class_map = [2, 3, 0, 1, 2, 3]

  var counts: Array[int] = []
  for i: int in range(6):
    var cls: int = class_map[i]
    counts.append(num_colors[cls])
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
