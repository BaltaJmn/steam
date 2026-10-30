@tool
extends Node3D
## Tesoro suelto: se coge, se lleva en la mano y se coloca en su hueco.
## Cada tesoro de la escena necesita un item_id único.

@export var item_id := 0
@export var type_key := "crown_gold"

var _mesh: MeshInstance3D
var _area: Area3D
var _state := "loose"
var _holder := 0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("items")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	_mesh = Visuals.mesh_instance(self, Visuals.item_mesh(type_key), Vector3.ZERO)
	_area = Area3D.new()
	_area.collision_layer = Visuals.LAYER_INTERACT
	_area.collision_mask = 0
	_area.monitoring = false
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 0.2, 0)
	_area.add_child(collision)
	add_child(_area)
	_set_pose(false)


## De pie (en la mano o en el estante) o tumbado en el suelo.
func _set_pose(upright: bool) -> void:
	if type_key.begins_with("sword") and not upright:
		_mesh.rotation_degrees = Vector3(90, 0, 0)
		_mesh.position = Vector3(0, 0.015, 0)
	else:
		_mesh.rotation_degrees = Vector3.ZERO
		_mesh.position = Vector3(0, Visuals.item_height(type_key) / 2.0, 0)


func _on_changed(what: String, id: int) -> void:
	if what == "all" or (what == "item" and id == item_id):
		_refresh()


func _refresh() -> void:
	if not Game.items.has(item_id):
		return
	var data: Dictionary = Game.items[item_id]
	_state = data["state"]
	_holder = int(data["holder"])
	_area.collision_layer = Visuals.LAYER_INTERACT if _state == "loose" else 0
	match _state:
		"loose":
			global_position = data["pos"]
			rotation = Vector3(0, float(data.get("yaw", 0.0)), 0)
			scale = Vector3.ONE
			_set_pose(false)
		"placed":
			global_position = data["pos"]
			rotation = Vector3(0, float(data.get("yaw", 0.0)), 0)
			scale = Vector3.ONE
			_set_pose(true)
		"held":
			_set_pose(true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _state != "held":
		return
	var holder = Game.player_nodes.get(_holder)
	if is_instance_valid(holder):
		global_transform = holder.get_hold_transform()
		scale = Vector3.ONE * 0.8


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var item_name := Balance.item_name(type_key)
	if int(data["item"]) != -1 or data["load_kind"] != "":
		return "%s (tienes las manos ocupadas)" % item_name
	return "[E] Coger %s" % item_name


func interact(_player: Node, _part: String) -> void:
	Game.request("_srv_pickup_item", [item_id])
