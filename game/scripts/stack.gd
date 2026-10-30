@tool
extends Node3D
## Torres de monedas de un tipo en la cámara acorazada. Se llenan columna a
## columna y quedan completas justo cuando está todo ordenado.

const COLUMNS_X := 5
const COLUMNS_Z := 4
const COLUMN_HEIGHT := 1.3
const SPACING := 0.34
const BASE_HEIGHT := 0.2

@export_enum("copper", "silver", "gold") var kind: String = "gold"

var _columns: Array[MeshInstance3D] = []
var _label: Label3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		_show_amount(1, 1)
		return
	add_to_group("stacks")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	var size := Vector3(COLUMNS_X * SPACING + 0.4, BASE_HEIGHT, COLUMNS_Z * SPACING + 0.4)
	Visuals.mesh_instance(self, Visuals.box_mesh(size), Vector3(0, BASE_HEIGHT / 2.0, 0), "rock")
	Visuals.static_box(
		self, Vector3(size.x, 1.0, size.z), Vector3(0, 0.5, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	var column_mesh := CylinderMesh.new()
	column_mesh.top_radius = 0.13
	column_mesh.bottom_radius = 0.13
	column_mesh.height = 1.0
	column_mesh.radial_segments = 14
	column_mesh.material = Visuals.mat(kind)
	for ix in COLUMNS_X:
		for iz in COLUMNS_Z:
			var pos := Vector3(
				(ix - (COLUMNS_X - 1) / 2.0) * SPACING, BASE_HEIGHT, (iz - (COLUMNS_Z - 1) / 2.0) * SPACING
			)
			var column := Visuals.mesh_instance(self, column_mesh, pos)
			column.visible = false
			_columns.append(column)
	_label = Visuals.label(self, "", Vector3(0, 2.2, 0), 56)


func _show_amount(amount: int, total: int) -> void:
	var per_column := maxf(1.0, float(total) / _columns.size())
	var remaining := float(amount)
	for column in _columns:
		var fill := clampf(remaining / per_column, 0.0, 1.0)
		remaining -= per_column
		column.visible = fill > 0.0
		var height := maxf(0.01, fill * COLUMN_HEIGHT)
		column.scale = Vector3(1, height, 1)
		column.position.y = BASE_HEIGHT + height / 2.0


func _on_changed(what: String, _id: int) -> void:
	if what == "stacks" or what == "all":
		_refresh()


func _refresh() -> void:
	var amount := int(Game.stacks.get(kind, 0))
	var total := int(Game.pile_start.get(kind, 0))
	_show_amount(amount, total)
	_label.text = "%s: %d / %d" % [str(Balance.KIND_NAMES[kind]).capitalize(), amount, total]


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var kind_name: String = Balance.KIND_NAMES[kind]
	var load_kind: String = data["load_kind"]
	if load_kind == kind:
		return "[E] Apilar %d monedas de %s" % [Game.load_total(data), kind_name]
	if load_kind == "mixed":
		return "Torre de %s: primero clasifica las monedas en la máquina" % kind_name
	if load_kind != "":
		return "Torre de %s: aquí no va el %s" % [kind_name, Balance.KIND_NAMES[load_kind]]
	return "Torre de %s" % kind_name


func interact(_player: Node, _part: String) -> void:
	Game.request("_srv_deposit", [kind])
