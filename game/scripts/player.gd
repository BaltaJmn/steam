extends CharacterBody3D
## Figurita (jugador). El local se mueve con teclado y ratón; los remotos solo
## siguen la posición que les llega por red.

const WALK_SPEED := 3.2
const SPRINT_SPEED := 5.2
const JUMP_VELOCITY := 4.0
const MOUSE_SENSITIVITY := 0.0025
const SYNC_INTERVAL := 0.05
const NOISE_SEND_INTERVAL := 0.5
# Cesta según el nivel de la mejora "Cesta más grande": [radio, alto, color].
const BASKETS := [[0.2, 0.14, "cream"], [0.23, 0.16, "sky"], [0.26, 0.18, "mint"], [0.3, 0.2, "coral"]]
const BASKET_SHOWN := 12  # piezas que se dibujan dentro de la cesta como mucho

var peer_id := 1
var is_local := false
var display_name := "Figurita"
var color := Color.WHITE

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _hud = null
var _sync_timer := 0.0
var _noise_acc := 0.0
var _noise_timer := 0.0
var _fall_speed := 0.0
var _knock_timer := 0.0
var _target_pos := Vector3.ZERO
var _target_yaw := 0.0
var _target_pitch := 0.0
var _spawn_pos := Vector3.ZERO
var _container: Node3D
var _container_level := -1
var _basket_pieces: MultiMesh
var _last_load := {}
var _burst: GPUParticles3D
var _burst_mesh: BoxMesh
var _bob_time := 0.0
var _shake := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var ray: RayCast3D = $Head/Camera/Ray
@onready var hold_point: Node3D = $Head/Camera/HoldPoint


## Se llama antes de añadirlo a la escena.
func setup(id: int, local: bool, player_name: String, player_color: Color) -> void:
	peer_id = id
	is_local = local
	display_name = player_name
	color = player_color


func _ready() -> void:
	_target_pos = global_position
	_spawn_pos = global_position
	_build_body()
	_hud = get_tree().get_first_node_in_group("hud")
	if is_local:
		camera.make_current()
		_build_first_person()
	else:
		camera.current = false


func _build_body() -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	# Figurita de madera muy simple: cuerpo del color del jugador, cabeza y ojos.
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 0.6
	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 1.05
	torso.material = paint
	Visuals.mesh_instance(body, torso, Vector3(0, 0.55, 0))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	Visuals.mesh_instance(body, head_mesh, Vector3(0, 1.28, 0), "skin")
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.035
		eye.height = 0.07
		Visuals.mesh_instance(body, eye, Vector3(0.08 * side, 1.31, -0.22), "ink")
	var name_label := Visuals.label(self, display_name, Vector3(0, 1.8, 0), 40, color.darkened(0.35))
	# El jugador local no se ve a sí mismo (cámara en primera persona).
	body.visible = not is_local
	name_label.visible = not is_local

	_container = Node3D.new()
	_container.visible = false
	hold_point.add_child(_container)


## Lo que solo ve el jugador local: las piezas que saltan al recoger y vaciar.
func _build_first_person() -> void:
	_burst = GPUParticles3D.new()
	_burst.top_level = true
	_burst.one_shot = true
	_burst.emitting = false
	_burst.amount = 16
	_burst.lifetime = 0.7
	_burst.explosiveness = 1.0
	var burst_process := ParticleProcessMaterial.new()
	burst_process.direction = Vector3(0, 1, 0)
	burst_process.spread = 55.0
	burst_process.initial_velocity_min = 1.5
	burst_process.initial_velocity_max = 3.5
	burst_process.gravity = Vector3(0, -9.8, 0)
	burst_process.scale_min = 0.5
	burst_process.scale_max = 1.0
	_burst.process_material = burst_process
	_burst_mesh = Visuals.box_mesh(Vector3(0.05, 0.04, 0.05))
	_burst.draw_pass_1 = _burst_mesh
	add_child(_burst)


func _unhandled_input(event: InputEvent) -> void:
	if not is_local or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion:
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x, -1.45, 1.45)


func _physics_process(delta: float) -> void:
	if not is_local:
		var weight := clampf(delta * 12.0, 0.0, 1.0)
		global_position = global_position.lerp(_target_pos, weight)
		rotation.y = lerp_angle(rotation.y, _target_yaw, weight)
		head.rotation.x = lerp_angle(head.rotation.x, _target_pitch, weight)
		_update_sack()
		return

	var controls := _controls_enabled()
	if not is_on_floor():
		velocity.y -= _gravity * delta
		_fall_speed = maxf(_fall_speed, -velocity.y)

	var input := Vector2.ZERO
	if controls:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	var sprinting := controls and Input.is_action_pressed("sprint") and input.length() > 0.1
	var speed := (SPRINT_SPEED if sprinting else WALK_SPEED) * _load_slowdown() * Game.upgrade_value("speed")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	# Tras un manotazo de papá casi no hay control durante un momento.
	var control := 1.0 if _knock_timer <= 0.0 else 0.05
	velocity.x = lerpf(velocity.x, direction.x * speed, control)
	velocity.z = lerpf(velocity.z, direction.z * speed, control)

	var was_on_floor := is_on_floor()
	move_and_slide()
	_knock_timer = maxf(0.0, _knock_timer - delta)

	if is_on_floor() and not was_on_floor:
		if _fall_speed > Balance.NOISE_LAND_MIN_SPEED:
			_noise_acc += Balance.NOISE_LAND
		_fall_speed = 0.0
	if sprinting and is_on_floor():
		_noise_acc += Balance.NOISE_SPRINT * delta
	if global_position.y < -5.0:
		global_position = _spawn_pos
		velocity = Vector3.ZERO

	_send_noise(delta)
	_send_transform(delta)
	_update_interaction(delta, controls)
	_update_sack()
	_update_camera_feel(delta)


func _controls_enabled() -> bool:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	return _hud == null or not _hud.is_menu_open()


func _load_slowdown() -> float:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return 1.0
	if int(data["item"]) != -1:
		return 0.9
	var fraction := float(Game.load_total(data)) / maxf(1.0, float(Game.capacity()))
	return lerpf(1.0, 0.75, clampf(fraction, 0.0, 1.0))


func _send_transform(delta: float) -> void:
	_sync_timer += delta
	if _sync_timer < SYNC_INTERVAL:
		return
	_sync_timer = 0.0
	Game.send_transform(global_position, rotation.y, head.rotation.x)


func _send_noise(delta: float) -> void:
	if not Balance.NOISE_ENABLED:
		return
	_noise_timer += delta
	if _noise_timer < NOISE_SEND_INTERVAL or _noise_acc <= 0.0:
		return
	_noise_timer = 0.0
	Game.request("_srv_noise", [_noise_acc])
	_noise_acc = 0.0


## Mira qué hay delante (raycast), muestra el aviso y reenvía la interacción.
## Los objetos interactuables implementan get_prompt() e interact(), y
## opcionalmente interact_hold() para acciones de mantener pulsado.
func _update_interaction(delta: float, controls: bool) -> void:
	var target = null
	var part := ""
	if ray.is_colliding():
		var node := ray.get_collider() as Node
		if node:
			part = str(node.get_meta("part", ""))
		while node and not node.has_method("get_prompt"):
			node = node.get_parent()
		target = node
	var prompt := ""
	if target:
		prompt = target.get_prompt(self, part)
	if _hud:
		_hud.set_prompt(prompt if controls else "")
	if not controls:
		return
	if target and Input.is_action_just_pressed("interact"):
		target.interact(self, part)
	if target and Input.is_action_pressed("interact") and target.has_method("interact_hold"):
		target.interact_hold(self, part, delta)
	if Input.is_action_just_pressed("drop"):
		_drop()


func _drop() -> void:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return
	if int(data["item"]) != -1:
		Game.request("_srv_drop_item", [_drop_position()])
	elif data["load_kind"] != "":
		Game.request("_srv_return_load")


## Suelta el objeto a tus pies (dentro de tu propio hueco, así nunca queda
## metido dentro de un cuenco o una máquina) y sobre lo que haya debajo.
func _drop_position() -> Vector3:
	var origin := global_position - global_transform.basis.z * 0.3 + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 3.0, Visuals.LAYER_WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector3(origin.x, 0.0, origin.z)
	return hit["position"]


## La cesta que llevas en la mano (crece con la mejora) y las piezas dentro,
## con sus colores de verdad.
func _update_sack() -> void:
	var level := Game.upgrade_level("sack")
	if level != _container_level:
		_build_container(level)
	var data: Dictionary = Game.players.get(peer_id, {})
	var amount: int = Game.load_total(data)
	_container.visible = amount > 0
	if amount <= 0 or data["load"] == _last_load:
		return
	_last_load = data["load"].duplicate()
	var shown := 0
	for kind in Balance.KINDS:
		for i in int(data["load"].get(kind, 0)):
			if shown >= BASKET_SHOWN:
				break
			_basket_pieces.set_instance_color(shown, Visuals.COLORS[kind])
			shown += 1
	_basket_pieces.visible_instance_count = shown


func _build_container(level: int) -> void:
	_container_level = level
	_last_load = {}
	for child in _container.get_children():
		child.queue_free()
	var spec: Array = BASKETS[clampi(level, 0, BASKETS.size() - 1)]
	var radius: float = spec[0]
	var height: float = spec[1]
	var basket := CylinderMesh.new()
	basket.top_radius = radius
	basket.bottom_radius = radius * 0.85
	basket.height = height
	basket.cap_top = false
	var basket_material := Visuals.mat(spec[2]).duplicate() as StandardMaterial3D
	basket_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	basket.material = basket_material
	Visuals.mesh_instance(_container, basket, Vector3(0, height / 2.0, 0))
	# Piezas dentro de la cesta (algo más pequeñas), en capas de 2x2.
	_basket_pieces = Visuals.brick_multimesh(BASKET_SHOWN)
	var piece_scale := 0.7
	for i in BASKET_SHOWN:
		var layer := floorf(i / 4.0)
		var cell := i % 4
		var pos := Vector3((float(cell % 2) - 0.5) * 0.12, 0.05 + layer * 0.08, (floorf(cell / 2.0) - 0.5) * 0.12)
		var basis := Basis(Vector3.UP, float(i) * 0.7).scaled(Vector3.ONE * piece_scale)
		_basket_pieces.set_instance_transform(i, Transform3D(basis, pos))
	var pieces := MultiMeshInstance3D.new()
	pieces.multimesh = _basket_pieces
	pieces.material_override = Visuals.mat("bricks")
	_container.add_child(pieces)


## Balanceo al andar y temblor de cámara.
func _update_camera_feel(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and speed > 0.5:
		_bob_time += delta * speed * 2.2
	var bob := sin(_bob_time) * 0.035 * clampf(speed / WALK_SPEED, 0.0, 1.5)
	_shake = maxf(0.0, _shake - delta * 0.8)
	camera.v_offset = bob + randf_range(-1.0, 1.0) * _shake * 0.3
	camera.h_offset = randf_range(-1.0, 1.0) * _shake * 0.3


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Efectos de recoger piezas del suelo (los llama el montón).
func play_scoop() -> void:
	_play_burst(Balance.KINDS[randi() % Balance.KINDS.size()])


## Efectos de vaciar la cesta (los llaman la tolva y las figuras).
func play_dump() -> void:
	var data: Dictionary = Game.me()
	if data.is_empty() or data["load_kind"] == "":
		return
	var kind: String = data["load_kind"]
	_play_burst(Balance.KINDS[randi() % Balance.KINDS.size()] if kind == "mixed" else kind)


func _play_burst(material_key: String) -> void:
	if _burst == null or not ray.is_colliding():
		return
	_burst_mesh.material = Visuals.mat(material_key)
	_burst.global_position = ray.get_collision_point()
	_burst.restart()


func set_remote_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	_target_pos = pos
	_target_yaw = yaw
	_target_pitch = pitch


func get_hold_transform() -> Transform3D:
	return hold_point.global_transform


## Empujón (lo usaría una amenaza como papá; ahora el ruido está desactivado).
func knockback(from: Vector3) -> void:
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	velocity = away * 11.0 + Vector3.UP * 7.0
	_knock_timer = 0.8
