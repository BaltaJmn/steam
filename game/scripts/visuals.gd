@tool
class_name Visuals
extends RefCounted
## Materiales, mallas y piezas provisionales (greybox).
## Cuando haya arte de verdad, se sustituyen estas funciones o las escenas por
## modelos y la lógica del juego no cambia.

const LAYER_WORLD := 1
const LAYER_INTERACT := 2
const LAYER_PLAYERS := 4

const PLASTIC_COLORS := {
	"red": Color(0.9, 0.12, 0.12), "blue": Color(0.15, 0.4, 0.95),
	"yellow": Color(1.0, 0.82, 0.1), "white": Color(0.95, 0.95, 0.92),
}

# Materiales que llevan contorno oscuro (estilo dibujo animado). Las paredes y
# el suelo no lo llevan: con cajas tan grandes el contorno no aporta.
const OUTLINED := [
	"crumbs", "popcorn", "puff", "cookie", "red", "blue", "yellow", "white", "gold", "silver",
	"remote", "skin", "sleeve", "ant", "helmet", "bowl", "wood", "metal", "lint", "tray", "cork",
]

static var _materials := {}
static var _outline: StandardMaterial3D


static func mat(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	match key:
		# Migas
		"crumbs":
			m.albedo_color = Color(0.88, 0.68, 0.4)
			m.roughness = 0.9
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.09, 5.0)
		"popcorn":
			m.albedo_color = Color(0.98, 0.94, 0.8)
			m.roughness = 0.85
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.12, 3.0)
		"puff":
			m.albedo_color = Color(1.0, 0.55, 0.12)
			m.roughness = 0.8
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.12, 3.0)
		"cookie":
			m.albedo_color = Color(0.58, 0.35, 0.17)
			m.roughness = 0.9
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.12, 3.0)
		# Objetos perdidos (plástico y metal)
		"red", "blue", "yellow", "white":
			m.albedo_color = PLASTIC_COLORS[key]
			m.roughness = 0.3
		"gold":
			m.albedo_color = Color(1.0, 0.78, 0.3)
			m.metallic = 1.0
			m.roughness = 0.22
		"silver":
			m.albedo_color = Color(0.85, 0.87, 0.92)
			m.metallic = 1.0
			m.roughness = 0.2
		"ghost":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.7, 0.85, 1.0, 0.22)
		"remote":
			m.albedo_color = Color(0.06, 0.06, 0.07)
			m.roughness = 0.4
		# El sofá
		"fabric":
			# Pana: el ruido estirado en un eje parece el canalé de la tela.
			m.albedo_color = Color(0.13, 0.33, 0.34)
			m.roughness = 1.0
			_add_noise_normal(m, FastNoiseLite.TYPE_SIMPLEX, 0.08, 1.0)
			m.uv1_scale = Vector3(40.0, 1.5, 1.0)
		"cushion":
			m.albedo_color = Color(0.17, 0.4, 0.41)
			m.roughness = 1.0
			_add_noise_normal(m, FastNoiseLite.TYPE_SIMPLEX, 0.08, 1.0)
			m.uv1_scale = Vector3(30.0, 1.5, 1.0)
		"seam":
			m.albedo_color = Color(0.08, 0.22, 0.23)
			m.roughness = 1.0
		"thread":
			m.albedo_color = Color(0.85, 0.78, 0.55)
		"lint":
			m.albedo_color = Color(0.7, 0.68, 0.78)
			m.roughness = 1.0
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.2, 2.0)
		"screen":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.5, 0.75, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.4, 0.7, 1.0)
			m.emission_energy_multiplier = 2.5
		"worklight":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1.0, 0.9, 0.6)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.85, 0.5)
			m.emission_energy_multiplier = 4.0
		# Materiales de la cuadrilla (palitos de helado, clips...)
		"wood":
			m.albedo_color = Color(0.85, 0.7, 0.45)
			m.roughness = 0.8
		"metal":
			m.albedo_color = Color(0.7, 0.72, 0.75)
			m.metallic = 0.9
			m.roughness = 0.35
		"bowl":
			m.albedo_color = Color(0.95, 0.42, 0.33)
			m.roughness = 0.3
		"tray":
			m.albedo_color = Color(0.92, 0.9, 0.82)
			m.roughness = 0.4
		"cork":
			m.albedo_color = Color(0.72, 0.52, 0.32)
			m.roughness = 1.0
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.3, 2.0)
		"glass":
			m.albedo_color = Color(0.8, 0.92, 1.0, 0.35)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = 0.05
		"note_yellow", "note_pink", "note_blue":
			m.albedo_color = {"note_yellow": Color(1.0, 0.92, 0.4), "note_pink": Color(1.0, 0.6, 0.75), "note_blue": Color(0.55, 0.85, 1.0)}[key]
		"sleeve":
			# Pijama de franela de papá.
			m.albedo_color = Color(0.32, 0.4, 0.62)
			m.roughness = 0.9
		# Papá, las hormigas y la cuadrilla
		"skin":
			m.albedo_color = Color(0.95, 0.74, 0.6)
			m.roughness = 0.7
		"hair":
			m.albedo_color = Color(0.22, 0.14, 0.09)
			m.roughness = 0.9
		"dark":
			m.albedo_color = Color(0.05, 0.04, 0.04)
		"ant":
			m.albedo_color = Color(0.1, 0.06, 0.05)
			m.roughness = 0.25
		"helmet":
			m.albedo_color = Color(1.0, 0.8, 0.1)
			m.roughness = 0.4
		"snore":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.92, 0.95, 1.0)
		_:
			m.albedo_color = Color.MAGENTA
	if m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_TOON
		m.rim_enabled = true
		m.rim = 0.25
		m.rim_tint = 0.6
	if key in OUTLINED:
		m.next_pass = outline()
	_materials[key] = m
	return m


## Contorno oscuro "de cómic" (casco invertido): se dibuja la cara de atrás de
## la malla un poco hinchada y en un color casi negro.
static func outline() -> StandardMaterial3D:
	if _outline:
		return _outline
	_outline = StandardMaterial3D.new()
	_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_outline.cull_mode = BaseMaterial3D.CULL_FRONT
	_outline.grow = true
	_outline.grow_amount = 0.025
	_outline.albedo_color = Color(0.1, 0.06, 0.05)
	return _outline


static func _add_noise_normal(
	m: StandardMaterial3D, noise_type: FastNoiseLite.NoiseType, frequency: float, uv_scale: float
) -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = noise_type
	noise.frequency = frequency
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.seamless = true
	texture.as_normal_map = true
	texture.bump_strength = 6.0
	m.normal_enabled = true
	m.normal_texture = texture
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)


# --- Objetos perdidos ---

static func item_mesh(type_key: String) -> Mesh:
	var parts := type_key.split("_")
	var material_key: String = parts[1] if parts.size() > 1 else "red"
	var mesh: PrimitiveMesh
	match parts[0]:
		"button":
			var disc := CylinderMesh.new()
			disc.top_radius = 0.2
			disc.bottom_radius = 0.2
			disc.height = 0.06
			disc.radial_segments = 16
			mesh = disc
		"block":
			mesh = box_mesh(Vector3(0.32, 0.19, 0.16))
		"earring":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.1
			ring.outer_radius = 0.15
			mesh = ring
		_:
			mesh = box_mesh(Vector3(0.24, 0.24, 0.24))
	mesh.material = mat(material_key)
	return mesh


## Altura del objeto apoyado, para dejarlo bien en el suelo o en la bandeja.
static func item_height(type_key: String) -> float:
	match type_key.split("_")[0]:
		"button":
			return 0.06
		"block":
			return 0.19
		"earring":
			return 0.05
	return 0.24


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
	parent: Node, text: String, pos: Vector3, size := 48, color := Color.WHITE, billboard := true
) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.outline_size = 12
	l.modulate = color
	l.pixel_size = 0.004
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l
