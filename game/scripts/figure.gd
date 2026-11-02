@tool
extends Node3D
## Mesa de una figura: una mesa sencilla con la figura encima y, delante, su
## clasificador: una bandeja con un compartimento por cada color que necesita,
## que se va llenando y dice cuántas lleva ("12/26"). Se deja la cesta tal cual
## y la mesa se queda solo con las piezas que le faltan; cada bloque aparece en
## su sitio en orden de montaje (de abajo arriba) sobre la silueta transparente.
## Las piezas especiales (ojos, puerta...) van en sus huecos. Toda la mesa es
## interactuable. La parte de delante mira a +Z.

const SLOT_SCRIPT := preload("res://scripts/slot.gd")
const TABLE_WIDTH := 1.3
const TABLE_HEIGHT := 0.75
const TABLE_DEPTH := 1.0
const TOP_THICKNESS := 0.05
const BOARD_HEIGHT := 0.02  # tablilla clara sobre la que se monta la figura
const BASE_HEIGHT := TABLE_HEIGHT + BOARD_HEIGHT
const FIGURE_Z := -0.15  # la figura va al fondo de la mesa...
const TRAY_Z := 0.3  # ...y el clasificador delante
const TRAY_SLOT_WIDTH := 0.36
const TRAY_SHOWN := 12  # piezas que se dibujan como mucho en cada compartimento

@export_enum("duck", "cat", "house", "tree", "boat", "rocket", "mushroom", "flower", "fish", "mug") var model: String = "duck"
@export var figure_id := 1
@export var first_slot_id := 1

var _blocks := []
var _solid: MultiMesh
var _ghost: MultiMesh
var _body: Node3D
var _label: Label3D
var _confetti: GPUParticles3D
var _placed := -1
var _bounce := 0.0
var _tray_kinds := []  # colores que necesita, en el orden de Balance.KINDS
var _tray_pieces := {}  # color -> MultiMesh con las piezas del compartimento
var _tray_labels := {}  # color -> Label3D "12/26"


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		_show_have(FigureData.color_counts(model))
		return
	add_to_group("figures")
	Game.changed.connect(_on_changed)
	Game.game_event.connect(_on_game_event)
	_refresh()


func _build() -> void:
	_blocks = FigureData.blocks(model)
	var cells := FigureData.cells(model)
	var size := Vector3(cells.x * FigureData.BLOCK.x, cells.y * FigureData.BLOCK.y, cells.z * FigureData.BLOCK.z)
	_build_table(size)
	_build_tray()
	Visuals.static_box(
		self, Vector3(size.x + 0.1, size.y + 0.05, size.z + 0.1), Vector3(0, BASE_HEIGHT + (size.y + 0.05) / 2.0, FIGURE_Z),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	_body = Node3D.new()
	_body.position = Vector3(0, BASE_HEIGHT, FIGURE_Z)
	add_child(_body)
	_solid = Visuals.brick_multimesh(_blocks.size())
	_ghost = Visuals.brick_multimesh(_blocks.size())
	for pair in [[_solid, "bricks"], [_ghost, "ghost"]]:
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = pair[0]
		instance.material_override = Visuals.mat(pair[1])
		_body.add_child(instance)
	_label = Visuals.label(self, "", Vector3(0, BASE_HEIGHT + size.y + 0.25, FIGURE_Z), 36)

	# Huecos de las piezas especiales.
	var specials: Array = FigureData.MODELS[model]["specials"]
	for i in specials.size():
		var spec: Array = specials[i]
		var slot = SLOT_SCRIPT.new()
		slot.slot_id = first_slot_id + i
		slot.type_key = spec[0]
		slot.figure_id = figure_id
		slot.position = _special_position(spec[0], spec[1], spec[2]) + Vector3(0, BASE_HEIGHT, FIGURE_Z)
		if spec[2] == "back":
			slot.rotation.y = PI
		add_child(slot)

	_confetti = GPUParticles3D.new()
	_confetti.position = Vector3(0, BASE_HEIGHT + size.y + 0.1, FIGURE_Z)
	_confetti.one_shot = true
	_confetti.emitting = false
	_confetti.amount = 40
	_confetti.lifetime = 1.4
	_confetti.explosiveness = 0.9
	var confetti_process := ParticleProcessMaterial.new()
	confetti_process.direction = Vector3(0, 1, 0)
	confetti_process.spread = 60.0
	confetti_process.initial_velocity_min = 1.2
	confetti_process.initial_velocity_max = 2.4
	confetti_process.gravity = Vector3(0, -3.0, 0)
	confetti_process.scale_min = 0.6
	confetti_process.scale_max = 1.2
	_confetti.process_material = confetti_process
	var confetti_mesh := Visuals.box_mesh(Vector3(0.03, 0.03, 0.008))
	confetti_mesh.material = Visuals.mat("yellow")
	_confetti.draw_pass_1 = confetti_mesh
	add_child(_confetti)


## Mesa de madera clara con cuatro patas y una tablilla crema encima.
func _build_table(figure_size: Vector3) -> void:
	var top_y := TABLE_HEIGHT - TOP_THICKNESS / 2.0
	var top := Vector3(TABLE_WIDTH, TOP_THICKNESS, TABLE_DEPTH)
	Visuals.mesh_instance(self, Visuals.box_mesh(top), Vector3(0, top_y, 0), "table_top")
	Visuals.static_box(self, top, Vector3(0, top_y, 0), Visuals.LAYER_WORLD)
	var leg_height := TABLE_HEIGHT - TOP_THICKNESS
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pos := Vector3(sx * (TABLE_WIDTH / 2.0 - 0.07), leg_height / 2.0, sz * (TABLE_DEPTH / 2.0 - 0.07))
			Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.05, leg_height, 0.05)), pos, "table")
			Visuals.static_box(self, Vector3(0.05, leg_height, 0.05), pos, Visuals.LAYER_WORLD)
	var board := Vector3(figure_size.x + 0.12, BOARD_HEIGHT, figure_size.z + 0.12)
	Visuals.mesh_instance(self, Visuals.box_mesh(board), Vector3(0, TABLE_HEIGHT + BOARD_HEIGHT / 2.0, FIGURE_Z), "baseplate")


## El clasificador de la mesa: una bandeja de madera con un compartimento por
## color (con el fondo de ese color), las piezas que ya tiene y su contador.
func _build_tray() -> void:
	var need := FigureData.color_counts(model)
	_tray_kinds = []
	for kind in Balance.KINDS:
		if need.has(kind):
			_tray_kinds.append(kind)
	var tray_width := TRAY_SLOT_WIDTH * _tray_kinds.size() + 0.06
	var tray_y := TABLE_HEIGHT + 0.0125
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(tray_width, 0.025, 0.22)), Vector3(0, tray_y, TRAY_Z), "table")
	var piece_scale := 0.4
	for i in _tray_kinds.size():
		var kind: String = _tray_kinds[i]
		var x := (i - (_tray_kinds.size() - 1) / 2.0) * TRAY_SLOT_WIDTH
		# Fondo del compartimento en su color, y separadores.
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(TRAY_SLOT_WIDTH - 0.05, 0.006, 0.17)), Vector3(x, tray_y + 0.015, TRAY_Z), kind)
		for side in [-1.0, 1.0]:
			Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.012, 0.04, 0.2)), Vector3(x + side * TRAY_SLOT_WIDTH / 2.0, tray_y + 0.03, TRAY_Z), "table")
		# Piezas del compartimento, en filas de 4.
		var pieces := Visuals.brick_multimesh(TRAY_SHOWN)
		for j in TRAY_SHOWN:
			var row := floorf(j / 4.0)
			var column := j % 4
			var pos := Vector3(x - 0.105 + column * 0.07, tray_y + 0.04 + floorf(row / 2.0) * 0.045, TRAY_Z - 0.035 + fmod(row, 2.0) * 0.07)
			pieces.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * piece_scale), pos))
			pieces.set_instance_color(j, Visuals.COLORS[kind])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = pieces
		instance.material_override = Visuals.mat("bricks")
		add_child(instance)
		_tray_pieces[kind] = pieces
		_tray_labels[kind] = Visuals.label(self, "", Vector3(x, tray_y + 0.17, TRAY_Z + 0.05), 26)


## Dónde va cada pieza especial respecto a su celda.
func _special_position(type_key: String, cell: Vector3i, face: String) -> Vector3:
	var center := FigureData.cell_center(model, cell)
	var height := Visuals.item_height(type_key)
	var gap := FigureData.BLOCK.z * 0.1
	match face:
		"front":
			return center + Vector3(0, -height / 2.0, FigureData.BLOCK.z / 2.0 + gap)
		"back":
			return center + Vector3(0, -height / 2.0, -(FigureData.BLOCK.z / 2.0 + gap))
		"top":
			return center + Vector3(0, FigureData.BLOCK.y / 2.0 + gap, 0)
	# "inside": un hueco dentro de la figura (la puerta, la ventanilla).
	return center + Vector3(0, -FigureData.BLOCK.y / 2.0, 0)


## Coloca como sólidos los bloques que ya tienen pieza y deja el resto como silueta.
func _show_have(have: Dictionary) -> void:
	var used := {}
	var solid_count := 0
	var ghost_count := 0
	for block in _blocks:
		var kind: String = block[1]
		var xform := Transform3D(Basis.IDENTITY, FigureData.cell_center(model, block[0]))
		if int(used.get(kind, 0)) < int(have.get(kind, 0)):
			used[kind] = int(used.get(kind, 0)) + 1
			_solid.set_instance_transform(solid_count, xform)
			_solid.set_instance_color(solid_count, Visuals.COLORS[kind])
			solid_count += 1
		else:
			_ghost.set_instance_transform(ghost_count, xform)
			ghost_count += 1
	_solid.visible_instance_count = solid_count
	_ghost.visible_instance_count = ghost_count
	if _placed >= 0 and solid_count > _placed:
		_bounce = 1.0
	_placed = solid_count
	_show_tray(have)


## Llena cada compartimento en proporción a lo que ya tiene y pone el contador.
func _show_tray(have: Dictionary) -> void:
	var need := FigureData.color_counts(model)
	for kind in _tray_kinds:
		var total := int(need[kind])
		var count := mini(int(have.get(kind, 0)), total)
		var pieces: MultiMesh = _tray_pieces[kind]
		pieces.visible_instance_count = ceili(float(count) / float(total) * TRAY_SHOWN) if count > 0 else 0
		var tray_label: Label3D = _tray_labels[kind]
		tray_label.text = "%d/%d" % [count, total]


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _bounce <= 0.0:
		return
	_bounce = maxf(0.0, _bounce - delta * 3.0)
	_body.scale = Vector3.ONE * (1.0 + sin(_bounce * PI) * 0.04)


func _on_changed(what: String, id: int) -> void:
	if what == "all" or (what == "figure" and id == figure_id):
		_refresh()


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	if ev_name == "figure_done" and int(data.get("figure", -1)) == figure_id:
		_confetti.restart()


func _refresh() -> void:
	if not Game.figures.has(figure_id):
		return
	var figure: Dictionary = Game.figures[figure_id]
	_show_have(figure["have"])
	var name_text: String = FigureData.MODELS[model]["name"]
	if bool(figure["done"]):
		_label.text = "%s · ¡terminado!" % name_text
	else:
		_label.text = "%s  %d / %d" % [name_text, Game.piece_sum(figure["have"]), _blocks.size()]


## Primer hueco libre de esta figura para un tipo de pieza especial.
func _free_slot_for(type_key: String) -> int:
	for id in Game.slots:
		var slot: Dictionary = Game.slots[id]
		if int(slot["figure"]) == figure_id and slot["type"] == type_key and int(slot["item"]) == -1:
			return int(id)
	return -1


func _missing_text() -> String:
	var parts := PackedStringArray()
	for kind in Balance.KINDS:
		var missing := Game.figure_missing(figure_id, kind)
		if missing > 0:
			parts.append("%d %s" % [missing, Balance.KIND_NAMES[kind]])
	return ", ".join(parts)


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty() or not Game.figures.has(figure_id):
		return ""
	var name_text: String = FigureData.MODELS[model]["name"]
	var held := int(data["item"])
	if held != -1 and Game.items.has(held):
		var type_key: String = Game.items[held]["type"]
		if _free_slot_for(type_key) != -1:
			return "[E] Poner: %s" % Balance.item_name(type_key)
		return "%s: esta pieza no va aquí" % name_text
	if data["load_kind"] != "":
		var takes: int = Game.figure_takes(figure_id, data["load"])
		if takes > 0:
			return "[E] Dejar piezas en el clasificador (%s se queda %d)" % [name_text, takes]
		return "%s: no necesita ninguna de las piezas que llevas" % name_text
	if bool(Game.figures[figure_id]["done"]):
		return "%s · ¡terminado!" % name_text
	var missing_text := _missing_text()
	if missing_text == "":
		return "%s · faltan las piezas especiales" % name_text
	return "%s · faltan: %s" % [name_text, missing_text]


func interact(player: Node, _part: String) -> void:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return
	var held := int(data["item"])
	if held != -1 and Game.items.has(held):
		var slot_id := _free_slot_for(Game.items[held]["type"])
		if slot_id != -1:
			Game.request("_srv_place_item", [slot_id])
		return
	if data["load_kind"] != "" and Game.figure_takes(figure_id, data["load"]) > 0:
		player.call("play_dump")
		Game.request("_srv_deposit", [figure_id])
