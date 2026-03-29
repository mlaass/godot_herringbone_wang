@tool
class_name HerringboneWangPlugin
extends EditorPlugin

const AUTHORING_LAYER_SCRIPT: String = (
  "res://addons/herringbone_wang_generator/herringbone_authoring_layer.gd"
)

var _panel: HerringboneEditorPanel = null
var _panel_button: Button = null


func _enter_tree() -> void:
  add_custom_type(
    "HerringboneAuthoringLayer",
    "TileMapLayer",
    load(AUTHORING_LAYER_SCRIPT),
    _get_icon(),
  )
  _panel = HerringboneEditorPanel.new()
  _panel_button = add_control_to_bottom_panel(_panel, "Herringbone")


func _exit_tree() -> void:
  if _panel != null:
    remove_control_from_bottom_panel(_panel)
    _panel.queue_free()
    _panel = null
    _panel_button = null
  remove_custom_type("HerringboneAuthoringLayer")


func _handles(object: Object) -> bool:
  return object is TileMapLayer


func _edit(object: Object) -> void:
  if _panel == null:
    return
  if object is TileMapLayer:
    _panel.set_target_layer(object as TileMapLayer)


func _make_visible(visible: bool) -> void:
  if _panel == null:
    return
  if visible:
    make_bottom_panel_item_visible(_panel)
  else:
    _panel.set_target_layer(null)


func _get_icon() -> Texture2D:
  var icon_path: String = (
    "res://addons/herringbone_wang_generator/icon.png"
  )
  if ResourceLoader.exists(icon_path):
    return load(icon_path) as Texture2D
  return null
