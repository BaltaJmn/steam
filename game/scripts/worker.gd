extends Node3D
## Pollito de cuerda (cosita de la tienda): va y viene con piezas del suelo a
## las mesas. Solo es visual: la lógica la lleva el host en Game. Mira hacia -Z.

var _target := Vector3.ZERO
var _carrying := false
var _body: Node3D
var _key: Node3D
var _load: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_target = position
	_body = Node3D.new()
	add_child(_body)
	var fluff := SphereMesh.new()
	fluff.radius = 0.11
	fluff.height = 0.21
	Visuals.mesh_instance(_body, fluff, Vector3(0, 0.12, 0), "chick")
	var head := SphereMesh.new()
	head.radius = 0.075
	head.height = 0.15
	Visuals.mesh_instance(_body, head, Vector3(0, 0.25, -0.04), "chick")
	var beak := PrismMesh.new()
	beak.size = Vector3(0.04, 0.035, 0.04)
	var beak_instance := Visuals.mesh_instance(_body, beak, Vector3(0, 0.24, -0.12), "beak")
	beak_instance.rotation_degrees = Vector3(-90, 0, 0)
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.012
		eye.height = 0.024
		Visuals.mesh_instance(_body, eye, Vector3(0.035 * side, 0.27, -0.1), "ink")
		var wing := SphereMesh.new()
		wing.radius = 0.04
		wing.height = 0.1
		Visuals.mesh_instance(_body, wing, Vector3(0.1 * side, 0.12, 0.0), "chick")
	# Llave de cuerda en la espalda, que gira al andar.
	_key = Node3D.new()
	_key.position = Vector3(0, 0.15, 0.12)
	_body.add_child(_key)
	Visuals.mesh_instance(_key, Visuals.box_mesh(Vector3(0.012, 0.012, 0.05)), Vector3(0, 0, 0.025), "metal")
	Visuals.mesh_instance(_key, Visuals.box_mesh(Vector3(0.08, 0.04, 0.01)), Vector3(0, 0, 0.055), "metal")
	# Pieza que lleva encima de la cabeza cuando va cargado.
	_load = Visuals.mesh_instance(_body, Visuals.brick_mesh(), Vector3(0, 0.38, -0.02), "coral")
	_load.scale = Vector3.ONE * 0.6
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
	_body.position.y = absf(sin(_time * 12.0)) * 0.03 if moving else 0.0
	if moving:
		_key.rotation.z += delta * 6.0
	_load.visible = _carrying
