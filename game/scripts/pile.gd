@tool
extends Node3D
## Montaña de migas mezcladas. Encoge según se va vaciando y, cuando no queda
## nada, deja a la vista lo que había debajo: EL MANDO DE LA TELE.

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
var _remote_label: Label3D
var _last_scoop := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("pile")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	_build_remote()
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


## El mando de la tele, enterrado bajo la montaña (a escala de becario es enorme).
func _build_remote() -> void:
	var remote := Node3D.new()
	remote.rotation_degrees = Vector3(0, 20, 0)
	add_child(remote)
	Visuals.mesh_instance(remote, Visuals.box_mesh(Vector3(0.9, 0.3, 2.6)), Vector3(0, 0.15, 0), "remote")
	var power := CylinderMesh.new()
	power.top_radius = 0.1
	power.bottom_radius = 0.1
	power.height = 0.06
	Visuals.mesh_instance(remote, power, Vector3(0.25, 0.32, -1.05), "red")
	for row in 4:
		for column in 3:
			var pos := Vector3(-0.25 + column * 0.25, 0.31, -0.5 + row * 0.3)
			Visuals.mesh_instance(remote, Visuals.box_mesh(Vector3(0.15, 0.04, 0.15)), pos, "white")
	Visuals.static_box(remote, Vector3(0.9, 0.3, 2.6), Vector3(0, 0.15, 0), Visuals.LAYER_WORLD)
	_remote_label = Visuals.label(self, "¡EL MANDO!", Vector3(0, 1.4, 0), 96, Color(1.0, 0.85, 0.3))
	_remote_label.visible = false


func _add_cone(pos: Vector3, cone_scale: float) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.35 * cone_scale
	cone.bottom_radius = MAX_RADIUS * cone_scale
	cone.height = MAX_HEIGHT * cone_scale
	cone.radial_segments = 28
	cone.rings = 3
	cone.material = Visuals.mat("crumbs")
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
	_remote_label.visible = fraction <= 0.0


func _on_changed(what: String, _id: int) -> void:
	if what == "pile" or what == "all":
		_refresh()


func _refresh() -> void:
	_apply_size(Game.pile_fraction())


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	var total: int = Game.crumb_sum(Game.pile)
	if data.is_empty() or total == 0:
		return ""
	var load_kind: String = data["load_kind"]
	if int(data["item"]) != -1 or (load_kind != "" and load_kind != "mixed"):
		return "Montaña de migas (tienes las manos ocupadas)"
	if Game.load_total(data) >= Game.capacity():
		return "El cubo está lleno: vacíalo en la tolva de la clasificadora"
	return "[E] Recoger migas (mantén pulsado) · quedan %d" % total


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
