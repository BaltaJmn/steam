@tool
extends Node3D
## Hueco con la silueta (fantasma) del tesoro que va ahí. Lo crea la estantería.

@export var slot_id := 0
@export var type_key := "crown_gold"

var _ghost: MeshInstance3D
var _area: Area3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("slots")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	var height := Visuals.item_height(type_key)
	_ghost = Visuals.mesh_instance(self, Visuals.item_mesh(type_key), Vector3(0, height / 2.0, 0), "ghost")
	_area = Area3D.new()
	_area.collision_layer = Visuals.LAYER_INTERACT
	_area.collision_mask = 0
	_area.monitoring = false
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, height + 0.25, 0.5)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, (height + 0.25) / 2.0, 0)
	_area.add_child(collision)
	add_child(_area)


func _on_changed(what: String, id: int) -> void:
	if what == "all" or (what == "slot" and id == slot_id):
		_refresh()


func _refresh() -> void:
	if not Game.slots.has(slot_id):
		return
	var filled := int(Game.slots[slot_id]["item"]) != -1
	_ghost.visible = not filled
	_area.collision_layer = 0 if filled else Visuals.LAYER_INTERACT


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var wanted := Balance.item_name(type_key)
	var held := int(data["item"])
	if held == -1 or not Game.items.has(held):
		return "Hueco: %s" % wanted
	if Game.items[held]["type"] == type_key:
		return "[E] Colocar %s" % wanted
	return "Aquí va: %s" % wanted


func interact(_player: Node, _part: String) -> void:
	Game.request("_srv_place_item", [slot_id])
