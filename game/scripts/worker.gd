extends Node3D
## Hormiga contratada (con casco). Solo es visual: la lógica la lleva el host
## en Game. Mira hacia -Z y lleva la miga encima de la cabeza, como las de verdad.

var _target := Vector3.ZERO
var _carrying := false
var _body: Node3D
var _load: MeshInstance3D
var _time := 0.0


func _ready() -> void:
	_target = position
	_body = Node3D.new()
	add_child(_body)
	var segments := [[Vector3(0, 0.32, 0.3), 0.22], [Vector3(0, 0.32, 0.0), 0.14], [Vector3(0, 0.36, -0.28), 0.16]]
	for segment in segments:
		var sphere := SphereMesh.new()
		sphere.radius = segment[1]
		sphere.height = segment[1] * 2.0
		Visuals.mesh_instance(_body, sphere, segment[0], "ant")
	for side in [-1.0, 1.0]:
		for i in 3:
			var leg := CylinderMesh.new()
			leg.top_radius = 0.025
			leg.bottom_radius = 0.025
			leg.height = 0.5
			var leg_instance := Visuals.mesh_instance(_body, leg, Vector3(0.2 * side, 0.18, -0.12 + i * 0.12), "ant")
			leg_instance.rotation_degrees = Vector3(0, 0, 55.0 * side)
		var antenna := CylinderMesh.new()
		antenna.top_radius = 0.015
		antenna.bottom_radius = 0.015
		antenna.height = 0.35
		var antenna_instance := Visuals.mesh_instance(_body, antenna, Vector3(0.08 * side, 0.6, -0.4), "ant")
		antenna_instance.rotation_degrees = Vector3(-35, 0, 20.0 * side)
	var helmet := SphereMesh.new()
	helmet.radius = 0.17
	helmet.height = 0.17
	helmet.is_hemisphere = true
	Visuals.mesh_instance(_body, helmet, Vector3(0, 0.44, -0.28), "helmet")
	var crumb := SphereMesh.new()
	crumb.radius = 0.22
	crumb.height = 0.36
	_load = Visuals.mesh_instance(_body, crumb, Vector3(0, 0.75, -0.1), "crumbs")
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
	_body.position.y = absf(sin(_time * 16.0)) * 0.04 if moving else 0.0
	_load.visible = _carrying
