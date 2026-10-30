@tool
extends Node3D
## El dragón dormido (greybox). Respira, se inquieta cuando hay mucho ruido y,
## si el ruido llega al máximo, resopla y manda volando al kobold más ruidoso.
## Está tumbado a lo largo del eje X con la cabeza hacia +X/+Z.

var _body: Node3D
var _head: Node3D
var _zzz: Label3D
var _flash: OmniLight3D
var _puff: GPUParticles3D
var _time := 0.0
var _snort_time := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("sleeper")
	Game.game_event.connect(_on_game_event)


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)

	var torso := CapsuleMesh.new()
	torso.radius = 1.6
	torso.height = 6.5
	var torso_instance := Visuals.mesh_instance(_body, torso, Vector3(0, 1.4, 0), "dragon")
	torso_instance.rotation_degrees = Vector3(0, 0, 90)

	var neck := CylinderMesh.new()
	neck.top_radius = 0.6
	neck.bottom_radius = 0.9
	neck.height = 2.4
	var neck_instance := Visuals.mesh_instance(_body, neck, Vector3(2.4, 1.3, 1.2), "dragon")
	neck_instance.rotation_degrees = Vector3(70, 0, -20)

	var tail := CylinderMesh.new()
	tail.top_radius = 0.08
	tail.bottom_radius = 0.75
	tail.height = 5.0
	var tail_instance := Visuals.mesh_instance(_body, tail, Vector3(-5.0, 0.6, 1.2), "dragon")
	tail_instance.rotation_degrees = Vector3(0, 30, 80)

	var wing := PrismMesh.new()
	wing.size = Vector3(4.0, 1.6, 0.12)
	for side in [-1.0, 1.0]:
		var wing_instance := Visuals.mesh_instance(_body, wing, Vector3(-0.5, 3.0, 0.7 * side), "dragon_wing")
		wing_instance.rotation_degrees = Vector3(-20.0 * side, 0, 0)

	_head = Node3D.new()
	_head.position = Vector3(3.0, 1.1, 2.4)
	_body.add_child(_head)
	var skull := SphereMesh.new()
	skull.radius = 0.9
	skull.height = 1.5
	Visuals.mesh_instance(_head, skull, Vector3.ZERO, "dragon")
	Visuals.mesh_instance(_head, Visuals.box_mesh(Vector3(0.9, 0.6, 1.2)), Vector3(0, -0.15, 0.9), "dragon")
	for side in [-1.0, 1.0]:
		var horn := CylinderMesh.new()
		horn.top_radius = 0.0
		horn.bottom_radius = 0.16
		horn.height = 0.8
		var horn_instance := Visuals.mesh_instance(_head, horn, Vector3(0.38 * side, 0.75, -0.35), "bone")
		horn_instance.rotation_degrees = Vector3(-35, 0, 0)
		# Ojos cerrados
		Visuals.mesh_instance(_head, Visuals.box_mesh(Vector3(0.3, 0.04, 0.03)), Vector3(0.36 * side, 0.22, 0.72), "dark")

	Visuals.static_box(self, Vector3(9.5, 3.2, 4.2), Vector3(-0.5, 1.6, 0.4), Visuals.LAYER_WORLD)

	_zzz = Visuals.label(self, "Zzz", Vector3(3.0, 3.2, 2.4), 110, Color(0.8, 0.85, 1.0))

	_flash = OmniLight3D.new()
	_flash.position = _head.position + Vector3(0, 0, 1.6)
	_flash.light_color = Color(1.0, 0.55, 0.2)
	_flash.light_energy = 0.0
	_flash.omni_range = 12.0
	add_child(_flash)

	_puff = GPUParticles3D.new()
	_puff.position = _head.position + Vector3(0, -0.1, 1.5)
	_puff.one_shot = true
	_puff.emitting = false
	_puff.amount = 48
	_puff.lifetime = 1.2
	_puff.explosiveness = 0.85
	var puff_process := ParticleProcessMaterial.new()
	puff_process.direction = Vector3(0, 0.1, 1)
	puff_process.spread = 25.0
	puff_process.initial_velocity_min = 4.0
	puff_process.initial_velocity_max = 8.0
	puff_process.gravity = Vector3(0, 1.5, 0)
	puff_process.scale_min = 0.4
	puff_process.scale_max = 1.2
	_puff.process_material = puff_process
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.15
	puff_mesh.height = 0.3
	puff_mesh.material = Visuals.mat("smoke")
	_puff.draw_pass_1 = puff_mesh
	add_child(_puff)


func _process(delta: float) -> void:
	_time += delta
	var breath := sin(_time * 1.1)
	_body.scale = Vector3(1.0, 1.0 + breath * 0.03, 1.0 + breath * 0.02)
	if Engine.is_editor_hint():
		return
	var worry := clampf(Game.noise / Balance.NOISE_MAX, 0.0, 1.0)
	if worry < 0.6:
		_zzz.text = "Zzz"
	elif worry < 0.85:
		_zzz.text = "¿Mmm...?"
	else:
		_zzz.text = "¡¿...?!"
	_zzz.position.y = 3.2 + sin(_time * 0.8) * 0.15
	_zzz.modulate = Color(0.8, 0.85, 1.0).lerp(Color(1.0, 0.35, 0.25), worry)
	_head.rotation.z = sin(_time * 23.0) * 0.1 * maxf(0.0, worry - 0.6)
	if _snort_time > 0.0:
		_snort_time = maxf(0.0, _snort_time - delta)
		_flash.light_energy = _snort_time * 14.0
		_head.position.y = 1.1 + _snort_time * 0.4


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	if ev_name != "snort":
		return
	_snort_time = 1.0
	_puff.restart()
	var target := int(data.get("target", -1))
	var node = Game.player_nodes.get(target)
	if target == multiplayer.get_unique_id() and is_instance_valid(node):
		node.knockback(_head.global_position)
