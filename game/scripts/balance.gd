@tool
class_name Balance
extends RefCounted
## Todos los números y textos de diseño en un solo sitio, para equilibrar sin
## tocar la lógica. Los valores son de prototipo (partida corta para probar).

# El que duerme encima y al que no hay que despertar.
const SLEEPER_NAME := "papá"
const SLEEPER_NAME_CAP := "Papá"
const COMPANY_NAME := "MicroLimpiezas Menguantes S.L."

# Tamaño jugable del hueco entre los cojines (mitad en X y en Z, en metros).
const ROOM_HALF_X := 17.0
const ROOM_HALF_Z := 14.0

# --- Migas ---
const KINDS := ["popcorn", "puff", "cookie"]
const KIND_NAMES := {
	"mixed": "migas mezcladas", "popcorn": "palomitas", "puff": "ganchitos", "cookie": "galleta",
}
const PILE_START := {"popcorn": 3600, "puff": 1800, "cookie": 600}
const CRUMBS_PER_PAY := 8  # entre cada 8 migas aparece 1 moneda de calderilla
const ITEM_PAY := 15  # calderilla por cada objeto devuelto a su hueco
const SCOOP_COOLDOWN := 0.3
const CRANK_INTERVAL := 0.2

# --- Ruido ---
const NOISE_MAX := 100.0
const NOISE_AFTER_SNORT := 35.0
const NOISE_DECAY := 6.0  # por segundo
const NOISE_SPRINT := 9.0  # por segundo corriendo
const NOISE_LAND := 6.0  # al caer de un salto
const NOISE_DUMP := 3.0  # al vaciar el cubo en la tolva
const NOISE_CRANK := 0.35  # por cada vuelta de manivela
const NOISE_DROP := 5.0  # al tirar un objeto al suelo

# --- Hormigas contratadas ---
const WORKER_CAPACITY := 30
const WORKER_SPEED := 2.2
const WORKER_SCOOP_TIME := 1.2
const WORKER_DUMP_TIME := 0.6

# --- Mejoras (compartidas por toda la cuadrilla) ---
# "values" tiene un valor más que "costs": el del nivel 0.
const UPGRADE_ORDER := ["shovel", "sack", "crank", "boots", "workers", "wheel", "chute"]
const UPGRADES := {
	"shovel": {
		"name": "Cuchara más grande", "desc": "Cucharilla de café → de postre → sopera → cucharón",
		"costs": [10, 30, 60], "values": [20, 35, 60, 100],
	},
	"sack": {
		"name": "Cubo más grande", "desc": "Tapón de botella → vaso de chupito → taza → tazón",
		"costs": [15, 35, 70], "values": [60, 100, 160, 250],
	},
	"crank": {
		"name": "Manivela engrasada", "desc": "Cada vuelta clasifica más migas",
		"costs": [10, 30, 60], "values": [6, 10, 16, 25],
	},
	"boots": {
		"name": "Zapatillas de estar por casa", "desc": "Todo lo que haces hace menos ruido",
		"costs": [15, 40], "values": [1.0, 0.6, 0.3],
	},
	"workers": {
		"name": "Contratar hormiga", "desc": "Lleva migas de la montaña a la tolva por ti",
		"costs": [30, 60, 100], "values": [0, 1, 2, 3],
	},
	"wheel": {
		"name": "El hámster de la familia", "desc": "Hace girar la clasificadora él solo (migas/s)",
		"costs": [50, 100], "values": [0, 8, 20],
	},
	"chute": {
		"name": "Tobogán de pajita", "desc": "Las cubetas se vacían solas en los cuencos (migas/s)",
		"costs": [60, 120], "values": [0, 6, 15],
	},
}

# --- Objetos perdidos en el sofá ---
# type_key = "<forma>_<color>". Todos los nombres son masculinos para que
# concuerden con el color ("Botón rojo", "Dado blanco"...).
const SHAPE_NAMES := {
	"button": "Botón", "block": "Bloque de juguete", "earring": "Pendiente", "dice": "Dado",
}
const MATERIAL_NAMES := {
	"red": "rojo", "blue": "azul", "yellow": "amarillo", "white": "blanco",
	"gold": "de oro", "silver": "de plata",
}


static func item_name(type_key: String) -> String:
	var parts := type_key.split("_")
	if parts.size() < 2:
		return type_key
	return "%s %s" % [SHAPE_NAMES.get(parts[0], parts[0]), MATERIAL_NAMES.get(parts[1], parts[1])]
