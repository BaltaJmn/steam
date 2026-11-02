extends Node3D
## Ayudante contratado: una figurita amarilla más pequeña con su cesta. Solo es
## visual: la lógica la lleva el host en Game. Mira hacia -Z.

var _target := Vector3.ZERO
var _carrying := false
var _body: Node3D
var _load: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_target = position
	_body = Node3D.new()
	add_child(_body)
	var torso := CapsuleMesh.new()
	torso.radius = 0.22
	torso.height = 0.75
	Visuals.mesh_instance(_body, torso, Vector3(0, 0.38, 0), "yellow")
	var head := SphereMesh.new()
	head.radius = 0.18
	head.height = 0.36
	Visuals.mesh_instance(_body, head, Vector3(0, 0.9, 0), "skin")
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.028
		eye.height = 0.056
		Visuals.mesh_instance(_body, eye, Vector3(0.06 * side, 0.93, -0.16), "ink")
	# Una pieza en brazos cuando lleva carga.
	_load = Visuals.mesh_instance(_body, Visuals.brick_mesh(), Vector3(0, 0.5, -0.3), "coral")
	_load.scale = Vector3.ONE * 0.5
	_load.visible = false


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
	_body.position.y = absf(sin(_time * 12.0)) * 0.05 if moving else 0.0
	_load.visible = _carrying
