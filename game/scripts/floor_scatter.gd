@tool
extends Node3D
## Reparte por el suelo los grupitos de piezas (BrickPatch), también debajo de
## las mesas, y evita los muebles. Usa una semilla fija, así que la colocación
## es la misma en todos los jugadores. Cada grupito recibe un pile_id (1, 2...).

const PATCH_SCENE := preload("res://scenes/brick_patch.tscn")
# Zonas sin piezas: [centro x, centro z, medio ancho, medio fondo].
const AVOID := [
	[0.0, 0.0, 1.5, 1.0],  # clasificadora
	[8.4, 4.5, 0.7, 0.9],  # mueble del tocadiscos
	[0.0, -6.6, 1.5, 0.6],  # estantería
	[-8.2, -6.2, 0.8, 0.8],  # planta
	[8.2, 6.2, 0.8, 0.8],  # planta
	[-8.2, 5.8, 0.8, 0.8],  # planta
	[-8.3, -4.0, 0.6, 0.6],  # lámpara de pie
]

@export var cluster_count := 40
@export var seed_value := 7
@export var area := Rect2(-8.2, -6.1, 16.4, 12.2)
@export var min_spacing := 1.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var placed: Array[Vector3] = []
	var attempts := 0
	while placed.size() < cluster_count and attempts < cluster_count * 60:
		attempts += 1
		var pos := Vector3(
			rng.randf_range(area.position.x, area.end.x), 0.0, rng.randf_range(area.position.y, area.end.y)
		)
		if not _blocked(pos) and not _too_close(pos, placed):
			placed.append(pos)
	for i in placed.size():
		var patch = PATCH_SCENE.instantiate()
		patch.pile_id = i + 1
		patch.radius = rng.randf_range(0.22, 0.36)
		patch.position = placed[i]
		add_child(patch)


func _blocked(pos: Vector3) -> bool:
	for zone in AVOID:
		if absf(pos.x - zone[0]) < zone[2] and absf(pos.z - zone[1]) < zone[3]:
			return true
	return false


func _too_close(pos: Vector3, placed: Array[Vector3]) -> bool:
	for other in placed:
		if pos.distance_to(other) < min_spacing:
			return true
	return false
