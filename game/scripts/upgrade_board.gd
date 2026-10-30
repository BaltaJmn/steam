@tool
extends Node3D
## Tablón de mejoras. Las mejoras son de toda la tripulación (compartidas).
## La parte de delante mira hacia +Z.


func _ready() -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(2.2, 1.4, 0.1)), Vector3(0, 1.6, 0), "wood")
	for x in [-1.0, 1.0]:
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.1, 2.3, 0.1)), Vector3(x, 1.15, -0.05), "wood")
	Visuals.static_box(
		self, Vector3(2.2, 2.3, 0.4), Vector3(0, 1.15, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	Visuals.label(self, "MEJORAS", Vector3(0, 2.0, 0.06), 96, Color(1.0, 0.88, 0.55), false)
	Visuals.label(self, "para toda la tripulación", Vector3(0, 1.65, 0.06), 48, Color(0.95, 0.9, 0.8), false)
	if Engine.is_editor_hint():
		return
	add_to_group("upgrade_board")


func get_prompt(_player: Node, _part: String) -> String:
	return "[E] Tablón de mejoras · paga disponible: %d" % Game.wallet


func interact(_player: Node, _part: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_upgrades()
