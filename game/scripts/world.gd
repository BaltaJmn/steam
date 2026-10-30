extends Node3D
## Monta la partida: si somos host, registra en Game lo que hay en la escena, y
## en todos los casos crea o borra los nodos de jugadores y hormigas según el
## estado compartido.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const WORKER_SCENE := preload("res://scenes/worker.tscn")

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
		Game.server_setup(_collect_items(), _collect_slots())
	Game.request("_srv_hello", [Network.player_name])
	_sync_players()
	_sync_workers()


func return_to_menu(message := "") -> void:
	Network.leave()
	Network.last_message = message
	Game.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_session_ended(reason: String) -> void:
	return_to_menu(reason)


## Puntos del mapa que necesitan las hormigas y papá (iguales en todos los
## jugadores, porque la escena es la misma).
func _register_anchors() -> void:
	var pile := get_tree().get_first_node_in_group("pile") as Node3D
	var sorter := get_tree().get_first_node_in_group("sorter") as Node3D
	var sleeper := get_tree().get_first_node_in_group("sleeper") as Node3D
	var board := get_tree().get_first_node_in_group("upgrade_board") as Node3D
	if pile and sorter:
		var dir := sorter.global_position - pile.global_position
		dir.y = 0.0
		dir = dir.normalized()
		Game.anchors["pile_point"] = pile.global_position + dir * 3.7
		Game.anchors["hopper_point"] = sorter.global_position - dir * 1.3
	if sleeper:
		Game.anchors["sleeper"] = sleeper.global_position
	if board:
		Game.anchors["worker_spawn"] = board.global_position + board.global_transform.basis.z * 1.5


func _collect_items() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Node3D
		var id := int(item.get("item_id"))
		if result.has(id):
			push_warning("Hay dos objetos con el mismo item_id: %d" % id)
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
			"yaw": slot.global_rotation.y, "item": -1,
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
