extends Node
## Estado compartido de la partida (autoload "Game").
##
## Regla de oro: solo el host cambia el estado. Cualquiera pide cosas con
## request("_srv_algo", [...]); el host valida, aplica y reenvía a todos las
## partes que han cambiado. En solitario es igual, pero sin red.
## Los nodos del mundo escuchan la señal "changed" y se redibujan.

signal changed(what: String, id: int)
signal game_event(ev_name: String, data: Dictionary)

const REQUESTS := [
	"_srv_hello", "_srv_scoop", "_srv_dump", "_srv_crank", "_srv_take_bag", "_srv_deposit",
	"_srv_return_load", "_srv_pickup_item", "_srv_place_item", "_srv_drop_item", "_srv_buy",
	"_srv_noise",
]
const PLAYER_COLORS := [
	Color(0.4, 0.8, 0.35), Color(0.35, 0.6, 1.0), Color(1.0, 0.6, 0.25), Color(0.9, 0.45, 0.9),
]
const NET_INTERVAL := 0.1

# --- Estado sincronizado (lo manda el host) ---
var pile := {}
var pile_start := {}
var hopper := {}
var bins := {}
var stacks := {}
var items := {}  # id -> {type, state: "loose"/"held"/"placed", pos, yaw, holder, slot}
var slots := {}  # id -> {type, pos, yaw, item}
var players := {}  # peer_id -> {name, color, spawn, load_kind, load, item}
var wallet := 0
var upgrades := {}
var noise := 0.0
var workers_net := []  # [[posición, lleva_migas], ...]
var completed := false

# --- Solo local ---
var player_nodes := {}  # peer_id -> nodo Player
var player_pos := {}  # peer_id -> última posición conocida
var anchors := {}  # puntos del mapa que usan las hormigas y papá

# --- Solo en el host ---
var _world_ready := false
var _pending_hellos := []
var _dirty := {}
var _workers := []
var _player_noise := {}
var _last_action := {}
var _pay_remainder := 0
var _wheel_acc := 0.0
var _chute_acc := 0.0
var _net_timer := 0.0
var _noise_sent := -1.0
var _join_count := 0


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	reset()


func reset() -> void:
	pile = _zero_crumbs()
	pile_start = _zero_crumbs()
	hopper = _zero_crumbs()
	bins = _zero_crumbs()
	stacks = _zero_crumbs()
	items = {}
	slots = {}
	players = {}
	wallet = 0
	upgrades = {}
	for id in Balance.UPGRADE_ORDER:
		upgrades[id] = 0
	noise = 0.0
	workers_net = []
	completed = false
	player_nodes = {}
	player_pos = {}
	anchors = {}
	_world_ready = false
	_pending_hellos = []
	_dirty = {}
	_workers = []
	_player_noise = {}
	_last_action = {}
	_pay_remainder = 0
	_wheel_acc = 0.0
	_chute_acc = 0.0
	_net_timer = 0.0
	_noise_sent = -1.0
	_join_count = 0


## El host lo llama al cargar el mundo, con lo que hay colocado en la escena.
func server_setup(world_items: Dictionary, world_slots: Dictionary) -> void:
	for kind in Balance.KINDS:
		pile[kind] = int(Balance.PILE_START[kind])
		pile_start[kind] = int(Balance.PILE_START[kind])
	items = world_items
	slots = world_slots
	_world_ready = true
	changed.emit("all", 0)
	for pending in _pending_hellos:
		_handle_request(pending[0], "_srv_hello", [pending[1]])
	_pending_hellos.clear()


# --- Consultas (cualquiera puede usarlas) ---

func my_id() -> int:
	return multiplayer.get_unique_id()


func me() -> Dictionary:
	return players.get(my_id(), {})


func crumb_sum(crumbs: Dictionary) -> int:
	var total := 0
	for kind in Balance.KINDS:
		total += int(crumbs.get(kind, 0))
	return total


func load_total(player: Dictionary) -> int:
	if player.is_empty():
		return 0
	return crumb_sum(player["load"])


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func upgrade_value(id: String) -> float:
	var values: Array = Balance.UPGRADES[id]["values"]
	return float(values[mini(upgrade_level(id), values.size() - 1)])


## Coste del siguiente nivel, o -1 si ya está al máximo.
func upgrade_cost(id: String) -> int:
	var costs: Array = Balance.UPGRADES[id]["costs"]
	var level := upgrade_level(id)
	return int(costs[level]) if level < costs.size() else -1


func capacity() -> int:
	return int(upgrade_value("sack"))


func pile_fraction() -> float:
	var start := crumb_sum(pile_start)
	return 1.0 if start <= 0 else float(crumb_sum(pile)) / float(start)


func crumbs_sorted() -> int:
	return crumb_sum(stacks)


func crumbs_total() -> int:
	return crumb_sum(pile_start)


func items_placed() -> int:
	var placed := 0
	for id in items:
		if items[id]["state"] == "placed":
			placed += 1
	return placed


func is_complete() -> bool:
	if items.is_empty() or crumbs_total() == 0:
		return false
	return crumbs_sorted() >= crumbs_total() and items_placed() >= items.size()


# --- Peticiones al host ---

func request(method: String, args: Array = []) -> void:
	if method not in REQUESTS:
		push_error("Petición desconocida: %s" % method)
		return
	if multiplayer.is_server():
		_handle_request(my_id(), method, args)
	else:
		rpc_id(1, "_rpc_request", method, args)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request(method: String, args: Array) -> void:
	if multiplayer.is_server():
		_handle_request(multiplayer.get_remote_sender_id(), method, args)


func _handle_request(sender: int, method: String, args: Array) -> void:
	if method not in REQUESTS:
		return
	if method != "_srv_hello" and not players.has(sender):
		return
	callv(method, [sender] + args)
	_flush()


# --- Posición de los jugadores (cada uno manda la suya) ---

func send_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	player_pos[my_id()] = pos
	if Network.is_online():
		rpc("_rpc_transform", pos, yaw, pitch)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	var id := multiplayer.get_remote_sender_id()
	player_pos[id] = pos
	var node = player_nodes.get(id)
	if is_instance_valid(node):
		node.set_remote_transform(pos, yaw, pitch)


# --- Envío de estado del host a los demás ---

func _mark(key: String) -> void:
	_dirty[key] = true


func _flush() -> void:
	if _dirty.is_empty():
		return
	var keys := _dirty.keys()
	_dirty.clear()
	for key in keys:
		if Network.is_online():
			rpc("_rpc_part", key, _get_part(key))
		_emit_part(key)
	_check_complete()


func _get_part(key: String) -> Variant:
	var parts := key.split(":")
	var id := int(parts[1]) if parts.size() > 1 else 0
	match parts[0]:
		"pile":
			return pile
		"hopper":
			return hopper
		"bins":
			return bins
		"stacks":
			return stacks
		"economy":
			return {"wallet": wallet, "upgrades": upgrades}
		"item":
			return items.get(id)
		"slot":
			return slots.get(id)
		"player":
			return players.get(id)
	return null


@rpc("authority", "call_remote", "reliable")
func _rpc_part(key: String, value: Variant) -> void:
	var parts := key.split(":")
	var id := int(parts[1]) if parts.size() > 1 else 0
	match parts[0]:
		"pile":
			pile = value
		"hopper":
			hopper = value
		"bins":
			bins = value
		"stacks":
			stacks = value
		"economy":
			wallet = int(value["wallet"])
			upgrades = value["upgrades"]
		"item":
			items[id] = value
		"slot":
			slots[id] = value
		"player":
			if value == null:
				players.erase(id)
			else:
				players[id] = value
	_emit_part(key)


func _emit_part(key: String) -> void:
	var parts := key.split(":")
	var id := int(parts[1]) if parts.size() > 1 else 0
	changed.emit(parts[0], id)


func _snapshot() -> Dictionary:
	return {
		"pile": pile, "pile_start": pile_start, "hopper": hopper, "bins": bins,
		"stacks": stacks, "items": items, "slots": slots, "players": players,
		"wallet": wallet, "upgrades": upgrades, "noise": noise, "workers": workers_net,
		"completed": completed,
	}


@rpc("authority", "call_remote", "reliable")
func _rpc_snapshot(snapshot: Dictionary) -> void:
	pile = snapshot["pile"]
	pile_start = snapshot["pile_start"]
	hopper = snapshot["hopper"]
	bins = snapshot["bins"]
	stacks = snapshot["stacks"]
	items = snapshot["items"]
	slots = snapshot["slots"]
	players = snapshot["players"]
	wallet = int(snapshot["wallet"])
	upgrades = snapshot["upgrades"]
	noise = float(snapshot["noise"])
	workers_net = snapshot["workers"]
	completed = bool(snapshot["completed"])
	changed.emit("all", 0)


func _event(ev_name: String, data: Dictionary) -> void:
	if Network.is_online():
		rpc("_rpc_event", ev_name, data)
	game_event.emit(ev_name, data)


@rpc("authority", "call_remote", "reliable")
func _rpc_event(ev_name: String, data: Dictionary) -> void:
	if ev_name == "complete":
		completed = true
	game_event.emit(ev_name, data)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_noise(value: float) -> void:
	noise = value
	changed.emit("noise", 0)


@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_workers(data: Array) -> void:
	workers_net = data
	changed.emit("workers", 0)


# --- Lógica del host: peticiones de los jugadores ---

func _srv_hello(sender: int, player_name: String) -> void:
	if not _world_ready:
		_pending_hellos.append([sender, player_name])
		return
	if players.has(sender):
		return
	var clean := player_name.strip_edges().left(20)
	if clean == "":
		clean = "Becario"
	players[sender] = {
		"name": clean,
		"color": PLAYER_COLORS[_join_count % PLAYER_COLORS.size()],
		"spawn": _join_count % 4,
		"load_kind": "",
		"load": _zero_crumbs(),
		"item": -1,
	}
	_join_count += 1
	if sender != my_id() and Network.is_online():
		rpc_id(sender, "_rpc_snapshot", _snapshot())
	_mark("player:%d" % sender)
	_event("joined", {"name": clean})


func _srv_scoop(sender: int) -> void:
	var p: Dictionary = players[sender]
	if int(p["item"]) != -1 or p["load_kind"] not in ["", "mixed"]:
		return
	if not _cooldown_ok(sender, "scoop", Balance.SCOOP_COOLDOWN):
		return
	var space := capacity() - load_total(p)
	if space <= 0:
		return
	var taken := _take_mixed(pile, mini(int(upgrade_value("shovel")), space))
	if crumb_sum(taken) == 0:
		return
	_add_crumbs(p["load"], taken)
	p["load_kind"] = "mixed"
	_mark("pile")
	_mark("player:%d" % sender)


func _srv_dump(sender: int) -> void:
	var p: Dictionary = players[sender]
	if p["load_kind"] != "mixed":
		return
	_add_crumbs(hopper, p["load"])
	_clear_load(p)
	_add_noise(sender, Balance.NOISE_DUMP)
	_mark("hopper")
	_mark("player:%d" % sender)


func _srv_crank(sender: int) -> void:
	if crumb_sum(hopper) == 0:
		return
	if not _cooldown_ok(sender, "crank", Balance.CRANK_INTERVAL):
		return
	_sort_from_hopper(int(upgrade_value("crank")))
	_add_noise(sender, Balance.NOISE_CRANK)


func _srv_take_bag(sender: int, kind: String) -> void:
	if kind not in Balance.KINDS:
		return
	var p: Dictionary = players[sender]
	if int(p["item"]) != -1:
		return
	if p["load_kind"] != "" and p["load_kind"] != kind:
		return
	var amount := mini(capacity() - load_total(p), int(bins[kind]))
	if amount <= 0:
		return
	bins[kind] = int(bins[kind]) - amount
	p["load"][kind] = int(p["load"][kind]) + amount
	p["load_kind"] = kind
	_mark("bins")
	_mark("player:%d" % sender)


func _srv_deposit(sender: int, kind: String) -> void:
	var p: Dictionary = players[sender]
	if kind not in Balance.KINDS or p["load_kind"] != kind:
		return
	var amount := int(p["load"][kind])
	stacks[kind] = int(stacks[kind]) + amount
	_clear_load(p)
	_pay_for_crumbs(amount)
	_mark("stacks")
	_mark("player:%d" % sender)


## Soltar migas: vuelven a su sitio (las mezcladas a la montaña, las
## clasificadas a su cubeta).
func _srv_return_load(sender: int) -> void:
	var p: Dictionary = players[sender]
	match p["load_kind"]:
		"":
			return
		"mixed":
			_add_crumbs(pile, p["load"])
			_mark("pile")
		_:
			_add_crumbs(bins, p["load"])
			_mark("bins")
	_clear_load(p)
	_mark("player:%d" % sender)


func _srv_pickup_item(sender: int, item_id: int) -> void:
	var p: Dictionary = players[sender]
	if not items.has(item_id) or int(p["item"]) != -1 or p["load_kind"] != "":
		return
	var item: Dictionary = items[item_id]
	if item["state"] != "loose":
		return
	item["state"] = "held"
	item["holder"] = sender
	p["item"] = item_id
	_mark("item:%d" % item_id)
	_mark("player:%d" % sender)


func _srv_place_item(sender: int, slot_id: int) -> void:
	var p: Dictionary = players[sender]
	var item_id := int(p["item"])
	if item_id == -1 or not slots.has(slot_id) or not items.has(item_id):
		return
	var slot: Dictionary = slots[slot_id]
	var item: Dictionary = items[item_id]
	if int(slot["item"]) != -1 or slot["type"] != item["type"]:
		return
	item["state"] = "placed"
	item["holder"] = 0
	item["slot"] = slot_id
	item["pos"] = slot["pos"]
	item["yaw"] = slot["yaw"]
	slot["item"] = item_id
	p["item"] = -1
	wallet += Balance.ITEM_PAY
	_mark("item:%d" % item_id)
	_mark("slot:%d" % slot_id)
	_mark("player:%d" % sender)
	_mark("economy")


func _srv_drop_item(sender: int, pos: Vector3) -> void:
	var p: Dictionary = players[sender]
	var item_id := int(p["item"])
	if item_id == -1 or not items.has(item_id):
		return
	var item: Dictionary = items[item_id]
	item["state"] = "loose"
	item["holder"] = 0
	item["pos"] = Vector3(
		clampf(pos.x, -Balance.ROOM_HALF_X, Balance.ROOM_HALF_X),
		clampf(pos.y, 0.0, 5.0),
		clampf(pos.z, -Balance.ROOM_HALF_Z, Balance.ROOM_HALF_Z)
	)
	p["item"] = -1
	_add_noise(sender, Balance.NOISE_DROP)
	_mark("item:%d" % item_id)
	_mark("player:%d" % sender)


func _srv_buy(sender: int, upgrade_id: String) -> void:
	if not Balance.UPGRADES.has(upgrade_id):
		return
	var cost := upgrade_cost(upgrade_id)
	if cost < 0 or wallet < cost:
		return
	wallet -= cost
	upgrades[upgrade_id] = upgrade_level(upgrade_id) + 1
	_mark("economy")
	_event("bought", {
		"name": players[sender]["name"], "upgrade": upgrade_id, "level": upgrade_level(upgrade_id),
	})


func _srv_noise(sender: int, amount: float) -> void:
	_add_noise(sender, clampf(amount, 0.0, 25.0))


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server() or not players.has(id):
		return
	var p: Dictionary = players[id]
	var item_id := int(p["item"])
	if item_id != -1 and items.has(item_id):
		var item: Dictionary = items[item_id]
		var pos: Vector3 = player_pos.get(id, Vector3.ZERO)
		item["state"] = "loose"
		item["holder"] = 0
		item["pos"] = Vector3(pos.x, maxf(pos.y, 0.0), pos.z)
		_mark("item:%d" % item_id)
	_srv_return_load(id)
	players.erase(id)
	player_pos.erase(id)
	_player_noise.erase(id)
	_mark("player:%d" % id)
	_event("left", {"name": p["name"]})
	_flush()


# --- Lógica del host: automatización, hormigas y ruido ---

func _process(delta: float) -> void:
	if not _world_ready or not multiplayer.is_server():
		return
	_update_automation(delta)
	_update_workers(delta)
	noise = maxf(0.0, noise - Balance.NOISE_DECAY * delta)
	for id in _player_noise.keys():
		_player_noise[id] = float(_player_noise[id]) * exp(-delta / 4.0)
	_net_timer += delta
	if _net_timer >= NET_INTERVAL:
		_net_timer = 0.0
		_flush()
		_send_streams()


func _update_automation(delta: float) -> void:
	var wheel := upgrade_value("wheel")
	if wheel > 0.0 and crumb_sum(hopper) > 0:
		_wheel_acc += wheel * delta
		var to_sort := int(_wheel_acc)
		if to_sort > 0:
			_wheel_acc -= to_sort
			_sort_from_hopper(to_sort)
	else:
		_wheel_acc = 0.0

	var chute := upgrade_value("chute")
	if chute > 0.0 and crumb_sum(bins) > 0:
		_chute_acc += chute * delta
		var to_move := int(_chute_acc)
		if to_move > 0:
			_chute_acc -= to_move
			var moved := 0
			for kind in Balance.KINDS:
				var amount := mini(to_move, int(bins[kind]))
				bins[kind] = int(bins[kind]) - amount
				stacks[kind] = int(stacks[kind]) + amount
				moved += amount
			if moved > 0:
				_pay_for_crumbs(moved)
				_mark("bins")
				_mark("stacks")
	else:
		_chute_acc = 0.0


func _update_workers(delta: float) -> void:
	var wanted := int(upgrade_value("workers"))
	while _workers.size() < wanted:
		var spawn: Vector3 = anchors.get("worker_spawn", Vector3.ZERO)
		var offset := Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-0.6, 0.6))
		_workers.append({
			"pos": spawn + offset, "offset": offset, "state": "to_pile", "t": 0.0,
			"crumbs": _zero_crumbs(),
		})
	if not anchors.has("pile_point") or not anchors.has("hopper_point"):
		return
	var pile_point: Vector3 = anchors["pile_point"]
	var hopper_point: Vector3 = anchors["hopper_point"]
	for worker in _workers:
		var offset: Vector3 = worker["offset"]
		match worker["state"]:
			"to_pile":
				if _walk(worker, pile_point + offset, delta):
					worker["state"] = "scoop"
					worker["t"] = Balance.WORKER_SCOOP_TIME
			"scoop":
				worker["t"] = float(worker["t"]) - delta
				if float(worker["t"]) <= 0.0:
					var taken := _take_mixed(pile, Balance.WORKER_CAPACITY)
					if crumb_sum(taken) == 0:
						worker["state"] = "idle"
						worker["t"] = 1.0
					else:
						worker["crumbs"] = taken
						worker["state"] = "to_hopper"
						_mark("pile")
			"to_hopper":
				if _walk(worker, hopper_point + offset * 0.5, delta):
					worker["state"] = "dump"
					worker["t"] = Balance.WORKER_DUMP_TIME
			"dump":
				worker["t"] = float(worker["t"]) - delta
				if float(worker["t"]) <= 0.0:
					_add_crumbs(hopper, worker["crumbs"])
					worker["crumbs"] = _zero_crumbs()
					worker["state"] = "to_pile"
					_mark("hopper")
			"idle":
				worker["t"] = float(worker["t"]) - delta
				if float(worker["t"]) <= 0.0:
					worker["t"] = 1.0
					if crumb_sum(pile) > 0:
						worker["state"] = "to_pile"


## Mueve a la hormiga hacia el objetivo. Devuelve true al llegar.
func _walk(worker: Dictionary, target: Vector3, delta: float) -> bool:
	var pos: Vector3 = worker["pos"]
	var to := target - pos
	to.y = 0.0
	var dist := to.length()
	if dist < 0.2:
		return true
	worker["pos"] = pos + to / dist * minf(Balance.WORKER_SPEED * delta, dist)
	return false


func _send_streams() -> void:
	var data := []
	for worker in _workers:
		data.append([worker["pos"], crumb_sum(worker["crumbs"]) > 0])
	workers_net = data
	changed.emit("workers", 0)
	if Network.is_online() and not data.is_empty():
		rpc("_rpc_workers", data)
	if absf(noise - _noise_sent) > 0.05:
		_noise_sent = noise
		changed.emit("noise", 0)
		if Network.is_online():
			rpc("_rpc_noise", noise)


func _add_noise(sender: int, amount: float) -> void:
	if amount <= 0.0:
		return
	amount *= upgrade_value("boots")
	noise = minf(noise + amount, Balance.NOISE_MAX)
	_player_noise[sender] = float(_player_noise.get(sender, 0.0)) + amount
	if noise >= Balance.NOISE_MAX:
		_snort()


## Papá ronca fuerte y se da la vuelta: sale volando quien más ruido ha hecho.
func _snort() -> void:
	var target := -1
	var loudest := -1.0
	for id in _player_noise:
		if players.has(id) and float(_player_noise[id]) > loudest:
			loudest = float(_player_noise[id])
			target = int(id)
	noise = Balance.NOISE_AFTER_SNORT
	_player_noise.clear()
	_noise_sent = -1.0
	var who := ""
	if players.has(target):
		who = players[target]["name"]
	_event("snort", {"target": target, "name": who})


func _check_complete() -> void:
	if completed or not is_complete():
		return
	completed = true
	_event("complete", {})


# --- Utilidades ---

func _zero_crumbs() -> Dictionary:
	var empty := {}
	for kind in Balance.KINDS:
		empty[kind] = 0
	return empty


func _add_crumbs(target: Dictionary, source: Dictionary) -> void:
	for kind in Balance.KINDS:
		target[kind] = int(target.get(kind, 0)) + int(source.get(kind, 0))


func _clear_load(player: Dictionary) -> void:
	player["load"] = _zero_crumbs()
	player["load_kind"] = ""


func _sort_from_hopper(amount: int) -> void:
	var moved := _take_mixed(hopper, amount)
	if crumb_sum(moved) == 0:
		return
	_add_crumbs(bins, moved)
	_mark("hopper")
	_mark("bins")


## Saca "amount" migas de "source" respetando la proporción de cada tipo.
func _take_mixed(source: Dictionary, amount: int) -> Dictionary:
	var taken := _zero_crumbs()
	var total := crumb_sum(source)
	amount = mini(amount, total)
	if amount <= 0:
		return taken
	var count := 0
	for kind in Balance.KINDS:
		var share := int(floor(float(amount) * float(source[kind]) / float(total)))
		taken[kind] = share
		count += share
	# El resto (por redondeo) se reparte entre los tipos que aún tienen migas.
	var i := 0
	while count < amount:
		var kind: String = Balance.KINDS[i % Balance.KINDS.size()]
		if int(source[kind]) - int(taken[kind]) > 0:
			taken[kind] = int(taken[kind]) + 1
			count += 1
		i += 1
	for kind in Balance.KINDS:
		source[kind] = int(source[kind]) - int(taken[kind])
	return taken


func _pay_for_crumbs(amount: int) -> void:
	_pay_remainder += amount
	@warning_ignore("integer_division")
	var earned := _pay_remainder / Balance.CRUMBS_PER_PAY
	_pay_remainder -= earned * Balance.CRUMBS_PER_PAY
	if earned > 0:
		wallet += earned
		_mark("economy")


func _cooldown_ok(sender: int, action: String, seconds: float) -> bool:
	var key := "%d:%s" % [sender, action]
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_action.get(key, -100.0)) < seconds * 0.8:
		return false
	_last_action[key] = now
	return true
