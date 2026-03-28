class_name HerringboneConstraintCatalog
extends Resource

@export var schema_name: String = ""
@export var num_colors: PackedInt32Array = PackedInt32Array()
@export var is_corner: bool = true
@export var description: String = ""


static func create_hbw_2222() -> HerringboneConstraintCatalog:
  var catalog: HerringboneConstraintCatalog = HerringboneConstraintCatalog.new()
  catalog.schema_name = "hbw-2222"
  catalog.num_colors = PackedInt32Array([2, 2, 2, 2])
  catalog.is_corner = true
  catalog.description = (
    "Herringbone Wang 2-2-2-2: 2 colors per corner class, "
    + "128 tiles (64H + 64V)"
  )
  return catalog


static func create_hbw_2221() -> HerringboneConstraintCatalog:
  var catalog: HerringboneConstraintCatalog = HerringboneConstraintCatalog.new()
  catalog.schema_name = "hbw-2221"
  catalog.num_colors = PackedInt32Array([2, 2, 2, 1])
  catalog.is_corner = true
  catalog.description = (
    "Herringbone Wang 2-2-2-1: 3 classes with 2 colors, "
    + "1 class with 1 color, 48 tiles (32H + 16V)"
  )
  return catalog


static func create_hbw_3131() -> HerringboneConstraintCatalog:
  var catalog: HerringboneConstraintCatalog = HerringboneConstraintCatalog.new()
  catalog.schema_name = "hbw-3131"
  catalog.num_colors = PackedInt32Array([3, 1, 3, 1])
  catalog.is_corner = true
  catalog.description = (
    "Herringbone Wang 3-1-3-1: alternating 3 and 1 colors, "
    + "54 tiles (27H + 27V)"
  )
  return catalog


static func create_hbe_222222() -> HerringboneConstraintCatalog:
  var catalog: HerringboneConstraintCatalog = HerringboneConstraintCatalog.new()
  catalog.schema_name = "hbe-222222"
  catalog.num_colors = PackedInt32Array([2, 2, 2, 2, 2, 2])
  catalog.is_corner = false
  catalog.description = (
    "Herringbone Edge 2-2-2-2-2-2: 2 colors per edge type, "
    + "128 tiles (64H + 64V). Barrett's binary dungeon corridors."
  )
  return catalog


func create_empty_macro_set(
  base_unit_size: int,
) -> HerringboneMacroSet:
  var macro_set: HerringboneMacroSet = HerringboneMacroSet.new()
  macro_set.base_unit_size = base_unit_size
  macro_set.num_colors = num_colors.duplicate()
  macro_set.is_corner = is_corner
  return macro_set
