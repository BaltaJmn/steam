@tool
class_name Visuals
extends RefCounted
## Materiales, mallas y piezas provisionales (greybox).
## Cuando haya arte de verdad, se sustituyen estas funciones o las escenas por
## modelos y la lógica del juego no cambia.

const LAYER_WORLD := 1
const LAYER_INTERACT := 2
const LAYER_PLAYERS := 4

const GEM_COLORS := {
	"red": Color(0.95, 0.15, 0.2), "blue": Color(0.2, 0.45, 1.0), "green": Color(0.2, 0.9, 0.4),
}

static var _materials := {}


static func mat(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	match key:
		"coins":
			m.albedo_color = Color(1.0, 0.74, 0.28)
			m.metallic = 1.0
			m.roughness = 0.3
			m.emission_enabled = true
			m.emission = Color(1.0, 0.55, 0.15)
			m.emission_energy_multiplier = 0.15
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.09, 5.0)
		"gold":
			m.albedo_color = Color(1.0, 0.78, 0.3)
			m.metallic = 1.0
			m.roughness = 0.22
		"silver":
			m.albedo_color = Color(0.85, 0.87, 0.92)
			m.metallic = 1.0
			m.roughness = 0.2
		"copper":
			m.albedo_color = Color(0.85, 0.48, 0.28)
			m.metallic = 1.0
			m.roughness = 0.3
		"red", "blue", "green":
			m.albedo_color = GEM_COLORS[key]
			m.metallic = 0.2
			m.roughness = 0.05
			m.emission_enabled = true
			m.emission = GEM_COLORS[key]
			m.emission_energy_multiplier = 0.6
		"ghost":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.7, 0.85, 1.0, 0.22)
		"rock":
			m.albedo_color = Color(0.22, 0.18, 0.16)
			m.roughness = 0.95
			_add_noise_normal(m, FastNoiseLite.TYPE_SIMPLEX, 0.02, 3.0)
		"floor":
			m.albedo_color = Color(0.28, 0.22, 0.17)
			m.roughness = 0.9
			_add_noise_normal(m, FastNoiseLite.TYPE_SIMPLEX, 0.03, 12.0)
		"wood":
			m.albedo_color = Color(0.45, 0.28, 0.16)
			m.roughness = 0.8
		"metal":
			m.albedo_color = Color(0.4, 0.4, 0.43)
			m.metallic = 0.8
			m.roughness = 0.45
		"dragon":
			m.albedo_color = Color(0.55, 0.12, 0.1)
			m.metallic = 0.3
			m.roughness = 0.5
			_add_noise_normal(m, FastNoiseLite.TYPE_CELLULAR, 0.12, 4.0)
		"dragon_wing":
			m.albedo_color = Color(0.35, 0.08, 0.08)
			m.roughness = 0.7
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"bone":
			m.albedo_color = Color(0.9, 0.85, 0.72)
			m.roughness = 0.6
		"dark":
			m.albedo_color = Color(0.05, 0.04, 0.04)
		"kobold":
			m.albedo_color = Color(0.55, 0.42, 0.25)
			m.roughness = 0.8
		"helmet":
			m.albedo_color = Color(1.0, 0.8, 0.1)
			m.roughness = 0.4
		"flame":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1.0, 0.6, 0.2)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.5, 0.15)
			m.emission_energy_multiplier = 4.0
		"crystal":
			m.albedo_color = Color(0.3, 0.8, 1.0)
			m.roughness = 0.1
			m.emission_enabled = true
			m.emission = Color(0.2, 0.7, 1.0)
			m.emission_energy_multiplier = 1.5
		"smoke":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1.0, 0.55, 0.2)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.45, 0.1)
			m.emission_energy_multiplier = 3.0
		_:
			m.albedo_color = Color.MAGENTA
	_materials[key] = m
	return m


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


# --- Tesoros ---

static func item_mesh(type_key: String) -> Mesh:
	var parts := type_key.split("_")
	var material_key: String = parts[1] if parts.size() > 1 else "gold"
	var mesh: PrimitiveMesh
	match parts[0]:
		"crown":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.13
			torus.outer_radius = 0.2
			mesh = torus
		"chalice":
			var cup := CylinderMesh.new()
			cup.top_radius = 0.13
			cup.bottom_radius = 0.05
			cup.height = 0.3
			mesh = cup
		"sword":
			var blade := BoxMesh.new()
			blade.size = Vector3(0.07, 0.8, 0.025)
			mesh = blade
		_:
			var gem := SphereMesh.new()
			gem.radius = 0.11
			gem.height = 0.2
			gem.radial_segments = 6
			gem.rings = 2
			mesh = gem
	mesh.material = mat(material_key)
	return mesh


## Altura del tesoro de pie, para apoyarlo bien en el suelo o en el estante.
static func item_height(type_key: String) -> float:
	match type_key.split("_")[0]:
		"crown":
			return 0.07
		"chalice":
			return 0.3
		"sword":
			return 0.8
	return 0.2


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
