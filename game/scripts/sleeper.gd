@tool
extends Node3D
## Papá. Está tumbado ENCIMA del sofá, así que desde aquí abajo no se le ve:
## el cojín de arriba se hunde con su peso y sube y baja al respirar, y por la
## rendija se cuela su ronquido. Con mucho ruido asoma los dedos por la rendija;
## si el ruido llega al máximo, mete la mano buscando el mando y va a por el
## becario más ruidoso. Corriendo se puede esquivar (aunque correr hace ruido).
## Este nodo va colocado en el suelo, justo debajo de la rendija del techo.

enum State { IDLE, PEEK, REACH, SLAM, RETRACT }

const PEEK_WORRY := 0.7
const DESCEND_SPEED := 10.0
const SEARCH_TIME := 1.8  # tiempo que tarda en decidirse a dar el manotazo
const SLAM_TIME := 0.22
const RETRACT_TIME := 1.3
const SEARCH_HEIGHT := 2.6
const SLAM_HEIGHT := 0.5

var _sag: MeshInstance3D
var _shoulder: Node3D
var _sleeve: MeshInstance3D
var _hand: Node3D
var _fingers: Array[Node3D] = []
var _zzz: Label3D
var _state := State.IDLE
var _state_time := 0.0
var _target_id := -1
var _target_fallback := Vector3.ZERO
var _slam_from := Vector3.ZERO
var _retract_from := Vector3.ZERO
var _time := 0.0
var _mumble := ""
var _mumble_timer := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		# Vista previa en el editor: la mano buscando bajo la rendija.
		_hand.global_position = global_position + Vector3(1.5, SEARCH_HEIGHT, 1.5)
		_update_arm()
		return
	add_to_group("sleeper")
	Game.game_event.connect(_on_game_event)
	_hand.global_position = _hidden_point()
	_update_arm()


func _build() -> void:
	var ceiling := Balance.CEILING_HEIGHT
	# La rendija entre cojines por la que entra la luz del salón.
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(5.0, 0.05, 1.3)), Vector3(0, ceiling - 0.03, 0), "worklight")

	# El cojín de arriba hundido por el peso de papá.
	var sag_mesh := SphereMesh.new()
	sag_mesh.radius = 7.0
	sag_mesh.height = 4.0
	sag_mesh.radial_segments = 32
	sag_mesh.rings = 16
	_sag = Visuals.mesh_instance(self, sag_mesh, Vector3(7.5, ceiling + 1.0, 4.0), "cushion")

	_zzz = Visuals.label(self, "Zzz", Vector3(0, ceiling - 1.2, 0.8), 120, Color(0.8, 0.85, 1.0))

	# Brazo (manga del pijama) y mano. Van en coordenadas globales.
	_shoulder = Node3D.new()
	_shoulder.top_level = true
	add_child(_shoulder)
	var sleeve_mesh := CylinderMesh.new()
	sleeve_mesh.top_radius = 0.55
	sleeve_mesh.bottom_radius = 0.6
	sleeve_mesh.height = 1.0
	sleeve_mesh.radial_segments = 16
	_sleeve = Visuals.mesh_instance(_shoulder, sleeve_mesh, Vector3.ZERO, "sleeve")
	_sleeve.rotation_degrees = Vector3(90, 0, 0)

	_hand = Node3D.new()
	_hand.top_level = true
	add_child(_hand)
	var palm := SphereMesh.new()
	palm.radius = 0.95
	palm.height = 0.7
	var palm_instance := Visuals.mesh_instance(_hand, palm, Vector3.ZERO, "skin")
	palm_instance.scale = Vector3(1.0, 1.0, 1.15)
	var cuff := CylinderMesh.new()
	cuff.top_radius = 0.62
	cuff.bottom_radius = 0.62
	cuff.height = 0.5
	var cuff_instance := Visuals.mesh_instance(_hand, cuff, Vector3(0, 0.2, 1.0), "sleeve")
	cuff_instance.rotation_degrees = Vector3(90, 0, 0)
	for i in 4:
		var knuckle := Node3D.new()
		knuckle.position = Vector3(-0.6 + i * 0.4, 0.0, -0.85)
		_hand.add_child(knuckle)
		var finger := CapsuleMesh.new()
		finger.radius = 0.19
		finger.height = 1.25 - absf(i - 1.5) * 0.15
		var finger_instance := Visuals.mesh_instance(knuckle, finger, Vector3(0, 0, -finger.height / 2.0 + 0.1), "skin")
		finger_instance.rotation_degrees = Vector3(90, 0, 0)
		_fingers.append(knuckle)
	var thumb := CapsuleMesh.new()
	thumb.radius = 0.21
	thumb.height = 1.0
	var thumb_instance := Visuals.mesh_instance(_hand, thumb, Vector3(-1.0, -0.05, -0.2), "skin")
	thumb_instance.rotation_degrees = Vector3(90, -45, 0)


func _hidden_point() -> Vector3:
	return global_position + Vector3(0, Balance.CEILING_HEIGHT + 1.8, 0)


func _peek_point() -> Vector3:
	return global_position + Vector3(0, Balance.CEILING_HEIGHT - 0.2, 0)


func _process(delta: float) -> void:
	_time += delta
	_sag.scale = Vector3(1.0, 1.0 + sin(_time * 1.0) * 0.06, 1.0)
	if Engine.is_editor_hint():
		return
	var worry := clampf(Game.noise / Balance.NOISE_MAX, 0.0, 1.0)
	_update_label(worry, delta)
	_state_time += delta
	match _state:
		State.IDLE, State.PEEK:
			_state = State.PEEK if worry >= PEEK_WORRY else State.IDLE
			var goal := _peek_point() if _state == State.PEEK else _hidden_point()
			_hand.global_position = _hand.global_position.lerp(goal, clampf(delta * 3.0, 0.0, 1.0))
			_hand.rotation.y = lerp_angle(_hand.rotation.y, PI, clampf(delta * 3.0, 0.0, 1.0))
			_wiggle_fingers(0.35 if _state == State.PEEK else 0.0)
		State.REACH:
			_reach(delta)
			_wiggle_fingers(0.5)
			if _state_time >= SEARCH_TIME:
				_slam_from = _hand.global_position
				_enter(State.SLAM)
		State.SLAM:
			var t := clampf(_state_time / SLAM_TIME, 0.0, 1.0)
			_hand.global_position = _slam_from.lerp(Vector3(_slam_from.x, SLAM_HEIGHT, _slam_from.z), t * t)
			_wiggle_fingers(0.0)
			if t >= 1.0:
				_resolve_slam()
				_retract_from = _hand.global_position
				_enter(State.RETRACT)
		State.RETRACT:
			var t := clampf(_state_time / RETRACT_TIME, 0.0, 1.0)
			if _state_time > 0.35:
				_hand.global_position = _retract_from.lerp(_hidden_point(), smoothstep(0.0, 1.0, t))
			if t >= 1.0:
				_enter(State.IDLE)
	_update_arm()


func _enter(state: State) -> void:
	_state = state
	_state_time = 0.0


## Baja por la rendija y persigue al objetivo (más despacio de lo que corre un becario).
func _reach(delta: float) -> void:
	var target := _target_position()
	var pos := _hand.global_position
	var flat := Vector3(target.x - pos.x, 0.0, target.z - pos.z)
	var dist := flat.length()
	if dist > 0.05:
		pos += flat / dist * minf(Balance.HAND_SPEED * delta, dist)
		_hand.rotation.y = lerp_angle(_hand.rotation.y, atan2(-flat.x, -flat.z), clampf(delta * 6.0, 0.0, 1.0))
	pos.y = move_toward(pos.y, SEARCH_HEIGHT, DESCEND_SPEED * delta)
	_hand.global_position = pos


func _target_position() -> Vector3:
	var node = Game.player_nodes.get(_target_id)
	if is_instance_valid(node):
		return node.global_position
	return _target_fallback


## El manotazo. Cada jugador comprueba si le ha dado a él (así lo que ve es
## justo lo que pasa en su pantalla).
func _resolve_slam() -> void:
	var me = Game.player_nodes.get(multiplayer.get_unique_id())
	if not is_instance_valid(me):
		return
	var to_me: Vector3 = me.global_position - _hand.global_position
	var flat_dist := Vector2(to_me.x, to_me.z).length()
	if flat_dist < 8.0:
		me.add_shake(clampf(1.0 - flat_dist / 8.0, 0.0, 1.0) * 0.35)
	if _target_id != multiplayer.get_unique_id():
		return
	var hud = get_tree().get_first_node_in_group("hud")
	if flat_dist <= Balance.HAND_HIT_RADIUS:
		me.knockback(_hand.global_position)
		if hud:
			hud.toast("¡MANOTAZO!", Color(1.0, 0.5, 0.35))
	elif hud:
		hud.toast("¡Te has librado por los pelos!", Color(0.6, 1.0, 0.6))


func _wiggle_fingers(amount: float) -> void:
	for i in _fingers.size():
		_fingers[i].rotation.x = sin(_time * 9.0 + float(i) * 0.8) * amount


## Coloca la manga entre la rendija y la muñeca.
func _update_arm() -> void:
	var shoulder_pos := global_position + Vector3(0, Balance.CEILING_HEIGHT + 2.0, 0)
	var wrist := _hand.global_position + _hand.global_transform.basis.z * 1.1 + Vector3(0, 0.2, 0)
	var to_wrist := wrist - shoulder_pos
	var length := to_wrist.length()
	_shoulder.visible = _hand.global_position.y < Balance.CEILING_HEIGHT + 0.5
	if length < 0.1:
		return
	_shoulder.global_transform = Transform3D(Basis.looking_at(to_wrist, Vector3.FORWARD), shoulder_pos)
	_sleeve.scale = Vector3(1.0, length, 1.0)
	_sleeve.position = Vector3(0, 0, -length / 2.0)


func _update_label(worry: float, delta: float) -> void:
	_zzz.position.y = Balance.CEILING_HEIGHT - 1.2 + sin(_time * 0.8) * 0.2
	_zzz.modulate = Color(0.8, 0.85, 1.0).lerp(Color(1.0, 0.4, 0.3), worry)
	if _state == State.REACH or _state == State.SLAM:
		_zzz.text = "¡¿Quién anda ahí?!"
		return
	if worry < 0.6:
		_zzz.text = "Zzz" if fmod(_time, 4.0) < 3.0 else "ZZZZ..."
		_mumble = ""
		return
	_mumble_timer -= delta
	if _mumble == "" or _mumble_timer <= 0.0:
		_mumble = Balance.DAD_MUMBLES[randi() % Balance.DAD_MUMBLES.size()]
		_mumble_timer = 3.5
	_zzz.text = _mumble


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	if ev_name != "snort":
		return
	_target_id = int(data.get("target", -1))
	_target_fallback = data.get("pos", global_position)
	_enter(State.REACH)
