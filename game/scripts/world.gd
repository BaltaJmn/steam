extends Node3D
## Monta la partida: si somos host, registra en Game lo que hay en la escena, y
## en todos los casos crea o borra los nodos de jugadores y ayudantes según el
## estado compartido.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const WORKER_SCENE := preload("res://scenes/worker.tscn")
const PUPPY_SCRIPT := preload("res://scripts/puppy.gd")

@onready var players_root: Node3D = $Players
@onready var workers_root: Node3D = $Workers
@onready var spawn_points: Node3D = $SpawnPoints


func _ready() -> void:
	add_to_group("world")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.changed.connect(_on_game_changed)
	Network.session_ended.connect(_on_session_ended)
	_register_anchors()
	if multiplayer.is_server():
		Game.server_setup(_collect_figures(), _collect_pile_ids(), _collect_items(), _collect_slots())
	Game.request("_srv_hello", [Network.player_name])
	_sync_players()
	_sync_workers()
	# El perrito rastreador de este jugador (solo aparece si se compra).
	add_child(PUPPY_SCRIPT.new())


func return_to_menu(message := "") -> void:
	Network.leave()
	Network.last_message = message
	Game.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_session_ended(reason: String) -> void:
	return_to_menu(reason)


## Puntos del mapa que necesitan los ayudantes (iguales en todos los
## jugadores, porque la escena es la misma).
func _register_anchors() -> void:
	var board := get_tree().get_first_node_in_group("upgrade_board") as Node3D
	if board:
		Game.anchors["worker_spawn"] = board.global_position + board.global_transform.basis.z * 1.5
	var pile_points := {}
	for node in get_tree().get_nodes_in_group("piles"):
		var pile := node as Node3D
		pile_points[int(pile.get("pile_id"))] = pile.global_position
	Game.anchors["piles"] = pile_points
	# Delante de cada mesa, junto a su clasificador.
	var table_points := {}
	for node in get_tree().get_nodes_in_group("figures"):
		var table := node as Node3D
		table_points[int(table.get("figure_id"))] = table.global_position + table.global_transform.basis.z * 0.85
	Game.anchors["tables"] = table_points


func _collect_pile_ids() -> Array:
	var ids := []
	for node in get_tree().get_nodes_in_group("piles"):
		var id := int(node.get("pile_id"))
		if id in ids:
			push_warning("Hay dos montones con el mismo pile_id: %d" % id)
		ids.append(id)
	return ids


func _collect_figures() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("figures"):
		var id := int(node.get("figure_id"))
		if result.has(id):
			push_warning("Hay dos figuras con el mismo figure_id: %d" % id)
		var model := str(node.get("model"))
		var need := FigureData.color_counts(model)
		var have := {}
		for kind in need:
			have[kind] = 0
		result[id] = {"model": model, "need": need, "have": have, "done": false}
	return result


func _collect_items() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Node3D
		var id := int(item.get("item_id"))
		if result.has(id):
			push_warning("Hay dos piezas especiales con el mismo item_id: %d" % id)
		var pos := item.global_position
		result[id] = {
			"type": str(item.get("type_key")), "state": "loose", "pos": Vector3(pos.x, 0.0, pos.z),
			"yaw": item.global_rotation.y, "holder": 0, "slot": -1,
		}
	return result


func _collect_slots() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("slots"):
		var slot := node as Node3D
		var id := int(slot.get("slot_id"))
		if result.has(id):
			push_warning("Hay dos huecos con el mismo slot_id: %d" % id)
		result[id] = {
			"type": str(slot.get("type_key")), "pos": slot.global_position,
			"yaw": slot.global_rotation.y, "item": -1, "figure": int(slot.get("figure_id")),
		}
	return result


func _on_game_changed(what: String, _id: int) -> void:
	match what:
		"player":
			_sync_players()
		"workers":
			_sync_workers()
		"all":
			_sync_players()
			_sync_workers()


func _sync_players() -> void:
	for pid in Game.players:
		if not players_root.has_node(str(pid)):
			_spawn_player(int(pid))
	for child in players_root.get_children():
		var pid := int(String(child.name))
		if not Game.players.has(pid):
			Game.player_nodes.erase(pid)
			child.queue_free()


func _spawn_player(pid: int) -> void:
	var data: Dictionary = Game.players[pid]
	var is_local := pid == multiplayer.get_unique_id()
	var player = PLAYER_SCENE.instantiate()
	player.name = str(pid)
	player.setup(pid, is_local, data["name"], data["color"])
	var markers := spawn_points.get_children()
	if not is_local and Game.player_pos.has(pid):
		player.position = Game.player_pos[pid]
	elif not markers.is_empty():
		var marker := markers[int(data["spawn"]) % markers.size()] as Node3D
		player.position = marker.global_position
	players_root.add_child(player)
	Game.player_nodes[pid] = player


func _sync_workers() -> void:
	var data: Array = Game.workers_net
	while workers_root.get_child_count() < data.size():
		var worker = WORKER_SCENE.instantiate()
		var entry: Array = data[workers_root.get_child_count()]
		worker.position = entry[0]
		workers_root.add_child(worker)
	for i in mini(data.size(), workers_root.get_child_count()):
		var entry: Array = data[i]
		var worker = workers_root.get_child(i)
		worker.set_target(entry[0], entry[1])
