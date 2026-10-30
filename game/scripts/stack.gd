@tool
extends Node3D
## Cuenco donde se juntan las migas ya clasificadas de un tipo. Se va llenando
## y queda lleno justo cuando está todo recogido.

const BOWL_HEIGHT := 0.9
const BOWL_TOP := 1.1
const BOWL_BOTTOM := 0.75

@export_enum("popcorn", "puff", "cookie") var kind: String = "popcorn"

var _fill_mesh: CylinderMesh
var _fill: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		_show_fraction(0.8)
		return
	add_to_group("stacks")
	Game.changed.connect(_on_changed)
	_refresh()


func _build() -> void:
	var bowl := CylinderMesh.new()
	bowl.top_radius = BOWL_TOP
	bowl.bottom_radius = BOWL_BOTTOM
	bowl.height = BOWL_HEIGHT
	bowl.radial_segments = 32
	bowl.cap_top = false
	var bowl_material := Visuals.mat("bowl").duplicate() as StandardMaterial3D
	bowl_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bowl.material = bowl_material
	Visuals.mesh_instance(self, bowl, Vector3(0, BOWL_HEIGHT / 2.0, 0))
	Visuals.static_box(
		self, Vector3(BOWL_TOP * 2.0, BOWL_HEIGHT, BOWL_TOP * 2.0), Vector3(0, BOWL_HEIGHT / 2.0, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	_fill_mesh = CylinderMesh.new()
	_fill_mesh.radial_segments = 32
	_fill_mesh.material = Visuals.mat(kind)
	_fill = Visuals.mesh_instance(self, _fill_mesh, Vector3.ZERO)
	_label = Visuals.label(self, "", Vector3(0, 2.0, 0), 56)


## Rellena el cuenco hasta la fracción indicada (0 = vacío, 1 = lleno).
func _show_fraction(fraction: float) -> void:
	var f := clampf(fraction, 0.0, 1.0)
	_fill.visible = f > 0.0
	var height := maxf(0.02, f * (BOWL_HEIGHT - 0.05))
	_fill_mesh.height = height
	_fill_mesh.bottom_radius = BOWL_BOTTOM - 0.03
	_fill_mesh.top_radius = lerpf(BOWL_BOTTOM, BOWL_TOP, height / BOWL_HEIGHT) - 0.03
	_fill.position.y = height / 2.0 + 0.02


func _on_changed(what: String, _id: int) -> void:
	if what == "stacks" or what == "all":
		_refresh()


func _refresh() -> void:
	var amount := int(Game.stacks.get(kind, 0))
	var total := int(Game.pile_start.get(kind, 0))
	_show_fraction(0.0 if total <= 0 else float(amount) / float(total))
	_label.text = "%s: %d / %d" % [str(Balance.KIND_NAMES[kind]).capitalize(), amount, total]


func get_prompt(_player: Node, _part: String) -> String:
	var data: Dictionary = Game.me()
	if data.is_empty():
		return ""
	var kind_name: String = Balance.KIND_NAMES[kind]
	var load_kind: String = data["load_kind"]
	if load_kind == kind:
		return "[E] Echar %d migas de %s" % [Game.load_total(data), kind_name]
	if load_kind == "mixed":
		return "Cuenco de %s: primero separa las migas en la clasificadora" % kind_name
	if load_kind != "":
		return "Cuenco de %s: aquí no van las de %s" % [kind_name, Balance.KIND_NAMES[load_kind]]
	return "Cuenco de %s" % kind_name


func interact(_player: Node, _part: String) -> void:
	Game.request("_srv_deposit", [kind])
