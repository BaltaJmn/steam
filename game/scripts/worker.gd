extends Node3D
## Kobold contratado. Solo es visual: la lógica la lleva el host en Game.

var _target := Vector3.ZERO
var _carrying := false
var _body: Node3D
var _sack: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_target = position
	_body = Node3D.new()
	add_child(_body)
	var torso := CapsuleMesh.new()
	torso.radius = 0.25
	torso.height = 1.0
	Visuals.mesh_instance(_body, torso, Vector3(0, 0.5, 0), "kobold")
	Visuals.mesh_instance(_body, Visuals.box_mesh(Vector3(0.18, 0.12, 0.25)), Vector3(0, 0.82, -0.25), "kobold")
	var helmet := SphereMesh.new()
	helmet.radius = 0.24
	helmet.height = 0.24
	helmet.is_hemisphere = true
	Visuals.mesh_instance(_body, helmet, Vector3(0, 0.95, 0), "helmet")
	var sack := SphereMesh.new()
	sack.radius = 0.2
	sack.height = 0.34
	_sack = Visuals.mesh_instance(_body, sack, Vector3(0, 0.75, 0.3), "coins")
	_sack.visible = false


func set_target(pos: Vector3, carrying: bool) -> void:
	_target = pos
	_carrying = carrying


func _process(delta: float) -> void:
	_time += delta
	var to := _target - position
	to.y = 0.0
	var moving := to.length() > 0.05
	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(delta * 10.0, 0.0, 1.0))
	position = position.lerp(_target, clampf(delta * 8.0, 0.0, 1.0))
	_body.position.y = absf(sin(_time * 12.0)) * 0.06 if moving else 0.0
	_sack.visible = _carrying
