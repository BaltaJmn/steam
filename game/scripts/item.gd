@tool
extends Node3D
## Pieza especial (ojo, puerta, bandera...): se coge, se lleva en la mano y se
## pone en su figura. Cada pieza de la escena necesita un item_id único.

@export var item_id := 0
@export var type_key := "eye_ink"

var _mesh: MeshInstance3D
var _area: Area3D
var _glint: MeshInstance3D
var _balloon: Node3D
var _time := 0.0
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
	var spark := SphereMesh.new()
	spark.radius = 0.02
	spark.height = 0.04
	_glint = Visuals.mesh_instance(self, spark, Vector3(0, 0.25, 0), "glint")
	# Globito de la tienda, atado a la pieza (de un color distinto cada una).
	_balloon = Node3D.new()
	add_child(_balloon)
	var string := CylinderMesh.new()
	string.top_radius = 0.003
	string.bottom_radius = 0.003
	string.height = 1.3
	Visuals.mesh_instance(_balloon, string, Vector3(0, 0.7, 0), "ink")
	var ball := SphereMesh.new()
	ball.radius = 0.11
	ball.height = 0.26
	Visuals.mesh_instance(_balloon, ball, Vector3(0, 1.45, 0), Balance.KINDS[item_id % Balance.KINDS.size()])
	_balloon.visible = false
	_set_pose(false)


## Apoyado (en el suelo, en la mano o en la bandeja). Por ahora todos los
## objetos se apoyan igual; se deja el parámetro para cuando haya modelos.
func _set_pose(_upright: bool) -> void:
	_mesh.rotation_degrees = Vector3.ZERO
	_mesh.position = Vector3(0, Visuals.item_height(type_key) / 2.0, 0)


func _on_changed(what: String, id: int) -> void:
	if what == "all" or what == "economy" or (what == "item" and id == item_id):
		_refresh()


func _refresh() -> void:
	if not Game.items.has(item_id):
		return
	var data: Dictionary = Game.items[item_id]
	_state = data["state"]
	_holder = int(data["holder"])
	_area.collision_layer = Visuals.LAYER_INTERACT if _state == "loose" else 0
	_glint.visible = _state == "loose"
	_balloon.visible = _state == "loose" and Game.upgrade_level("balloons") > 0
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


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _state == "loose":
		# El brillito sube, baja y late despacio para delatar la pieza.
		_time += delta
		_glint.position.y = 0.25 + sin(_time * 2.0) * 0.04
		_glint.scale = Vector3.ONE * (0.7 + 0.5 * absf(sin(_time * 3.0 + float(item_id))))
		_balloon.rotation.z = sin(_time * 1.3 + float(item_id)) * 0.06
		return
	if _state != "held":
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
