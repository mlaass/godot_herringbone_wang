class_name HerringboneValidator
extends RefCounted


static func validate(macro_set: HerringboneMacroSet) -> Dictionary:
  var result: Dictionary = {
    "is_valid": true,
    "errors": PackedStringArray(),
    "warnings": PackedStringArray(),
    "missing_h": [] as Array[PackedInt32Array],
    "missing_v": [] as Array[PackedInt32Array],
    "completion_pct": 0.0,
  }

  if macro_set == null:
    result["is_valid"] = false
    result["errors"] = PackedStringArray(["macro_set is null"])
    return result

  var errors: PackedStringArray = PackedStringArray()
  var warnings: PackedStringArray = PackedStringArray()

  if macro_set.base_unit_size <= 0:
    errors.append("base_unit_size must be positive")

  if macro_set.num_colors.size() != 4:
    errors.append("num_colors must have 4 elements")

  for tile: HerringboneMacroData in macro_set.h_tiles:
    if not tile.is_valid():
      errors.append(
        "invalid H tile: %s" % tile.get_constraint_key()
      )

  for tile: HerringboneMacroData in macro_set.v_tiles:
    if not tile.is_valid():
      errors.append(
        "invalid V tile: %s" % tile.get_constraint_key()
      )

  var missing_h: Array[PackedInt32Array] = (
    macro_set.get_missing_h_constraints()
  )
  var missing_v: Array[PackedInt32Array] = (
    macro_set.get_missing_v_constraints()
  )

  var req_h: int = macro_set.get_required_h_count()
  var req_v: int = macro_set.get_required_v_count()
  var total_required: int = req_h + req_v
  var total_present: int = (
    (req_h - missing_h.size()) + (req_v - missing_v.size())
  )

  var pct: float = 0.0
  if total_required > 0:
    pct = float(total_present) / float(total_required) * 100.0

  if not missing_h.is_empty() or not missing_v.is_empty():
    warnings.append(
      "incomplete set: %d/%d tiles present (%.1f%%)"
      % [total_present, total_required, pct]
    )

  result["is_valid"] = errors.is_empty()
  result["errors"] = errors
  result["warnings"] = warnings
  result["missing_h"] = missing_h
  result["missing_v"] = missing_v
  result["completion_pct"] = pct
  return result
