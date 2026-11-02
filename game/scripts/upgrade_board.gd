@tool
extends Node3D
## Tienda de cositas monas, colgada en la pared. Lo que se compra es de todo el
## grupo (compartido) y ayuda a buscar piezas.
## La parte de delante mira hacia +Z; el nodo va a ras de suelo, pegado a la pared.

const CENTER_Y := 1.45


func _ready() -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(1.4, 0.9, 0.05)), Vector3(0, CENTER_Y, 0.025), "board")
	# Tres bloques de colores encima, de adorno.
	for i in 3:
		var brick := Visuals.mesh_instance(self, Visuals.brick_mesh(), Vector3(-0.2 + i * 0.2, CENTER_Y + 0.51, 0.09), Balance.KINDS[i])
		brick.rotation_degrees = Vector3(0, 8.0 * (i - 1), 0)
	Visuals.static_box(
		self, Vector3(1.4, 0.9, 0.3), Vector3(0, CENTER_Y, 0.15),
		Visuals.LAYER_WORLD | Visuals.LAYER_INTERACT
	)
	Visuals.label(self, "tienda", Vector3(0, CENTER_Y + 0.12, 0.06), 72, Color(0.35, 0.31, 0.33), false)
	Visuals.label(self, "cositas monas para buscar", Vector3(0, CENTER_Y - 0.15, 0.06), 32, Color(0.5, 0.45, 0.45), false)
	if Engine.is_editor_hint():
		return
	add_to_group("upgrade_board")


func get_prompt(_player: Node, _part: String) -> String:
	return "[E] Tienda de cositas monas · tienes %d pegatinas" % Game.wallet


func interact(_player: Node, _part: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_upgrades()
