extends Node
## Conexión de red (autoload "Network").
##
## El prototipo usa ENet (IP directa) para probar el coop en local. Para Steam
## se cambia el peer por el de GodotSteam en host() y join(); el resto del
## juego no se entera porque todo pasa por la API "multiplayer" de Godot.

signal connected_ok
signal connection_failed(reason: String)
signal session_ended(reason: String)

const PORT := 7777
const MAX_CLIENTS := 3  # 4 jugadores en total contando al host

var player_name := ""
var last_message := ""  # se muestra en el menú al volver (p. ej. "el host se ha ido")


func _ready() -> void:
	player_name = "Figurita %d" % (randi() % 900 + 100)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_solo() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func join(address: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func is_online() -> bool:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _on_connected() -> void:
	connected_ok.emit()


func _on_connection_failed() -> void:
	leave()
	connection_failed.emit("No se pudo conectar con el host.")


func _on_server_disconnected() -> void:
	leave()
	session_ended.emit("El host ha cerrado la partida.")
