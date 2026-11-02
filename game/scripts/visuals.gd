@tool
class_name Visuals
extends RefCounted
## Estilo visual: cozy y minimalista. Todo es geometría sencilla con colores
## pastel planos (sin texturas ni contornos) y plástico suave. Los bloques con
## pivotes se generan aquí y se usan tanto en el suelo como en las figuras.

const LAYER_WORLD := 1
const LAYER_INTERACT := 2
const LAYER_PLAYERS := 4

# Paleta. Los colores de las piezas coinciden con Balance.KINDS.
const COLORS := {
	"yellow": Color(1.0, 0.83, 0.42),
	"coral": Color(0.96, 0.52, 0.47),
	"sky": Color(0.53, 0.73, 0.94),
	"mint": Color(0.55, 0.82, 0.67),
	"cream": Color(0.97, 0.94, 0.87),
	"cocoa": Color(0.62, 0.45, 0.36),
	"ink": Color(0.2, 0.19, 0.24),
	# Escenario y muebles
	"floor": Color(0.9, 0.8, 0.68),
	"rug": Color(0.74, 0.82, 0.76),
	"wall": Color(0.98, 0.93, 0.86),
	"blanket": Color(0.66, 0.74, 0.9),
	"pillow": Color(0.99, 0.97, 0.94),
	"wood": Color(0.85, 0.7, 0.55),
	"book_a": Color(0.93, 0.65, 0.55),
	"book_b": Color(0.6, 0.72, 0.85),
	"book_c": Color(0.97, 0.86, 0.55),
	"plant": Color(0.48, 0.72, 0.56),
	"pot": Color(0.92, 0.62, 0.5),
	"machine": Color(0.82, 0.86, 0.92),
	"metal": Color(0.72, 0.75, 0.8),
	"skin": Color(0.98, 0.85, 0.74),
	"baseplate": Color(0.92, 0.9, 0.86),
	"board": Color(0.98, 0.95, 0.9),
}

static var _materials := {}
static var _brick_mesh: Mesh


static func mat(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.6
	match key:
		"ghost":
			# Silueta de lo que falta por montar.
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1.0, 1.0, 1.0, 0.18)
		"bricks":
			# Bloques coloreados por instancia (MultiMesh).
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.45
		"glass":
			m.albedo_color = Color(0.85, 0.93, 1.0, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.1
		"sunlight":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1.0, 0.95, 0.82)
		_:
			m.albedo_color = COLORS.get(key, Color.MAGENTA)
			if key in Balance.KINDS or key == "ink":
				m.roughness = 0.45
	_materials[key] = m
	return m


## Bloque con cuatro pivotes encima, del tamaño de FigureData.BLOCK.
## Es la pieza básica de todo el juego.
static func brick_mesh() -> Mesh:
	if _brick_mesh:
		return _brick_mesh
	var size := FigureData.BLOCK
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := BoxMesh.new()
	body.size = Vector3(size.x * 0.96, size.y * 0.96, size.z * 0.96)
	surface.append_from(body, 0, Transform3D.IDENTITY)
	var stud := CylinderMesh.new()
	stud.top_radius = size.x * 0.12
	stud.bottom_radius = size.x * 0.12
	stud.height = size.y * 0.2
	stud.radial_segments = 12
	stud.rings = 1
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pos := Vector3(sx * size.x * 0.24, size.y * 0.58, sz * size.z * 0.24)
			surface.append_from(stud, 0, Transform3D(Basis.IDENTITY, pos))
	_brick_mesh = surface.commit()
	return _brick_mesh


## MultiMesh de bloques con color por instancia.
static func brick_multimesh(count: int) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = brick_mesh()
	multimesh.instance_count = count
	multimesh.visible_instance_count = 0
	return multimesh


# --- Piezas especiales ---

static func item_mesh(type_key: String) -> Mesh:
	var parts := type_key.split("_")
	var material_key: String = parts[1] if parts.size() > 1 else "ink"
	var mesh: PrimitiveMesh
	match parts[0]:
		"eye":
			var eye := SphereMesh.new()
			eye.radius = 0.12
			eye.height = 0.24
			mesh = eye
		"door":
			mesh = box_mesh(Vector3(0.5, 0.86, 0.5))
		"apple":
			var apple := SphereMesh.new()
			apple.radius = 0.16
			apple.height = 0.32
			mesh = apple
		"flag":
			var flag := PrismMesh.new()
			flag.size = Vector3(0.4, 0.5, 0.06)
			mesh = flag
		_:
			var window := CylinderMesh.new()
			window.top_radius = 0.25
			window.bottom_radius = 0.25
			window.height = 0.42
			mesh = window
	mesh.material = mat(material_key)
	return mesh


## Altura de la pieza apoyada, para dejarla bien en el suelo o en su hueco.
static func item_height(type_key: String) -> float:
	match type_key.split("_")[0]:
		"eye":
			return 0.24
		"door":
			return 0.86
		"apple":
			return 0.32
		"flag":
			return 0.5
	return 0.42


# --- Piezas genéricas ---

static func box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func mesh_instance(parent: Node, mesh: Mesh, pos: Vector3, material_key := "") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	if material_key != "":
		instance.material_override = mat(material_key)
	parent.add_child(instance)
	return instance


## Caja con colisión. "part" sirve para saber qué trozo de una máquina miras.
static func static_box(parent: Node, size: Vector3, pos: Vector3, layers: int, part := "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layers
	body.collision_mask = 0
	body.position = pos
	if part != "":
		body.set_meta("part", part)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


static func label(
	parent: Node, text: String, pos: Vector3, size := 48, color := Color(0.25, 0.24, 0.3), billboard := true
) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.outline_size = 14
	l.outline_modulate = Color(1.0, 1.0, 1.0, 0.85)
	l.modulate = color
	l.pixel_size = 0.004
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l
