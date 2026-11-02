@tool
extends Node3D
## Clasificadora: tolva arriba (entran piezas mezcladas), manivela al lado y
## seis cubetas delante, una por color. Con las mejoras aparecen el motorcito
## (gira sola) y la cinta que lleva las piezas a las figuras.

const BIN_SPACING := 0.62

var _crank_pivot: Node3D
var _motor: Node3D
var _fan: MeshInstance3D
var _belt: Node3D
var _hopper_label: Label3D
var _bin_labels := {}
var _spin := 0.0
var _last_hopper := -1
var _last_crank := 0.0


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	add_to_group("sorter")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	var width := BIN_SPACING * Balance.KINDS.size() + 0.4
	# Cuerpo de la máquina
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(width, 0.9, 1.3)), Vector3(0, 0.45, 0), "machine")
	Visuals.static_box(self, Vector3(width, 0.9, 1.3), Vector3(0, 0.45, 0), Visuals.LAYER_WORLD)

	# Tolva (embudo)
	var funnel := CylinderMesh.new()
	funnel.top_radius = 1.0
	funnel.bottom_radius = 0.5
	funnel.height = 0.75
	funnel.radial_segments = 24
	Visuals.mesh_instance(self, funnel, Vector3(0, 1.27, 0), "cream")
	Visuals.static_box(
		self, Vector3(1.8, 0.75, 1.8), Vector3(0, 1.27, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT, "hopper"
	)
	_hopper_label = Visuals.label(self, "", Vector3(0, 2.05, 0), 44)

	# Manivela
	_crank_pivot = Node3D.new()
	_crank_pivot.position = Vector3(width / 2.0 + 0.05, 0.6, 0)
	add_child(_crank_pivot)
	var axle := CylinderMesh.new()
	axle.top_radius = 0.06
	axle.bottom_radius = 0.06
	axle.height = 0.3
	var axle_instance := Visuals.mesh_instance(_crank_pivot, axle, Vector3(0.1, 0, 0), "metal")
	axle_instance.rotation_degrees = Vector3(0, 0, 90)
	Visuals.mesh_instance(_crank_pivot, Visuals.box_mesh(Vector3(0.06, 0.45, 0.06)), Vector3(0.25, 0.2, 0), "metal")
	var grip := SphereMesh.new()
	grip.radius = 0.09
	grip.height = 0.18
	Visuals.mesh_instance(_crank_pivot, grip, Vector3(0.36, 0.42, 0), "coral")
	Visuals.static_box(self, Vector3(0.7, 0.9, 0.7), Vector3(width / 2.0 + 0.35, 0.7, 0), Visuals.LAYER_INTERACT, "crank")

	# Cubetas de salida, una por color
	for i in Balance.KINDS.size():
		var kind: String = Balance.KINDS[i]
		var x := (i - (Balance.KINDS.size() - 1) / 2.0) * BIN_SPACING
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.52, 0.42, 0.52)), Vector3(x, 0.21, 0.98), kind)
		Visuals.static_box(
			self, Vector3(0.52, 0.6, 0.52), Vector3(x, 0.3, 0.98),
			Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT, "bin_%s" % kind
		)
		_bin_labels[kind] = Visuals.label(self, "", Vector3(x, 0.72, 1.05), 36)

	# Motorcito (mejora "wheel")
	_motor = Node3D.new()
	_motor.position = Vector3(-width / 2.0 - 0.35, 0.55, 0)
	add_child(_motor)
	Visuals.mesh_instance(_motor, Visuals.box_mesh(Vector3(0.5, 0.5, 0.5)), Vector3.ZERO, "sky")
	_fan = Visuals.mesh_instance(_motor, Visuals.box_mesh(Vector3(0.06, 0.6, 0.08)), Vector3(-0.3, 0, 0), "yellow")
	_motor.visible = false

	# Cinta transportadora (mejora "chute")
	_belt = Node3D.new()
	add_child(_belt)
	Visuals.mesh_instance(_belt, Visuals.box_mesh(Vector3(width - 0.2, 0.08, 1.2)), Vector3(0, 0.06, 1.95), "ink")
	_belt.visible = false

	if Engine.is_editor_hint():
		_motor.visible = true
		_belt.visible = true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _spin > 0.0:
		_crank_pivot.rotation.x += delta * 12.0 * _spin
		_spin = maxf(0.0, _spin - delta * 2.5)
	if _motor.visible and Game.piece_sum(Game.hopper) > 0:
		_fan.rotation.x += delta * 14.0


func _on_changed(what: String, _id: int) -> void:
	if what in ["hopper", "bins", "economy", "all"]:
		_refresh()


func _refresh() -> void:
	var total: int = Game.piece_sum(Game.hopper)
	if _last_hopper >= 0 and total < _last_hopper:
		_spin = 1.0
	_last_hopper = total
	_hopper_label.text = "Tolva: %d" % total if total > 0 else "Tolva vacía"
	for kind in Balance.KINDS:
		var amount := int(Game.bins.get(kind, 0))
		var bin_label: Label3D = _bin_labels[kind]
		bin_label.text = str(amount) if amount > 0 else ""
	_motor.visible = Game.upgrade_level("wheel") > 0
	_belt.visible = Game.upgrade_level("chute") > 0


func get_prompt(_player: Node, part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var load_kind: String = data["load_kind"]
	if part == "hopper":
		if load_kind == "mixed":
			return "[E] Vaciar %d piezas en la tolva" % Game.load_total(data)
		return "Tolva: %d piezas por clasificar" % Game.piece_sum(Game.hopper)
	if part == "crank":
		if Game.piece_sum(Game.hopper) == 0:
			return "Manivela (la tolva está vacía)"
		return "Mantén [E] para girar la manivela"
	if part.begins_with("bin_"):
		var kind := part.substr(4)
		var amount := int(Game.bins.get(kind, 0))
		var kind_name := Balance.pieces_name(kind)
		if amount == 0:
			return "Cubeta de %s (vacía)" % kind_name
		if int(data["item"]) != -1 or (load_kind != "" and load_kind != kind):
			return "Cubeta de %s: %d (tienes las manos ocupadas)" % [kind_name, amount]
		return "[E] Coger %s (%d)" % [kind_name, amount]
	return ""


func interact(player: Node, part: String) -> void:
	if part == "hopper":
		if Game.me().get("load_kind", "") == "mixed":
			player.call("play_dump")
		Game.request("_srv_dump")
	elif part == "crank":
		_try_crank()
	elif part.begins_with("bin_"):
		Game.request("_srv_take_bag", [part.substr(4)])


func interact_hold(_player: Node, part: String, _delta: float) -> void:
	if part == "crank":
		_try_crank()


func _try_crank() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_crank < Balance.CRANK_INTERVAL:
		return
	_last_crank = now
	Game.request("_srv_crank")
