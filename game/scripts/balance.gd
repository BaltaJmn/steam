@tool
class_name Balance
extends RefCounted
## Todos los números y textos de diseño en un solo sitio, para equilibrar sin
## tocar la lógica. Los valores son de prototipo (partida corta para probar).

# Tamaño jugable de la habitación (mitad en X y en Z, en metros).
const ROOM_HALF_X := 8.5
const ROOM_HALF_Z := 6.5

# --- Piezas ---
# Las piezas del suelo son exactamente las que hacen falta para las 10 figuras
# (las cuenta FigureData a partir de las maquetas).
const KINDS := ["yellow", "coral", "sky", "mint", "cream", "cocoa"]
# Se usa como "piezas <nombre>".
const KIND_NAMES := {
	"mixed": "mezcladas", "yellow": "amarillas", "coral": "rosas", "sky": "azules",
	"mint": "verdes", "cream": "crema", "cocoa": "marrones",
}
const PIECES_PER_PAY := 1  # pegatinas por cada pieza colocada en una figura
const ITEM_PAY := 5  # pegatinas por cada pieza especial colocada
const FIGURE_BONUS := 10  # pegatinas al terminar una figura
const SCOOP_COOLDOWN := 0.35

# --- Ruido (desactivado: el tono es cozy) ---
# El sistema sigue en Game por si se quiere recuperar una amenaza suave.
const NOISE_ENABLED := false
const NOISE_MAX := 100.0
const NOISE_AFTER_SNORT := 30.0
const NOISE_DECAY := 4.0
const NOISE_SPRINT := 14.0
const NOISE_LAND := 7.0
const NOISE_LAND_MIN_SPEED := 3.0
const NOISE_DROP := 8.0

# --- Pollitos de cuerda (ayudantes) ---
# Recogen piezas del suelo y las llevan a las mesas que las necesitan.
const WORKER_CAPACITY := 4
const WORKER_SPEED := 1.4
const WORKER_SCOOP_TIME := 1.2
const WORKER_PLACE_TIME := 0.6

# --- Perrito rastreador ---
const PUPPY_SPEED := 3.5

# --- Tienda de cositas monas (compartidas por todo el grupo) ---
# Todas ayudan a buscar piezas. "values" tiene un valor más que "costs": el
# del nivel 0.
const UPGRADE_ORDER := ["sack", "shovel", "speed", "fireflies", "balloons", "puppy", "workers"]
const UPGRADES := {
	"sack": {
		"name": "Cesta de gatito", "desc": "Llevas más piezas (y le sale un lazo, y luego orejitas)",
		"costs": [6, 15, 30], "values": [6, 10, 16, 24],
	},
	"shovel": {
		"name": "Manoplas de osito", "desc": "Coges más piezas de cada vez",
		"costs": [5, 12, 25], "values": [2, 3, 5, 8],
	},
	"speed": {
		"name": "Zapatillas de conejito", "desc": "Andas más rápido y dando saltitos",
		"costs": [8, 20], "values": [1.0, 1.15, 1.3],
	},
	"fireflies": {
		"name": "Luciérnagas", "desc": "Revolotean sobre los grupitos de piezas que quedan",
		"costs": [10, 20], "values": [0, 1, 2],
	},
	"balloons": {
		"name": "Globitos", "desc": "Cada pieza especial perdida lleva un globo atado",
		"costs": [15], "values": [0, 1],
	},
	"puppy": {
		"name": "Perrito rastreador", "desc": "Corre hasta el grupito más cercano y te espera allí",
		"costs": [20], "values": [0, 1],
	},
	"workers": {
		"name": "Pollitos de cuerda", "desc": "Recogen piezas y las llevan a las mesas",
		"costs": [12, 25, 40], "values": [0, 1, 2, 3],
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
