@tool
class_name Balance
extends RefCounted
## Todos los números y textos de diseño en un solo sitio, para equilibrar sin
## tocar la lógica. Los valores son de prototipo (partida corta para probar).

# Tamaño jugable del suelo (mitad en X y en Z, en metros).
const ROOM_HALF_X := 17.0
const ROOM_HALF_Z := 14.0

# --- Piezas ---
# Las piezas del suelo son exactamente las que hacen falta para las 6 figuras
# (las cuenta FigureData a partir de las maquetas).
const KINDS := ["yellow", "coral", "sky", "mint", "cream", "cocoa"]
# Se usa como "piezas <nombre>".
const KIND_NAMES := {
	"mixed": "mezcladas", "yellow": "amarillas", "coral": "rojas", "sky": "azules",
	"mint": "verdes", "cream": "blancas", "cocoa": "marrones",
}
const PIECES_PER_PAY := 1  # pegatinas por cada pieza colocada en una figura
const ITEM_PAY := 5  # pegatinas por cada pieza especial colocada
const FIGURE_BONUS := 10  # pegatinas al terminar una figura
const SCOOP_COOLDOWN := 0.35
const CRANK_INTERVAL := 0.25

# --- Ruido (desactivado: el tono es cozy) ---
# El sistema sigue en Game por si se quiere recuperar una amenaza suave.
const NOISE_ENABLED := false
const NOISE_MAX := 100.0
const NOISE_AFTER_SNORT := 30.0
const NOISE_DECAY := 4.0
const NOISE_SPRINT := 14.0
const NOISE_LAND := 7.0
const NOISE_LAND_MIN_SPEED := 3.0
const NOISE_DUMP := 5.0
const NOISE_CRANK := 0.6
const NOISE_DROP := 8.0

# --- Ayudantes contratados ---
const WORKER_CAPACITY := 4
const WORKER_SPEED := 2.2
const WORKER_SCOOP_TIME := 1.2
const WORKER_DUMP_TIME := 0.6

# --- Mejoras (compartidas por todo el grupo) ---
# "values" tiene un valor más que "costs": el del nivel 0.
const UPGRADE_ORDER := ["sack", "shovel", "crank", "workers", "wheel", "chute"]
const UPGRADES := {
	"sack": {
		"name": "Cesta más grande", "desc": "Llevas más piezas por viaje",
		"costs": [6, 15, 30], "values": [6, 10, 16, 24],
	},
	"shovel": {
		"name": "Recoger a puñados", "desc": "Coges más piezas de cada vez",
		"costs": [5, 12, 25], "values": [2, 3, 5, 8],
	},
	"crank": {
		"name": "Manivela engrasada", "desc": "Cada vuelta clasifica más piezas",
		"costs": [5, 12, 25], "values": [1, 2, 3, 5],
	},
	"workers": {
		"name": "Contratar ayudante", "desc": "Lleva piezas del suelo a la clasificadora",
		"costs": [12, 25, 40], "values": [0, 1, 2, 3],
	},
	"wheel": {
		"name": "Motorcito", "desc": "La clasificadora gira sola (piezas/s)",
		"costs": [20, 40], "values": [0, 1.5, 3.0],
	},
	"chute": {
		"name": "Cinta transportadora", "desc": "Las piezas clasificadas van solas a las figuras (piezas/s)",
		"costs": [25, 45], "values": [0, 1.0, 2.5],
	},
}

# --- Piezas especiales (el toque final de cada figura) ---
# type_key = "<forma>_<color>". El nombre visible es solo el de la forma.
const SHAPE_NAMES := {
	"eye": "Ojo", "door": "Puerta", "apple": "Manzana", "flag": "Bandera", "window": "Ventanilla",
}


static func item_name(type_key: String) -> String:
	var shape := type_key.split("_")[0]
	return str(SHAPE_NAMES.get(shape, shape))


static func pieces_name(kind: String) -> String:
	return "piezas %s" % KIND_NAMES.get(kind, kind)
