@tool
extends Node3D
## La cueva en greybox: suelo, paredes, rocas, cristales, antorchas, el haz de
## luz sobre el tesoro y el ambiente (niebla, bloom, oclusión).
## Se genera por código para iterar rápido; luego se cambia por un modelo.

const HEIGHT := 9.0
const TORCHES := [
	Vector3(-17.6, 3.0, -9), Vector3(-17.6, 3.0, 5), Vector3(17.6, 3.0, -9), Vector3(17.6, 3.0, 3),
	Vector3(-9, 3.0, 14.6), Vector3(4, 3.0, 14.6), Vector3(-10, 3.0, -14.6), Vector3(10, 3.0, -14.6),
]

var _torch_lights: Array[OmniLight3D] = []
var _time := 0.0


func _ready() -> void:
	var half_x := Balance.ROOM_HALF_X + 1.0
	var half_z := Balance.ROOM_HALF_Z + 1.0
	_build_environment()
	# Suelo, techo y paredes
	_solid(Vector3(half_x * 2 + 2, 1, half_z * 2 + 2), Vector3(0, -0.5, 0), "floor")
	_solid(Vector3(half_x * 2 + 2, 1, half_z * 2 + 2), Vector3(0, HEIGHT + 0.5, 0), "rock")
	_solid(Vector3(1, HEIGHT, half_z * 2 + 2), Vector3(-half_x - 0.5, HEIGHT / 2, 0), "rock")
	_solid(Vector3(1, HEIGHT, half_z * 2 + 2), Vector3(half_x + 0.5, HEIGHT / 2, 0), "rock")
	_solid(Vector3(half_x * 2 + 2, HEIGHT, 1), Vector3(0, HEIGHT / 2, -half_z - 0.5), "rock")
	_solid(Vector3(half_x * 2 + 2, HEIGHT, 1), Vector3(0, HEIGHT / 2, half_z + 0.5), "rock")
	_build_rocks(half_x, half_z)
	_build_crystals(half_x, half_z)
	_build_torches()
	_build_light_shaft()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.015, 0.015)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.32, 0.22)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.25, 0.16, 0.1)
	env.fog_density = 0.012
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.02
	env.volumetric_fog_albedo = Color(0.95, 0.85, 0.7)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)


func _solid(size: Vector3, pos: Vector3, material_key: String) -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(size), pos, material_key)
	Visuals.static_box(self, size, pos, Visuals.LAYER_WORLD)


## Rocas por el borde (siempre las mismas gracias a la semilla fija).
func _build_rocks(half_x: float, half_z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		var radius := rng.randf_range(0.5, 1.2)
		var pos: Vector3
		var along := rng.randf_range(-1.0, 1.0)
		match i % 4:
			0:
				pos = Vector3(-half_x + radius * 0.5, 0, along * half_z)
			1:
				pos = Vector3(half_x - radius * 0.5, 0, along * half_z)
			2:
				pos = Vector3(along * half_x, 0, -half_z + radius * 0.5)
			_:
				pos = Vector3(along * half_x, 0, half_z - radius * 0.5)
		var rock := SphereMesh.new()
		rock.radius = radius
		rock.height = radius * 2.0
		rock.radial_segments = 7
		rock.rings = 4
		var instance := Visuals.mesh_instance(self, rock, pos, "rock")
		instance.scale = Vector3(1.0, rng.randf_range(0.6, 1.5), rng.randf_range(0.8, 1.3))
		instance.rotation.y = rng.randf_range(0.0, TAU)


func _build_crystals(half_x: float, half_z: float) -> void:
	var corners := [
		Vector3(-half_x + 1.2, 0, -half_z + 1.2), Vector3(half_x - 1.2, 0, -half_z + 1.2),
		Vector3(-half_x + 1.2, 0, half_z - 1.2), Vector3(half_x - 1.2, 0, half_z - 1.2),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for corner in corners:
		for i in 4:
			var crystal := PrismMesh.new()
			var height := rng.randf_range(0.8, 2.0)
			crystal.size = Vector3(0.35, height, 0.35)
			var offset := Vector3(rng.randf_range(-0.6, 0.6), height / 2.0, rng.randf_range(-0.6, 0.6))
			var instance := Visuals.mesh_instance(self, crystal, corner + offset, "crystal")
			instance.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))
		var glow := OmniLight3D.new()
		glow.position = corner + Vector3(0, 1.2, 0)
		glow.light_color = Color(0.3, 0.7, 1.0)
		glow.light_energy = 1.2
		glow.omni_range = 5.0
		add_child(glow)


func _build_torches() -> void:
	for i in TORCHES.size():
		var pos: Vector3 = TORCHES[i]
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.15, 0.6, 0.15)), pos, "wood")
		var flame := SphereMesh.new()
		flame.radius = 0.12
		flame.height = 0.3
		Visuals.mesh_instance(self, flame, pos + Vector3(0, 0.4, 0), "flame")
		var light := OmniLight3D.new()
		light.position = pos + Vector3(0, 0.6, 0) - pos.normalized() * Vector3(0.6, 0, 0.6)
		light.light_color = Color(1.0, 0.6, 0.3)
		light.light_energy = 1.6
		light.omni_range = 10.0
		light.shadow_enabled = i < 3
		add_child(light)
		_torch_lights.append(light)


## Haz de luz desde una grieta del techo justo encima del tesoro.
func _build_light_shaft() -> void:
	var shaft := SpotLight3D.new()
	shaft.position = Vector3(0, HEIGHT - 0.3, -6)
	shaft.rotation_degrees = Vector3(-90, 0, 0)
	shaft.light_color = Color(1.0, 0.9, 0.7)
	shaft.light_energy = 6.0
	shaft.spot_range = 14.0
	shaft.spot_angle = 26.0
	shaft.shadow_enabled = true
	shaft.light_volumetric_fog_energy = 2.5
	add_child(shaft)


func _process(delta: float) -> void:
	_time += delta
	for i in _torch_lights.size():
		var phase := float(i) * 1.7
		var flicker := 0.85 + 0.15 * sin(_time * 13.0 + phase) * sin(_time * 7.3 + phase * 2.0)
		_torch_lights[i].light_energy = 1.6 * flicker
