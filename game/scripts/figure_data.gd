@tool
class_name FigureData
extends RefCounted
## Maquetas de las 6 figuras, hechas de bloques.
##
## Cada figura se describe por capas, de abajo arriba. Cada capa es una lista de
## filas de atrás (-Z) hacia delante (+Z), y cada carácter es un bloque del color
## de la paleta ("." = vacío). La X va de izquierda a derecha.
## "specials" son los huecos de las piezas especiales: [tipo, celda, cara].

const BLOCK := Vector3(0.6, 0.45, 0.6)  # tamaño de un bloque (igual en el suelo)

const PALETTE := {
	"Y": "yellow", "O": "coral", "S": "sky", "M": "mint", "C": "cream", "K": "cocoa",
}

const MODELS := {
	"duck": {
		"name": "Pato",
		"layers": [
			[".......", "..O.O..", "......."],
			[".YYYY..", ".YYYYY.", ".YYYY.."],
			["YYYYY..", "YYYYYY.", "YYYYY.."],
			[".YYYYY.", ".YYYYY.", ".YYYYY."],
			["....YY.", "....YYO", "....YY."],
			["....YY.", "....YY.", "....YY."],
		],
		"specials": [["eye_ink", Vector3i(5, 4, 2), "front"], ["eye_ink", Vector3i(5, 4, 0), "back"]],
	},
	"cat": {
		"name": "Gato",
		"layers": [
			["SSSSS.", "SSSSS."],
			["SSSSSS", "SCCCS."],
			[".SSS.S", ".SCS.."],
			["SSSSS.", "SSSSS."],
			["SSSSS.", "SSSSS."],
			["S...S.", "S...S."],
		],
		"specials": [["eye_ink", Vector3i(1, 4, 1), "front"], ["eye_ink", Vector3i(3, 4, 1), "front"]],
	},
	"house": {
		"name": "Casita",
		"layers": [
			["CCCCC", "CCCCC", "CC.CC"],
			["CCCCC", "CCCCC", "CS.SC"],
			["OOOOO", "OOOOO", "OOOOO"],
			[".OOO.", ".OOO.", ".OOO."],
			["..O..", "..O..", "..O.."],
		],
		"specials": [["door_cocoa", Vector3i(2, 0, 2), "inside"]],
	},
	"tree": {
		"name": "Árbol",
		"layers": [
			[".....", "..K..", "....."],
			[".....", "..K..", "....."],
			[".MMM.", "MMMMM", ".MMM."],
			["MMMMM", "MMMMM", "MMMMM"],
			[".MMM.", "MMMMM", ".MMM."],
			[".....", ".MMM.", "....."],
		],
		"specials": [["apple_coral", Vector3i(3, 3, 2), "front"]],
	},
	"boat": {
		"name": "Barco",
		"layers": [
			[".KKKKK.", ".KKKKK.", ".KKKKK."],
			["KKKKKKK", "KKKKKKK", "KKKKKKK"],
			[".......", "..CK...", "......."],
			[".......", ".CCK...", "......."],
			[".......", "..CK...", "......."],
			[".......", "...K...", "......."],
		],
		"specials": [["flag_coral", Vector3i(3, 5, 1), "top"]],
	},
	"rocket": {
		"name": "Cohete",
		"layers": [
			[".CCC.", "OCCCO", ".CCC."],
			[".CCC.", "OCCCO", ".CCC."],
			[".CCC.", ".CCC.", ".CCC."],
			[".CCC.", ".CCC.", ".C.C."],
			[".CCC.", ".CCC.", ".CCC."],
			[".OOO.", ".OOO.", ".OOO."],
			[".....", "..O..", "....."],
		],
		"specials": [["window_sky", Vector3i(2, 3, 2), "inside"]],
	},
}


## Bloques de la figura en orden de montaje (de abajo arriba):
## [[celda: Vector3i, color: String], ...]
static func blocks(model: String) -> Array:
	var result := []
	var layers: Array = MODELS[model]["layers"]
	for y in layers.size():
		var rows: Array = layers[y]
		for z in rows.size():
			var row: String = rows[z]
			for x in row.length():
				var code := row[x]
				if PALETTE.has(code):
					result.append([Vector3i(x, y, z), PALETTE[code]])
	return result


## Cuántos bloques de cada color necesita la figura.
static func color_counts(model: String) -> Dictionary:
	var counts := {}
	for block in blocks(model):
		counts[block[1]] = int(counts.get(block[1], 0)) + 1
	return counts


## Tamaño de la maqueta en celdas (ancho X, alto Y, fondo Z).
static func cells(model: String) -> Vector3i:
	var layers: Array = MODELS[model]["layers"]
	var rows: Array = layers[0]
	var row: String = rows[0]
	return Vector3i(row.length(), layers.size(), rows.size())


## Posición local del centro de una celda. La maqueta queda centrada en X y Z
## y apoyada en y = 0.
static func cell_center(model: String, cell: Vector3i) -> Vector3:
	var size := cells(model)
	return Vector3(
		(cell.x - (size.x - 1) / 2.0) * BLOCK.x,
		(cell.y + 0.5) * BLOCK.y,
		(cell.z - (size.z - 1) / 2.0) * BLOCK.z
	)
