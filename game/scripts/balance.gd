@tool
class_name Balance
extends RefCounted
## Todos los números y textos de diseño en un solo sitio, para equilibrar sin
## tocar la lógica. Los valores son de prototipo (partida corta para probar).

# Ambientación provisional: si cambia el tema, se cambia aquí.
const SLEEPER_NAME := "el dragón"
const SLEEPER_NAME_CAP := "El dragón"

# Tamaño jugable de la cueva (mitad en X y en Z, en metros).
const ROOM_HALF_X := 17.0
const ROOM_HALF_Z := 14.0

# --- Monedas ---
const KINDS := ["copper", "silver", "gold"]
const KIND_NAMES := {
	"mixed": "monedas mezcladas", "copper": "cobre", "silver": "plata", "gold": "oro",
}
const PILE_START := {"copper": 3600, "silver": 1800, "gold": 600}
const COINS_PER_PAY := 8  # 1 de paga por cada 8 monedas apiladas
const ITEM_PAY := 15  # paga por cada tesoro colocado
const SCOOP_COOLDOWN := 0.3
const CRANK_INTERVAL := 0.2

# --- Ruido ---
const NOISE_MAX := 100.0
const NOISE_AFTER_SNORT := 35.0
const NOISE_DECAY := 6.0  # por segundo
const NOISE_SPRINT := 9.0  # por segundo corriendo
const NOISE_LAND := 6.0  # al caer de un salto
const NOISE_DUMP := 3.0  # al vaciar un saco en la tolva
const NOISE_CRANK := 0.35  # por cada vuelta de manivela
const NOISE_DROP := 5.0  # al tirar un tesoro al suelo

# --- Kobolds contratados ---
const WORKER_CAPACITY := 30
const WORKER_SPEED := 2.2
const WORKER_SCOOP_TIME := 1.2
const WORKER_DUMP_TIME := 0.6

# --- Mejoras (compartidas por toda la tripulación) ---
# "values" tiene un valor más que "costs": el del nivel 0.
const UPGRADE_ORDER := ["shovel", "sack", "crank", "boots", "workers", "wheel", "chute"]
const UPGRADES := {
	"shovel": {
		"name": "Pala más grande", "desc": "Más monedas por palada",
		"costs": [10, 30, 60], "values": [20, 35, 60, 100],
	},
	"sack": {
		"name": "Saco más grande", "desc": "Llevas más monedas por viaje",
		"costs": [15, 35, 70], "values": [60, 100, 160, 250],
	},
	"crank": {
		"name": "Manivela engrasada", "desc": "Cada vuelta clasifica más monedas",
		"costs": [10, 30, 60], "values": [6, 10, 16, 25],
	},
	"boots": {
		"name": "Botas de silencio", "desc": "Todo lo que haces hace menos ruido",
		"costs": [15, 40], "values": [1.0, 0.6, 0.3],
	},
	"workers": {
		"name": "Contratar kobold", "desc": "Palea de la montaña a la tolva por ti",
		"costs": [30, 60, 100], "values": [0, 1, 2, 3],
	},
	"wheel": {
		"name": "Rueda de hámster", "desc": "La clasificadora gira sola (monedas/s)",
		"costs": [50, 100], "values": [0, 8, 20],
	},
	"chute": {
		"name": "Tobogán a la cámara", "desc": "Las cubetas se vacían solas en las torres (monedas/s)",
		"costs": [60, 120], "values": [0, 6, 15],
	},
}

# --- Tesoros ---
const SHAPE_NAMES := {"crown": "Corona", "chalice": "Cáliz", "sword": "Espada", "gem": "Gema"}
const MATERIAL_NAMES := {
	"gold": "de oro", "silver": "de plata", "red": "roja", "blue": "azul", "green": "verde",
}


static func item_name(type_key: String) -> String:
	var parts := type_key.split("_")
	if parts.size() < 2:
		return type_key
	return "%s %s" % [SHAPE_NAMES.get(parts[0], parts[0]), MATERIAL_NAMES.get(parts[1], parts[1])]
