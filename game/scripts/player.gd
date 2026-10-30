extends CharacterBody3D
## Kobold jugador. El local se mueve con teclado y ratón; los remotos solo
## siguen la posición que les llega por red.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const JUMP_VELOCITY := 4.8
const MOUSE_SENSITIVITY := 0.0025
const SYNC_INTERVAL := 0.05
const NOISE_SEND_INTERVAL := 0.5

var peer_id := 1
var is_local := false
var display_name := "Kobold"
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
var _sack: MeshInstance3D

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
	else:
		camera.current = false


func _build_body() -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = color
	skin.roughness = 0.8
	var torso := CapsuleMesh.new()
	torso.radius = 0.32
	torso.height = 1.3
	torso.material = skin
	Visuals.mesh_instance(body, torso, Vector3(0, 0.65, 0))
	var snout := Visuals.box_mesh(Vector3(0.22, 0.16, 0.3))
	snout.material = skin
	Visuals.mesh_instance(body, snout, Vector3(0, 1.05, -0.32))
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.05
		eye.height = 0.1
		Visuals.mesh_instance(body, eye, Vector3(0.1 * side, 1.16, -0.27), "dark")
		var horn := CylinderMesh.new()
		horn.top_radius = 0.0
		horn.bottom_radius = 0.05
		horn.height = 0.2
		Visuals.mesh_instance(body, horn, Vector3(0.13 * side, 1.38, -0.05), "bone")
	var name_label := Visuals.label(self, display_name, Vector3(0, 1.75, 0), 40, color.lightened(0.3))
	# El jugador local no se ve a sí mismo (cámara en primera persona).
	body.visible = not is_local
	name_label.visible = not is_local

	_sack = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.3
	_sack.mesh = sphere
	_sack.visible = false
	hold_point.add_child(_sack)


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
	var speed := (SPRINT_SPEED if sprinting else WALK_SPEED) * _load_slowdown()
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	# Tras un resoplido del dragón casi no hay control durante un momento.
	var control := 1.0 if _knock_timer <= 0.0 else 0.05
	velocity.x = lerpf(velocity.x, direction.x * speed, control)
	velocity.z = lerpf(velocity.z, direction.z * speed, control)

	var was_on_floor := is_on_floor()
	move_and_slide()
	_knock_timer = maxf(0.0, _knock_timer - delta)

	if is_on_floor() and not was_on_floor:
		if _fall_speed > 5.0:
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
		var forward := -global_transform.basis.z
		Game.request("_srv_drop_item", [global_position + forward * 1.0])
	elif data["load_kind"] != "":
		Game.request("_srv_return_load")


func _update_sack() -> void:
	var data: Dictionary = Game.players.get(peer_id, {})
	var amount: int = Game.load_total(data)
	_sack.visible = amount > 0
	if amount <= 0:
		return
	var fraction := clampf(float(amount) / maxf(1.0, float(Game.capacity())), 0.0, 1.0)
	_sack.scale = Vector3.ONE * (0.6 + 0.8 * fraction)
	var kind: String = data["load_kind"]
	_sack.material_override = Visuals.mat("coins" if kind == "mixed" else kind)


func set_remote_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	_target_pos = pos
	_target_yaw = yaw
	_target_pitch = pitch


func get_hold_transform() -> Transform3D:
	return hold_point.global_transform


## Lo llama el dragón al resoplar si este jugador ha sido el más ruidoso.
func knockback(from: Vector3) -> void:
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	velocity = away * 11.0 + Vector3.UP * 7.0
	_knock_timer = 0.8
