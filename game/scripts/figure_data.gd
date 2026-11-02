@tool
class_name FigureData
extends RefCounted
## Maquetas de las 10 figuras, hechas de bloques. Cada una se monta en su mesa.
##
## Cada figura se describe por capas, de abajo arriba. Cada capa es una lista de
## filas de atrás (-Z) hacia delante (+Z), y cada carácter es un bloque del color
## de la paleta ("." = vacío). La X va de izquierda a derecha.
## "specials" son los huecos de las piezas especiales: [tipo, celda, cara].
## Para que quepan en una mesa: como mucho 6 de ancho, 3 de fondo y 7 de alto.

const BLOCK := Vector3(0.15, 0.11, 0.15)  # tamaño de un bloque (igual en el suelo)

const PALETTE := {
	"Y": "yellow", "O": "coral", "S": "sky", "M": "mint", "C": "cream", "K": "cocoa",
}

const MODELS := {
	"duck": {
		"name": "Pato",
		"layers": [
			[".YYYY.", ".YYYY."],
			["YYYYY.", "YYYYY."],
			["...YY.", "...YYO"],
			["...YY.", "...YY."],
		],
		"specials": [["eye_ink", Vector3i(4, 3, 1), "front"], ["eye_ink", Vector3i(4, 3, 0), "back"]],
	},
	"cat": {
		"name": "Gato",
		"layers": [
			["SSSS", "SSSS"],
			["SSSS", "SCCS"],
			[".SS.", ".SS."],
			["SSSS", "SSSS"],
			["S..S", "S..S"],
		],
		"specials": [["eye_ink", Vector3i(1, 3, 1), "front"], ["eye_ink", Vector3i(2, 3, 1), "front"]],
	},
	"house": {
		"name": "Casita",
		"layers": [
			["CCCC", "CCCC", "C.CC"],
			["CCCC", "CCCC", "CCSC"],
			["OOOO", "OOOO", "OOOO"],
			[".OO.", ".OO.", ".OO."],
		],
		"specials": [["door_cocoa", Vector3i(1, 0, 2), "inside"]],
	},
	"tree": {
		"name": "Árbol",
		"layers": [
			["...", ".K.", "..."],
			["...", ".K.", "..."],
			["MMM", "MMM", "MMM"],
			["MMM", "MMM", "MMM"],
			["...", ".M.", "..."],
		],
		"specials": [["apple_coral", Vector3i(2, 3, 2), "front"]],
	},
	"boat": {
		"name": "Barco",
		"layers": [
			[".KKK.", ".KKK."],
			["KKKKK", "KKKKK"],
			["..K..", ".CK.."],
			["..K..", ".CK.."],
		],
		"specials": [["flag_coral", Vector3i(2, 3, 1), "top"]],
	},
	"rocket": {
		"name": "Cohete",
		"layers": [
			["OCO", "OCO"],
			["CCC", "CCC"],
			["CCC", "C.C"],
			["CCC", "CCC"],
			[".O.", ".O."],
		],
		"specials": [["window_sky", Vector3i(1, 2, 1), "inside"]],
	},
	"mushroom": {
		"name": "Seta",
		"layers": [
			[".CC.", ".CC."],
			[".CC.", ".CC."],
			["OOOO", "OCOO"],
			[".OO.", ".OC."],
		],
		"specials": [],
	},
	"flower": {
		"name": "Flor",
		"layers": [
			["..M..", "..M.."],
			[".MM..", ".MM.."],
			["..M..", "..M.."],
			[".YYY.", ".YYY."],
			["YYOYY", "YYOYY"],
			[".YYY.", ".YYY."],
			["..Y..", "..Y.."],
		],
		"specials": [],
	},
	"fish": {
		"name": "Pez",
		"layers": [
			["S.SS.", "S.SS."],
			["SSSSS", "SSSSS"],
			["S.SS.", "S.SS."],
		],
		"specials": [["eye_ink", Vector3i(4, 1, 1), "front"]],
	},
	"mug": {
		"name": "Taza",
		"layers": [
			["CCC.", "CCC.", "CCC."],
			["CCC.", "CCCC", "CCC."],
			["CCC.", "CCCC", "CCC."],
			["CCC.", "CKC.", "CCC."],
		],
		"specials": [],
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
