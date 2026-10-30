@tool
extends Node3D
## Montaña de monedas mezcladas. Encoge según se va vaciando.

const MAX_RADIUS := 3.2
const MAX_HEIGHT := 2.2
# Montoncitos alrededor del principal: [posición, escala].
const MOUNDS := [
	[Vector3(-2.2, 0, 1.0), 0.45], [Vector3(2.0, 0, 1.4), 0.38], [Vector3(0.6, 0, -2.3), 0.5],
]

var _cones: Array[MeshInstance3D] = []
var _cone_scales: Array[float] = []
var _shape: CylinderShape3D
var _collision: CollisionShape3D
var _last_scoop := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("pile")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	_add_cone(Vector3.ZERO, 1.0)
	for mound in MOUNDS:
		_add_cone(mound[0], mound[1])
	var body := StaticBody3D.new()
	body.collision_layer = Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	body.collision_mask = 0
	add_child(body)
	_shape = CylinderShape3D.new()
	_collision = CollisionShape3D.new()
	_collision.shape = _shape
	body.add_child(_collision)
	_apply_size(1.0)


func _add_cone(pos: Vector3, cone_scale: float) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.35 * cone_scale
	cone.bottom_radius = MAX_RADIUS * cone_scale
	cone.height = MAX_HEIGHT * cone_scale
	cone.radial_segments = 28
	cone.rings = 3
	cone.material = Visuals.mat("coins")
	var instance := Visuals.mesh_instance(self, cone, pos)
	_cones.append(instance)
	_cone_scales.append(cone_scale)


## Escala la montaña según la fracción que queda (0 = vacía, 1 = llena).
func _apply_size(fraction: float) -> void:
	var s := sqrt(clampf(fraction, 0.0, 1.0))
	for i in _cones.size():
		var cone := _cones[i]
		var height := MAX_HEIGHT * _cone_scales[i] * maxf(s, 0.05)
		cone.scale = Vector3(maxf(s, 0.1), maxf(s, 0.05), maxf(s, 0.1))
		cone.position.y = height / 2.0
		cone.visible = fraction > 0.0
	_shape.radius = maxf(0.3, MAX_RADIUS * 0.85 * s)
	_shape.height = maxf(0.2, MAX_HEIGHT * s)
	_collision.position.y = _shape.height / 2.0
	_collision.disabled = fraction <= 0.0


func _on_changed(what: String, _id: int) -> void:
	if what == "pile" or what == "all":
		_refresh()


func _refresh() -> void:
	_apply_size(Game.pile_fraction())


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	var total: int = Game.coin_sum(Game.pile)
	if data.is_empty() or total == 0:
		return ""
	var load_kind: String = data["load_kind"]
	if int(data["item"]) != -1 or (load_kind != "" and load_kind != "mixed"):
		return "Montaña de monedas (tienes las manos ocupadas)"
	if Game.load_total(data) >= Game.capacity():
		return "El saco está lleno: vacíalo en la tolva de la clasificadora"
	return "[E] Palear (mantén pulsado) · quedan %d monedas" % total


func interact(_player: Node, _part: String) -> void:
	_try_scoop()


func interact_hold(_player: Node, _part: String, _delta: float) -> void:
	_try_scoop()


func _try_scoop() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_scoop < Balance.SCOOP_COOLDOWN:
		return
	_last_scoop = now
	Game.request("_srv_scoop")
