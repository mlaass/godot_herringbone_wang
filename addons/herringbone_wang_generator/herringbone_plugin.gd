@tool
class_name HerringboneWangPlugin
extends EditorPlugin

const AUTHORING_LAYER_SCRIPT: String = (
  "res://addons/herringbone_wang_generator/herringbone_authoring_layer.gd"
)


func _enter_tree() -> void:
  add_custom_type(
    "HerringboneAuthoringLayer",
    "TileMapLayer",
    load(AUTHORING_LAYER_SCRIPT),
    _get_icon(),
  )


func _exit_tree() -> void:
  remove_custom_type("HerringboneAuthoringLayer")


func _get_icon() -> Texture2D:
  var icon_path: String = (
    "res://addons/herringbone_wang_generator/icon.svg"
  )
  if ResourceLoader.exists(icon_path):
    return load(icon_path) as Texture2D
  return null
