@tool
extends Node3D
## Estantería con huecos. Los huecos se crean solos a partir de slot_types, con
## ids consecutivos desde first_slot_id. La parte de delante mira hacia +Z.

const SLOT_SCRIPT := preload("res://scripts/slot.gd")
const BOARD_HEIGHT := 0.94

@export var title := "Coronas"
@export var first_slot_id := 1
@export var slot_types := PackedStringArray(["crown_gold", "crown_gold", "crown_silver"])
@export var spacing := 0.8


func _ready() -> void:
	var count := slot_types.size()
	var width := maxf(1.2, spacing * count + 0.4)
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(width, 0.08, 0.6)), Vector3(0, BOARD_HEIGHT - 0.04, 0), "wood")
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(width, 1.8, 0.06)), Vector3(0, 0.9, -0.32), "wood")
	for x in [-width / 2.0 + 0.05, width / 2.0 - 0.05]:
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.08, BOARD_HEIGHT - 0.08, 0.55)), Vector3(x, (BOARD_HEIGHT - 0.08) / 2.0, 0), "wood")
	Visuals.static_box(self, Vector3(width, BOARD_HEIGHT, 0.65), Vector3(0, BOARD_HEIGHT / 2.0, 0), Visuals.LAYER_WORLD)
	Visuals.label(self, title, Vector3(0, 1.6, -0.27), 72, Color(1.0, 0.88, 0.55), false)
	for i in count:
		var slot = SLOT_SCRIPT.new()
		slot.slot_id = first_slot_id + i
		slot.type_key = slot_types[i]
		slot.position = Vector3(-spacing * (count - 1) / 2.0 + spacing * i, BOARD_HEIGHT, 0.0)
		add_child(slot)
