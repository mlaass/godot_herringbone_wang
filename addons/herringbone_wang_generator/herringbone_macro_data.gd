class_name HerringboneMacroData
extends Resource

enum Orientation { HORIZONTAL, VERTICAL }

@export var orientation: int = Orientation.HORIZONTAL
@export var tile_id: int = 0
@export var constraints: PackedInt32Array = PackedInt32Array()
@export var width: int = 0
@export var height: int = 0
@export var cells: Array[Dictionary] = []


func get_cell(x: int, y: int) -> Dictionary:
  var idx: int = y * width + x
  if idx < 0 or idx >= cells.size():
    return {}
  var cell: Dictionary = cells[idx]
  return cell


func set_cell(x: int, y: int, data: Dictionary) -> void:
  var idx: int = y * width + x
  if idx < 0 or idx >= cells.size():
    return
  cells[idx] = data


func is_valid() -> bool:
  if constraints.size() != 6:
    return false
  if width <= 0 or height <= 0:
    return false
  if cells.size() != width * height:
    return false
  return true


func get_constraint_key() -> String:
  var prefix: String = "H" if orientation == Orientation.HORIZONTAL else "V"
  if constraints.size() != 6:
    return prefix + "_invalid"
  var parts: PackedStringArray = PackedStringArray()
  parts.append(prefix)
  for i: int in range(constraints.size()):
    parts.append(str(constraints[i]))
  return "_".join(parts)


func init_cells(w: int, h: int) -> void:
  width = w
  height = h
  cells.clear()
  cells.resize(w * h)
  var empty: Dictionary = {
    "source_id": -1,
    "atlas_coords": Vector2i(-1, -1),
    "alternative_tile": 0,
  }
  for i: int in range(w * h):
    cells[i] = empty.duplicate()
