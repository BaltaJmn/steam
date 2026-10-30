@tool
extends Node3D
## Clasificadora (hecha con palitos de helado y un clip): tolva arriba (entran
## migas mezcladas), manivela al lado y tres cubetas delante (salen separadas en
## palomitas, ganchitos y galleta). Con las mejoras aparecen la rueda del hámster
## y el tobogán de pajita hacia los cuencos.

var _crank_pivot: Node3D
var _wheel: Node3D
var _chute: Node3D
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
	# Cuerpo de la máquina
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(1.6, 1.0, 1.2)), Vector3(0, 0.5, 0), "wood")
	Visuals.static_box(self, Vector3(1.6, 1.0, 1.2), Vector3(0, 0.5, 0), Visuals.LAYER_WORLD)

	# Tolva (embudo)
	var funnel := CylinderMesh.new()
	funnel.top_radius = 0.9
	funnel.bottom_radius = 0.45
	funnel.height = 0.7
	funnel.radial_segments = 4
	var funnel_instance := Visuals.mesh_instance(self, funnel, Vector3(0, 1.35, 0), "metal")
	funnel_instance.rotation_degrees = Vector3(0, 45, 0)
	Visuals.static_box(
		self, Vector3(1.3, 0.7, 1.3), Vector3(0, 1.35, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT, "hopper"
	)
	_hopper_label = Visuals.label(self, "", Vector3(0, 2.1, 0), 44)

	# Manivela
	_crank_pivot = Node3D.new()
	_crank_pivot.position = Vector3(0.95, 0.7, 0)
	add_child(_crank_pivot)
	var axle := CylinderMesh.new()
	axle.top_radius = 0.06
	axle.bottom_radius = 0.06
	axle.height = 0.3
	var axle_instance := Visuals.mesh_instance(_crank_pivot, axle, Vector3(0.1, 0, 0), "metal")
	axle_instance.rotation_degrees = Vector3(0, 0, 90)
	Visuals.mesh_instance(_crank_pivot, Visuals.box_mesh(Vector3(0.06, 0.45, 0.06)), Vector3(0.25, 0.2, 0), "metal")
	var grip := CylinderMesh.new()
	grip.top_radius = 0.05
	grip.bottom_radius = 0.05
	grip.height = 0.25
	var grip_instance := Visuals.mesh_instance(_crank_pivot, grip, Vector3(0.36, 0.42, 0), "wood")
	grip_instance.rotation_degrees = Vector3(0, 0, 90)
	Visuals.static_box(self, Vector3(0.6, 0.9, 0.7), Vector3(1.2, 0.8, 0), Visuals.LAYER_INTERACT, "crank")

	# Cubetas de salida
	var i := 0
	for kind in Balance.KINDS:
		var x := (i - 1) * 0.6
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.5, 0.45, 0.5)), Vector3(x, 0.225, 1.0), kind)
		Visuals.static_box(
			self, Vector3(0.5, 0.6, 0.5), Vector3(x, 0.3, 1.0),
			Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT, "bin_%s" % kind
		)
		_bin_labels[kind] = Visuals.label(self, "", Vector3(x, 0.85, 1.05), 36)
		i += 1

	# Rueda del hámster de la familia (mejora "wheel")
	_wheel = Node3D.new()
	_wheel.position = Vector3(-1.25, 0.8, 0)
	add_child(_wheel)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.72
	var ring_instance := Visuals.mesh_instance(_wheel, ring, Vector3.ZERO, "wood")
	ring_instance.rotation_degrees = Vector3(0, 0, 90)
	_wheel.visible = false

	# Tobogán de pajita hacia los cuencos (mejora "chute")
	_chute = Node3D.new()
	add_child(_chute)
	var ramp := Visuals.mesh_instance(_chute, Visuals.box_mesh(Vector3(1.8, 0.08, 5.0)), Vector3(0, 0.25, 3.9), "metal")
	ramp.rotation_degrees = Vector3(-3, 0, 0)
	_chute.visible = false

	if Engine.is_editor_hint():
		_wheel.visible = true
		_chute.visible = true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _spin > 0.0:
		_crank_pivot.rotation.x += delta * 12.0 * _spin
		_spin = maxf(0.0, _spin - delta * 2.5)
	if _wheel.visible and Game.crumb_sum(Game.hopper) > 0:
		_wheel.rotation.x += delta * 3.0


func _on_changed(what: String, _id: int) -> void:
	if what in ["hopper", "bins", "economy", "all"]:
		_refresh()


func _refresh() -> void:
	var total: int = Game.crumb_sum(Game.hopper)
	if _last_hopper >= 0 and total < _last_hopper:
		_spin = 1.0
	_last_hopper = total
	_hopper_label.text = "Tolva: %d" % total if total > 0 else "Tolva vacía"
	for kind in Balance.KINDS:
		var bin_label: Label3D = _bin_labels[kind]
		bin_label.text = "%s: %d" % [Balance.KIND_NAMES[kind], int(Game.bins.get(kind, 0))]
	_wheel.visible = Game.upgrade_level("wheel") > 0
	_chute.visible = Game.upgrade_level("chute") > 0


func get_prompt(_player: Node, part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var load_kind: String = data["load_kind"]
	if part == "hopper":
		if load_kind == "mixed":
			return "[E] Vaciar %d migas en la tolva" % Game.load_total(data)
		return "Tolva: %d migas por clasificar" % Game.crumb_sum(Game.hopper)
	if part == "crank":
		if Game.crumb_sum(Game.hopper) == 0:
			return "Manivela (la tolva está vacía)"
		return "Mantén [E] para girar la manivela"
	if part.begins_with("bin_"):
		var kind := part.substr(4)
		var amount := int(Game.bins.get(kind, 0))
		var kind_name: String = Balance.KIND_NAMES[kind]
		if amount == 0:
			return "Cubeta de %s (vacía)" % kind_name
		if int(data["item"]) != -1 or (load_kind != "" and load_kind != kind):
			return "Cubeta de %s: %d (tienes las manos ocupadas)" % [kind_name, amount]
		return "[E] Llenar el cubo de %s (%d)" % [kind_name, amount]
	return ""


func interact(_player: Node, part: String) -> void:
	if part == "hopper":
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
