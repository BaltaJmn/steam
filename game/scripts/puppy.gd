extends Node3D
## Perrito rastreador (cosita de la tienda). Cada jugador ve el suyo: corre
## hasta el grupito de piezas más cercano a ti, se sienta, mueve la cola y
## ladra. Cuando llegas, busca el siguiente. Si no queda nada, te sigue.
## Es solo una pista visual: no toca el estado de la partida. Mira hacia -Z.

var _body: Node3D
var _tail: Node3D
var _bark: Label3D
var _time := 0.0
var _target_pile := -1
var _bark_time := 0.0
var _was_visible := false


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var torso := CapsuleMesh.new()
	torso.radius = 0.09
	torso.height = 0.32
	var torso_instance := Visuals.mesh_instance(_body, torso, Vector3(0, 0.16, 0), "pup")
	torso_instance.rotation_degrees = Vector3(90, 0, 0)
	var head := SphereMesh.new()
	head.radius = 0.085
	head.height = 0.17
	Visuals.mesh_instance(_body, head, Vector3(0, 0.27, -0.15), "pup")
	var snout := SphereMesh.new()
	snout.radius = 0.04
	snout.height = 0.07
	Visuals.mesh_instance(_body, snout, Vector3(0, 0.25, -0.23), "pup")
	var nose := SphereMesh.new()
	nose.radius = 0.015
	nose.height = 0.03
	Visuals.mesh_instance(_body, nose, Vector3(0, 0.26, -0.27), "ink")
	for side in [-1.0, 1.0]:
		var ear := SphereMesh.new()
		ear.radius = 0.035
		ear.height = 0.11
		var ear_instance := Visuals.mesh_instance(_body, ear, Vector3(0.07 * side, 0.29, -0.13), "pup_ear")
		ear_instance.rotation_degrees = Vector3(0, 0, 25.0 * side)
		var eye := SphereMesh.new()
		eye.radius = 0.012
		eye.height = 0.024
		Visuals.mesh_instance(_body, eye, Vector3(0.035 * side, 0.29, -0.215), "ink")
		for z in [-0.08, 0.08]:
			var leg := CapsuleMesh.new()
			leg.radius = 0.025
			leg.height = 0.1
			Visuals.mesh_instance(_body, leg, Vector3(0.05 * side, 0.05, z), "pup")
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.2, 0.15)
	_body.add_child(_tail)
	var tail := CapsuleMesh.new()
	tail.radius = 0.018
	tail.height = 0.12
	var tail_instance := Visuals.mesh_instance(_tail, tail, Vector3(0, 0.05, 0.02), "pup_ear")
	tail_instance.rotation_degrees = Vector3(-30, 0, 0)
	_bark = Visuals.label(self, "¡guau!", Vector3(0, 0.55, 0), 32)
	_bark.visible = false
	visible = false


func _process(delta: float) -> void:
	_time += delta
	var me = Game.player_nodes.get(Game.my_id())
	visible = Game.upgrade_level("puppy") > 0 and is_instance_valid(me)
	if not visible:
		_was_visible = false
		return
	var player_pos: Vector3 = me.global_position
	if not _was_visible:
		# Aparece a tus pies la primera vez.
		_was_visible = true
		global_position = Vector3(player_pos.x + 0.5, 0.0, player_pos.z + 0.5)
	var target := _choose_target(player_pos)
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	var moving := dist > 0.35
	if moving:
		global_position += to / dist * minf(Balance.PUPPY_SPEED * delta, dist - 0.3)
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(delta * 8.0, 0.0, 1.0))
		_body.position.y = absf(sin(_time * 14.0)) * 0.03
	else:
		_body.position.y = 0.0
	# Mueve la cola: deprisa al llegar, despacito caminando.
	_tail.rotation.y = sin(_time * (18.0 if not moving else 8.0)) * 0.6
	_bark_time = maxf(0.0, _bark_time - delta)
	_bark.visible = _bark_time > 0.0


## El grupito con piezas más cercano al jugador. Si el jugador ya está encima,
## el siguiente más cercano. Si no queda ninguno, la posición del jugador.
func _choose_target(player_pos: Vector3) -> Vector3:
	var pile_points: Dictionary = Game.anchors.get("piles", {})
	if pile_points.has(_target_pile) and Game.piece_sum(Game.piles.get(_target_pile, {})) > 0:
		var current: Vector3 = pile_points[_target_pile]
		if player_pos.distance_to(current) > 1.0:
			return current
	var best := -1
	var best_dist := INF
	for pile_id in pile_points:
		if Game.piece_sum(Game.piles.get(pile_id, {})) == 0:
			continue
		var pos: Vector3 = pile_points[pile_id]
		var dist := player_pos.distance_to(pos)
		if dist > 1.0 and dist < best_dist:
			best_dist = dist
			best = int(pile_id)
	if best == -1:
		_target_pile = -1
		return player_pos + Vector3(0.6, 0.0, 0.6)
	if best != _target_pile:
		_target_pile = best
		_bark_time = 1.2
	return pile_points[best]
