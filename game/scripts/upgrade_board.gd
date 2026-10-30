@tool
extends Node3D
## Tablón de mejoras de la empresa. Son de toda la cuadrilla (compartidas).
## La parte de delante mira hacia +Z.


func _ready() -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(2.2, 1.4, 0.1)), Vector3(0, 1.6, 0), "cork")
	# Notas pegadas (decoración)
	var notes := [[Vector3(-0.75, 1.15, 0.06), "note_yellow", 8.0], [Vector3(0.7, 1.12, 0.06), "note_pink", -6.0], [Vector3(0.85, 2.05, 0.06), "note_blue", 12.0]]
	for note in notes:
		var paper := Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.32, 0.32, 0.01)), note[0], note[1])
		paper.rotation_degrees = Vector3(0, 0, note[2])
	for x in [-1.0, 1.0]:
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.1, 2.3, 0.1)), Vector3(x, 1.15, -0.05), "wood")
	Visuals.static_box(
		self, Vector3(2.2, 2.3, 0.4), Vector3(0, 1.15, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	Visuals.label(self, "MEJORAS", Vector3(0, 2.0, 0.06), 96, Color(1.0, 0.88, 0.55), false)
	Visuals.label(self, Balance.COMPANY_NAME, Vector3(0, 1.65, 0.06), 30, Color(0.95, 0.9, 0.8), false)
	if Engine.is_editor_hint():
		return
	add_to_group("upgrade_board")


func get_prompt(_player: Node, _part: String) -> String:
	return "[E] Tablón de mejoras · calderilla: %d" % Game.wallet


func interact(_player: Node, _part: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_upgrades()
