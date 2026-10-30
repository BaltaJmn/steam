@tool
extends Node3D
## Papá, dormido en el sofá (greybox). Solo asoman su cabezota, apoyada al fondo,
## y una mano enorme. Ronca, murmura cuando hay mucho ruido y, si el ruido llega
## al máximo, ronca fuerte, da un manotazo y manda volando al becario más ruidoso.

var _head: Node3D
var _hand: Node3D
var _zzz: Label3D
var _snore_puff: GPUParticles3D
var _time := 0.0
var _snort_time := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("sleeper")
	Game.game_event.connect(_on_game_event)


func _build() -> void:
	_build_head()
	_build_hand()
	Visuals.static_box(self, Vector3(8.0, 6.5, 6.5), Vector3(0, 3.0, -1.0), Visuals.LAYER_WORLD)
	_zzz = Visuals.label(self, "Zzz", Vector3(3.0, 6.8, 0.5), 120, Color(0.8, 0.85, 1.0))

	_snore_puff = GPUParticles3D.new()
	_snore_puff.position = Vector3(0, 1.5, 2.2)
	_snore_puff.one_shot = true
	_snore_puff.emitting = false
	_snore_puff.amount = 40
	_snore_puff.lifetime = 1.4
	_snore_puff.explosiveness = 0.8
	var puff_process := ParticleProcessMaterial.new()
	puff_process.direction = Vector3(0, 0.2, 1)
	puff_process.spread = 30.0
	puff_process.initial_velocity_min = 5.0
	puff_process.initial_velocity_max = 9.0
	puff_process.gravity = Vector3(0, 0.5, 0)
	puff_process.scale_min = 0.5
	puff_process.scale_max = 1.4
	_snore_puff.process_material = puff_process
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.2
	puff_mesh.height = 0.4
	puff_mesh.material = Visuals.mat("snore")
	_snore_puff.draw_pass_1 = puff_mesh
	add_child(_snore_puff)


## Cabeza apoyada en el reposabrazos: calva con corona de pelo, bigote,
## ojos cerrados y la boca abierta de roncar.
func _build_head() -> void:
	_head = Node3D.new()
	_head.position = Vector3(0, 3.0, -1.0)
	add_child(_head)
	var skull := SphereMesh.new()
	skull.radius = 3.2
	skull.height = 6.0
	Visuals.mesh_instance(_head, skull, Vector3.ZERO, "skin")
	var hair_ring := TorusMesh.new()
	hair_ring.inner_radius = 2.5
	hair_ring.outer_radius = 3.4
	var hair_instance := Visuals.mesh_instance(_head, hair_ring, Vector3(0, 0.9, -0.4), "hair")
	hair_instance.rotation_degrees = Vector3(-15, 0, 0)
	var nose := SphereMesh.new()
	nose.radius = 0.85
	nose.height = 1.5
	Visuals.mesh_instance(_head, nose, Vector3(0, -0.2, 3.1), "skin")
	var moustache := Visuals.mesh_instance(_head, Visuals.box_mesh(Vector3(2.6, 0.45, 0.7)), Vector3(0, -0.95, 2.85), "hair")
	moustache.rotation_degrees = Vector3(-10, 0, 0)
	var mouth := SphereMesh.new()
	mouth.radius = 0.55
	mouth.height = 0.7
	var mouth_instance := Visuals.mesh_instance(_head, mouth, Vector3(0, -1.6, 2.55), "dark")
	mouth_instance.scale = Vector3(1.3, 0.8, 0.5)
	for side in [-1.0, 1.0]:
		# Ojos cerrados y cejas
		Visuals.mesh_instance(_head, Visuals.box_mesh(Vector3(0.9, 0.12, 0.12)), Vector3(1.1 * side, 0.7, 2.95), "dark")
		Visuals.mesh_instance(_head, Visuals.box_mesh(Vector3(1.0, 0.25, 0.25)), Vector3(1.1 * side, 1.2, 2.85), "hair")
		var ear := SphereMesh.new()
		ear.radius = 0.7
		ear.height = 1.6
		Visuals.mesh_instance(_head, ear, Vector3(3.1 * side, 0.0, 0.0), "skin")


## Mano gigante apoyada en el cojín, junto a la cabeza.
func _build_hand() -> void:
	_hand = Node3D.new()
	_hand.position = Vector3(6.0, 0.0, 1.5)
	_hand.rotation_degrees = Vector3(0, -20, 0)
	add_child(_hand)
	Visuals.mesh_instance(_hand, Visuals.box_mesh(Vector3(2.2, 0.9, 2.4)), Vector3(0, 0.45, 0), "skin")
	for i in 4:
		var finger := CapsuleMesh.new()
		finger.radius = 0.28
		finger.height = 1.8
		var finger_instance := Visuals.mesh_instance(_hand, finger, Vector3(-0.8 + i * 0.53, 0.35, 1.9), "skin")
		finger_instance.rotation_degrees = Vector3(90, 0, 0)
	var thumb := CapsuleMesh.new()
	thumb.radius = 0.3
	thumb.height = 1.5
	var thumb_instance := Visuals.mesh_instance(_hand, thumb, Vector3(-1.4, 0.35, 0.6), "skin")
	thumb_instance.rotation_degrees = Vector3(90, -50, 0)
	Visuals.static_box(_hand, Vector3(2.4, 0.9, 3.8), Vector3(0, 0.45, 0.8), Visuals.LAYER_WORLD)


func _process(delta: float) -> void:
	_time += delta
	var breath := sin(_time * 1.1)
	_head.scale = Vector3.ONE * (1.0 + breath * 0.015)
	if Engine.is_editor_hint():
		return
	var worry := clampf(Game.noise / Balance.NOISE_MAX, 0.0, 1.0)
	if worry < 0.6:
		_zzz.text = "Zzz"
	elif worry < 0.85:
		_zzz.text = "Mmm... cinco minutos más..."
	else:
		_zzz.text = "¡¿Quién ha cogido el mando?!"
	_zzz.position.y = 6.8 + sin(_time * 0.8) * 0.2
	_zzz.modulate = Color(0.8, 0.85, 1.0).lerp(Color(1.0, 0.4, 0.3), worry)
	_head.rotation.z = sin(_time * 19.0) * 0.06 * maxf(0.0, worry - 0.6)
	_hand.position.y = 0.0
	if _snort_time > 0.0:
		_snort_time = maxf(0.0, _snort_time - delta)
		# Manotazo: la mano sube y vuelve a caer de golpe.
		_hand.position.y = sin(_snort_time * PI) * 2.5


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	if ev_name != "snort":
		return
	_snort_time = 1.0
	_snore_puff.restart()
	var target := int(data.get("target", -1))
	var node = Game.player_nodes.get(target)
	if target == multiplayer.get_unique_id() and is_instance_valid(node):
		node.knockback(_head.global_position)
