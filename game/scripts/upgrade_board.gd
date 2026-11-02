@tool
extends Node3D
## Tablón de mejoras. Son de todo el grupo (compartidas). La parte de delante
## mira hacia +Z.


func _ready() -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(2.2, 1.4, 0.12)), Vector3(0, 1.6, 0), "board")
	for x in [-1.0, 1.0]:
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.12, 2.3, 0.12)), Vector3(x, 1.15, -0.05), "wood")
	# Tres bloques de colores encima, de adorno.
	for i in 3:
		var brick := Visuals.mesh_instance(self, Visuals.brick_mesh(), Vector3(-0.5 + i * 0.5, 2.5, 0), Balance.KINDS[i])
		brick.scale = Vector3.ONE * 0.7
	Visuals.static_box(
		self, Vector3(2.2, 2.3, 0.4), Vector3(0, 1.15, 0),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	Visuals.label(self, "MEJORAS", Vector3(0, 1.85, 0.07), 96, Color(0.3, 0.28, 0.36), false)
	Visuals.label(self, "para todo el grupo", Vector3(0, 1.45, 0.07), 44, Color(0.45, 0.42, 0.5), false)
	if Engine.is_editor_hint():
		return
	add_to_group("upgrade_board")


func get_prompt(_player: Node, _part: String) -> String:
	return "[E] Tablón de mejoras · pegatinas: %d" % Game.wallet


func interact(_player: Node, _part: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_upgrades()
