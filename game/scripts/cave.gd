@tool
extends Node3D
## El hueco entre los cojines del sofá (greybox): suelo de tela, paredes y
## techo de cojín, pelusas, focos de obra de la empresa, un móvil perdido con la
## pantalla encendida, la luz que entra por la rendija y el parpadeo de la tele.
## Se genera por código para iterar rápido; luego se cambia por un modelo.

const HEIGHT := 9.0
const WORK_LIGHTS := [
	Vector3(-14.5, 0, -10), Vector3(-14.5, 0, 8), Vector3(14.5, 0, -11),
	Vector3(14.5, 0, 10), Vector3(-9, 0, 12.5), Vector3(3, 0, 13),
]

var _work_lights: Array[OmniLight3D] = []
var _tv_light: OmniLight3D
var _time := 0.0
var _tv_level := 1.0
var _tv_timer := 0.0


func _ready() -> void:
	var half_x := Balance.ROOM_HALF_X + 1.0
	var half_z := Balance.ROOM_HALF_Z + 1.0
	_build_environment()
	# Asiento, cojín de arriba y laterales
	_solid(Vector3(half_x * 2 + 2, 1, half_z * 2 + 2), Vector3(0, -0.5, 0), "fabric")
	_solid(Vector3(half_x * 2 + 2, 1, half_z * 2 + 2), Vector3(0, HEIGHT + 0.5, 0), "cushion")
	_solid(Vector3(1, HEIGHT, half_z * 2 + 2), Vector3(-half_x - 0.5, HEIGHT / 2, 0), "cushion")
	_solid(Vector3(1, HEIGHT, half_z * 2 + 2), Vector3(half_x + 0.5, HEIGHT / 2, 0), "cushion")
	_solid(Vector3(half_x * 2 + 2, HEIGHT, 1), Vector3(0, HEIGHT / 2, -half_z - 0.5), "cushion")
	_solid(Vector3(half_x * 2 + 2, HEIGHT, 1), Vector3(0, HEIGHT / 2, half_z + 0.5), "cushion")
	_build_cushion_bulges(half_x, half_z)
	_build_lint(half_x, half_z)
	_build_work_lights()
	_build_lost_phone()
	_build_light_gap()
	_build_tv_light()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.38, 0.3)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.25, 0.18, 0.13)
	env.fog_density = 0.01
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.018
	env.volumetric_fog_albedo = Color(0.95, 0.9, 0.85)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)


func _solid(size: Vector3, pos: Vector3, material_key: String) -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(size), pos, material_key)
	Visuals.static_box(self, size, pos, Visuals.LAYER_WORLD)


## Bordes mullidos de los cojines (decorativos, la colisión es la pared).
func _build_cushion_bulges(half_x: float, half_z: float) -> void:
	var bulges := [
		[Vector3(-half_x - 0.5, 2.0, -6), 0.0], [Vector3(-half_x - 0.5, 2.0, 8), 0.0],
		[Vector3(half_x + 0.5, 2.0, -6), 0.0], [Vector3(half_x + 0.5, 2.0, 8), 0.0],
		[Vector3(-8, 2.0, half_z + 0.5), 90.0], [Vector3(8, 2.0, half_z + 0.5), 90.0],
	]
	for bulge in bulges:
		var capsule := CapsuleMesh.new()
		capsule.radius = 2.4
		capsule.height = 12.0
		var instance := Visuals.mesh_instance(self, capsule, bulge[0], "cushion")
		instance.rotation_degrees = Vector3(90, bulge[1], 0)


## Pelusas por los bordes (siempre las mismas gracias a la semilla fija).
func _build_lint(half_x: float, half_z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 24:
		var radius := rng.randf_range(0.4, 1.0)
		var pos: Vector3
		var along := rng.randf_range(-0.9, 0.9)
		match i % 4:
			0:
				pos = Vector3(-half_x + 1.4, radius * 0.6, along * half_z)
			1:
				pos = Vector3(half_x - 1.4, radius * 0.6, along * half_z)
			2:
				pos = Vector3(along * half_x, radius * 0.6, -half_z + 1.0)
			_:
				pos = Vector3(along * half_x, radius * 0.6, half_z - 1.4)
		var lint := SphereMesh.new()
		lint.radius = radius
		lint.height = radius * 2.0
		lint.radial_segments = 9
		lint.rings = 5
		var instance := Visuals.mesh_instance(self, lint, pos, "lint")
		instance.scale = Vector3(1.0, rng.randf_range(0.6, 0.9), rng.randf_range(0.8, 1.3))
		instance.rotation.y = rng.randf_range(0.0, TAU)


## Focos de obra que ha montado la empresa (trípode de palillos y lámpara).
func _build_work_lights() -> void:
	for i in WORK_LIGHTS.size():
		var base: Vector3 = WORK_LIGHTS[i]
		for leg in 3:
			var stick := CylinderMesh.new()
			stick.top_radius = 0.04
			stick.bottom_radius = 0.04
			stick.height = 2.4
			var angle := TAU * leg / 3.0
			var stick_instance := Visuals.mesh_instance(self, stick, base + Vector3(cos(angle) * 0.3, 1.15, sin(angle) * 0.3), "wood")
			stick_instance.rotation = Vector3(sin(angle) * 0.25, 0, -cos(angle) * 0.25)
		var lamp_pos := base + Vector3(0, 2.4, 0)
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.5, 0.35, 0.2)), lamp_pos, "worklight")
		var light := OmniLight3D.new()
		light.position = lamp_pos - base.normalized() * Vector3(0.5, 0, 0.5)
		light.light_color = Color(1.0, 0.85, 0.6)
		light.light_energy = 1.5
		light.omni_range = 11.0
		light.shadow_enabled = i < 3
		add_child(light)
		_work_lights.append(light)


## Un móvil perdido con la pantalla encendida (luz azul en una esquina).
func _build_lost_phone() -> void:
	var phone := Node3D.new()
	phone.position = Vector3(-12.5, 0, -12)
	phone.rotation_degrees = Vector3(0, 30, 0)
	add_child(phone)
	Visuals.mesh_instance(phone, Visuals.box_mesh(Vector3(1.6, 0.18, 3.2)), Vector3(0, 0.09, 0), "remote")
	Visuals.mesh_instance(phone, Visuals.box_mesh(Vector3(1.4, 0.02, 2.9)), Vector3(0, 0.19, 0), "screen")
	Visuals.static_box(phone, Vector3(1.6, 0.18, 3.2), Vector3(0, 0.09, 0), Visuals.LAYER_WORLD)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.0, 0)
	glow.light_color = Color(0.45, 0.7, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 6.0
	phone.add_child(glow)


## Luz del salón entrando por la rendija entre cojines, justo encima de la montaña.
func _build_light_gap() -> void:
	var gap := SpotLight3D.new()
	gap.position = Vector3(0, HEIGHT - 0.3, -6)
	gap.rotation_degrees = Vector3(-90, 0, 0)
	gap.light_color = Color(1.0, 0.92, 0.75)
	gap.light_energy = 6.0
	gap.spot_range = 14.0
	gap.spot_angle = 26.0
	gap.shadow_enabled = true
	gap.light_volumetric_fog_energy = 2.5
	add_child(gap)


## Papá se ha dormido con la tele puesta: su luz azulada parpadea al fondo.
func _build_tv_light() -> void:
	_tv_light = OmniLight3D.new()
	_tv_light.position = Vector3(0, HEIGHT - 1.0, 12)
	_tv_light.light_color = Color(0.55, 0.65, 1.0)
	_tv_light.light_energy = 1.2
	_tv_light.omni_range = 22.0
	add_child(_tv_light)


func _process(delta: float) -> void:
	_time += delta
	for i in _work_lights.size():
		var hum := 0.97 + 0.03 * sin(_time * 50.0 + float(i))
		_work_lights[i].light_energy = 1.5 * hum
	# La tele cambia de plano cada poco: saltos de brillo suaves.
	_tv_timer -= delta
	if _tv_timer <= 0.0:
		_tv_timer = randf_range(0.4, 1.8)
		_tv_level = randf_range(0.5, 1.4)
	_tv_light.light_energy = lerpf(_tv_light.light_energy, 1.2 * _tv_level, clampf(delta * 8.0, 0.0, 1.0))
