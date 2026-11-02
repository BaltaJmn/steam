@tool
extends Node3D
## Grupito de piezas mezcladas tiradas por el suelo (los reparte FloorScatter).
## Se dibujan todas de golpe (MultiMesh) y van desapareciendo según se recogen,
## empezando por las de arriba. Las posiciones salen de una semilla fija, así
## que son iguales en todos los jugadores sin tener que mandarlas por red.

const EDITOR_PREVIEW := 7

@export var pile_id := 1
@export var radius := 0.3

var _multimesh: MultiMesh
var _layout := []  # [[color, Transform3D], ...] ordenado de abajo arriba
var _layout_counts := {}  # cuántas piezas de cada color caben en el reparto actual
var _last_scoop := 0.0


func _ready() -> void:
	_multimesh = Visuals.brick_multimesh(0)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _multimesh
	instance.material_override = Visuals.mat("bricks")
	add_child(instance)
	# Zona para apuntar y recoger. No es sólida (se puede andar entre las piezas)
	# y es baja, para que una pieza especial soltada encima se pueda seguir cogiendo.
	var area := Area3D.new()
	area.collision_layer = Visuals.LAYER_INTERACT
	area.collision_mask = 0
	area.monitoring = false
	var shape := CylinderShape3D.new()
	shape.radius = radius + 0.15
	shape.height = 0.25
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 0.125, 0)
	area.add_child(collision)
	add_child(area)
	if Engine.is_editor_hint():
		var preview := {}
		for i in EDITOR_PREVIEW:
			var kind: String = Balance.KINDS[i % Balance.KINDS.size()]
			preview[kind] = int(preview.get(kind, 0)) + 1
		_build_layout(preview)
		_show(preview)
		return
	add_to_group("piles")
	Game.changed.connect(_on_changed)
	_refresh()


## Reparte posiciones para unas cantidades de piezas: más amontonadas en el
## centro, giradas al azar y un poco inclinadas. Se calcula a partir de las
## cantidades iniciales del montón, así sale igual en todos los jugadores.
func _build_layout(counts: Dictionary) -> void:
	_layout_counts = counts.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + pile_id
	var colors := []
	for kind in Balance.KINDS:
		for i in int(counts.get(kind, 0)):
			colors.append(kind)
	# Mezcla determinista de los colores.
	for i in range(colors.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = colors[i]
		colors[i] = colors[j]
		colors[j] = tmp
	_layout = []
	for kind in colors:
		var angle := rng.randf_range(0.0, TAU)
		var dist := sqrt(rng.randf()) * radius
		var stack := int((1.0 - dist / radius) * 2.0 * rng.randf())
		var pos := Vector3(cos(angle) * dist, FigureData.BLOCK.y * (0.5 + stack * 0.8), sin(angle) * dist)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		basis = basis * Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.2)) * Basis(Vector3.FORWARD, rng.randf_range(-0.2, 0.2))
		_layout.append([kind, Transform3D(basis, pos)])
	_layout.sort_custom(func(a, b): return a[1].origin.y < b[1].origin.y)
	_multimesh.instance_count = _layout.size()
	for i in _layout.size():
		_multimesh.set_instance_color(i, Visuals.COLORS[_layout[i][0]])


## Enseña tantas piezas de cada color como queden (las de abajo primero).
func _show(counts: Dictionary) -> void:
	var shown := {}
	var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	for i in _layout.size():
		var kind: String = _layout[i][0]
		var visible_here := int(shown.get(kind, 0)) < int(counts.get(kind, 0))
		if visible_here:
			shown[kind] = int(shown.get(kind, 0)) + 1
		_multimesh.set_instance_transform(i, _layout[i][1] if visible_here else hidden)
	_multimesh.visible_instance_count = _layout.size()


func _on_changed(what: String, id: int) -> void:
	if what == "all" or (what == "pile" and id == pile_id):
		_refresh()


func _refresh() -> void:
	if not Game.piles.has(pile_id):
		return
	var counts: Dictionary = Game.piles[pile_id]
	if _layout.is_empty():
		_build_layout(Game.piles_start.get(pile_id, counts))
	# Si vuelven piezas de otro montón y no caben en el reparto, se rehace.
	var grown := false
	var wanted := _layout_counts.duplicate()
	for kind in Balance.KINDS:
		if int(counts.get(kind, 0)) > int(wanted.get(kind, 0)):
			wanted[kind] = int(counts.get(kind, 0))
			grown = true
	if grown:
		_build_layout(wanted)
	_show(counts)


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	var total: int = Game.piece_sum(Game.piles.get(pile_id, {}))
	if data.is_empty() or total == 0:
		return ""
	var load_kind: String = data["load_kind"]
	if int(data["item"]) != -1 or (load_kind != "" and load_kind != "mixed"):
		return "Piezas (tienes las manos ocupadas)"
	if Game.load_total(data) >= Game.capacity():
		return "La cesta está llena: vacíala en la tolva de la clasificadora"
	return "[E] Recoger piezas (mantén pulsado) · aquí hay %d" % total


func interact(player: Node, _part: String) -> void:
	_try_scoop(player)


func interact_hold(player: Node, _part: String, _delta: float) -> void:
	_try_scoop(player)


func _try_scoop(player: Node) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_scoop < Balance.SCOOP_COOLDOWN:
		return
	_last_scoop = now
	var data: Dictionary = Game.me()
	var has_pieces := Game.piece_sum(Game.piles.get(pile_id, {})) > 0
	if has_pieces and not data.is_empty() and Game.load_total(data) < Game.capacity() and data["load_kind"] in ["", "mixed"]:
		player.call("play_scoop")
	Game.request("_srv_scoop", [pile_id])
