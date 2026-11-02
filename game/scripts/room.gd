@tool
extends Node3D
## La habitación: creamy, lofi y minimalista. Paredes y techo crema, suelo de
## madera clara, una ventana con luz de atardecer, lámparas colgantes cálidas,
## dos alfombras bajo las filas de mesas, plantas, una estantería, un
## tocadiscos y un filtro suave de grano y viñeta.

const HALF_X := 9.0
const HALF_Z := 7.0
const HEIGHT := 3.2
const WALL := 0.2
const WINDOW_Z := 2.5  # la ventana va de -WINDOW_Z a WINDOW_Z en la pared izquierda
const WINDOW_BOTTOM := 0.9
const WINDOW_TOP := 2.5

# Filtro lofi: un toque crema, viñeta suave y grano.
const LOFI_SHADER := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength = 0.35;
uniform float grain_strength = 0.035;
uniform vec3 cream = vec3(0.98, 0.94, 0.87);
uniform float cream_mix = 0.07;

float noise(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	color = mix(color, cream, cream_mix);
	vec2 centered = SCREEN_UV - vec2(0.5);
	color *= 1.0 - dot(centered, centered) * vignette_strength * 2.0;
	color += (noise(SCREEN_UV + vec2(TIME * 0.37, TIME * 0.11)) - 0.5) * grain_strength;
	COLOR = vec4(color, 1.0);
}
"""


func _ready() -> void:
	_build_environment()
	_build_shell()
	_build_window()
	_build_lamps()
	_build_furniture()
	if not Engine.is_editor_hint():
		_build_lofi_filter()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.96, 0.92, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.98, 0.9, 0.82)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.4
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 0.9
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(1.0, 0.95, 0.88)
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.9
	env.adjustment_contrast = 0.95
	var world_environment := WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)


## Suelo, techo, paredes (la izquierda con el hueco de la ventana) y rodapiés.
func _build_shell() -> void:
	var width := HALF_X * 2.0 + WALL * 2.0
	var depth := HALF_Z * 2.0 + WALL * 2.0
	_solid(Vector3(width, 0.2, depth), Vector3(0, -0.1, 0), "floor")
	_solid(Vector3(width, 0.2, depth), Vector3(0, HEIGHT + 0.1, 0), "wall")
	_solid(Vector3(width, HEIGHT, WALL), Vector3(0, HEIGHT / 2.0, -HALF_Z - WALL / 2.0), "wall")
	_solid(Vector3(width, HEIGHT, WALL), Vector3(0, HEIGHT / 2.0, HALF_Z + WALL / 2.0), "wall")
	_solid(Vector3(WALL, HEIGHT, HALF_Z * 2.0), Vector3(HALF_X + WALL / 2.0, HEIGHT / 2.0, 0), "wall")
	var left_x := -HALF_X - WALL / 2.0
	var side_length := HALF_Z - WINDOW_Z
	for side in [-1.0, 1.0]:
		_solid(Vector3(WALL, HEIGHT, side_length), Vector3(left_x, HEIGHT / 2.0, side * (WINDOW_Z + side_length / 2.0)), "wall")
	_solid(Vector3(WALL, WINDOW_BOTTOM, WINDOW_Z * 2.0), Vector3(left_x, WINDOW_BOTTOM / 2.0, 0), "wall")
	_solid(Vector3(WALL, HEIGHT - WINDOW_TOP, WINDOW_Z * 2.0), Vector3(left_x, (WINDOW_TOP + HEIGHT) / 2.0, 0), "wall")
	# Rodapiés
	var board_h := 0.08
	for side in [-1.0, 1.0]:
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(HALF_X * 2.0, board_h, 0.03)), Vector3(0, board_h / 2.0, side * (HALF_Z - 0.015)), "baseboard")
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.03, board_h, HALF_Z * 2.0)), Vector3(side * (HALF_X - 0.015), board_h / 2.0, 0), "baseboard")


func _solid(size: Vector3, pos: Vector3, material_key: String) -> void:
	Visuals.mesh_instance(self, Visuals.box_mesh(size), pos, material_key)
	Visuals.static_box(self, size, pos, Visuals.LAYER_WORLD)


## Ventana con cielo de atardecer y la luz del sol entrando en diagonal.
func _build_window() -> void:
	var window_height := WINDOW_TOP - WINDOW_BOTTOM
	var center_y := (WINDOW_BOTTOM + WINDOW_TOP) / 2.0
	var frame_x := -HALF_X - WALL / 2.0
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.02, window_height + 0.6, WINDOW_Z * 2.0 + 0.8)), Vector3(-HALF_X - WALL - 0.8, center_y, 0), "window_glow")
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.06, window_height, 0.06)), Vector3(frame_x, center_y, 0), "wall")
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.06, 0.06, WINDOW_Z * 2.0)), Vector3(frame_x, center_y, 0), "wall")
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.35, 0.05, WINDOW_Z * 2.0 + 0.2)), Vector3(-HALF_X + 0.05, WINDOW_BOTTOM, 0), "baseboard")
	var sun := SpotLight3D.new()
	add_child(sun)
	sun.look_at_from_position(Vector3(-HALF_X - 4.0, 3.2, -1.5), Vector3(-3.0, 0.0, 1.0), Vector3.UP)
	sun.light_color = Color(1.0, 0.8, 0.6)
	sun.light_energy = 6.0
	sun.spot_range = 18.0
	sun.spot_angle = 30.0
	sun.shadow_enabled = true
	sun.light_volumetric_fog_energy = 2.0


## Tres lámparas colgantes sobre el pasillo central y una de pie junto a la ventana.
func _build_lamps() -> void:
	for x in [-5.0, 0.0, 5.0]:
		var cable := CylinderMesh.new()
		cable.top_radius = 0.01
		cable.bottom_radius = 0.01
		cable.height = 0.6
		Visuals.mesh_instance(self, cable, Vector3(x, HEIGHT - 0.3, 0), "ink")
		var shade := CylinderMesh.new()
		shade.top_radius = 0.06
		shade.bottom_radius = 0.26
		shade.height = 0.22
		shade.radial_segments = 24
		Visuals.mesh_instance(self, shade, Vector3(x, HEIGHT - 0.7, 0), "lamp_shade")
		var bulb := SphereMesh.new()
		bulb.radius = 0.06
		bulb.height = 0.12
		Visuals.mesh_instance(self, bulb, Vector3(x, HEIGHT - 0.8, 0), "bulb")
		var light := OmniLight3D.new()
		light.position = Vector3(x, HEIGHT - 0.9, 0)
		light.light_color = Color(1.0, 0.86, 0.66)
		light.light_energy = 0.9
		light.omni_range = 7.5
		light.shadow_enabled = x == 0.0
		add_child(light)
	var lamp_pos := Vector3(-8.3, 0, -4.0)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.02
	pole.bottom_radius = 0.02
	pole.height = 1.6
	Visuals.mesh_instance(self, pole, lamp_pos + Vector3(0, 0.8, 0), "ink")
	var floor_shade := CylinderMesh.new()
	floor_shade.top_radius = 0.14
	floor_shade.bottom_radius = 0.22
	floor_shade.height = 0.3
	Visuals.mesh_instance(self, floor_shade, lamp_pos + Vector3(0, 1.7, 0), "lamp_shade")
	var floor_light := OmniLight3D.new()
	floor_light.position = lamp_pos + Vector3(0, 1.55, 0)
	floor_light.light_color = Color(1.0, 0.84, 0.62)
	floor_light.light_energy = 0.6
	floor_light.omni_range = 5.0
	add_child(floor_light)


func _build_furniture() -> void:
	# Alfombras bajo las dos filas de mesas.
	for rug in [[-3.2, "rug_a"], [3.2, "rug_b"]]:
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.0
		disc.height = 0.02
		disc.radial_segments = 48
		var instance := Visuals.mesh_instance(self, disc, Vector3(0, 0.01, rug[0]), rug[1])
		instance.scale = Vector3(8.0, 1.0, 1.7)
	# Plantas
	for pos in [Vector3(-8.2, 0, -6.2), Vector3(8.2, 0, 6.2), Vector3(-8.2, 0, 5.8)]:
		_plant(pos)
	# Estantería en la pared del fondo, con libros encima.
	var shelf_pos := Vector3(0, 0.9, -HALF_Z + 0.2)
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(2.6, 1.8, 0.35)), shelf_pos, "table")
	Visuals.static_box(self, Vector3(2.6, 1.8, 0.35), shelf_pos, Visuals.LAYER_WORLD)
	var book_colors := ["poster_a", "poster_b", "poster_c", "rug_a", "poster_a", "cream"]
	for i in book_colors.size():
		var book_height := 0.24 + 0.04 * float(i % 3)
		var book_pos := Vector3(-1.0 + i * 0.1, 1.8 + book_height / 2.0, -HALF_Z + 0.2)
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.08, book_height, 0.22)), book_pos, book_colors[i])
	# Cuadros en la pared derecha.
	for poster in [[0.6, "poster_b"], [4.5, "poster_a"]]:
		var poster_pos := Vector3(HALF_X - 0.02, 1.75, poster[0])
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.03, 0.9, 0.7)), poster_pos, "baseplate")
		Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.035, 0.74, 0.54)), poster_pos, poster[1])
	_record_player(Vector3(8.45, 0, 4.5))


func _plant(pos: Vector3) -> void:
	var pot := CylinderMesh.new()
	pot.top_radius = 0.28
	pot.bottom_radius = 0.22
	pot.height = 0.45
	pot.radial_segments = 24
	Visuals.mesh_instance(self, pot, pos + Vector3(0, 0.225, 0), "pot")
	Visuals.static_box(self, Vector3(0.5, 0.45, 0.5), pos + Vector3(0, 0.225, 0), Visuals.LAYER_WORLD)
	for leaf in [[Vector3(0, 0.75, 0), 0.4], [Vector3(-0.2, 0.6, 0.12), 0.3], [Vector3(0.2, 0.62, -0.1), 0.32]]:
		var sphere := SphereMesh.new()
		sphere.radius = leaf[1]
		sphere.height = leaf[1] * 2.0
		Visuals.mesh_instance(self, sphere, pos + leaf[0], "plant")


## Mueble bajo con un tocadiscos (el guiño lofi).
func _record_player(pos: Vector3) -> void:
	var cabinet := Vector3(0.6, 0.65, 1.3)
	Visuals.mesh_instance(self, Visuals.box_mesh(cabinet), pos + Vector3(0, cabinet.y / 2.0, 0), "table")
	Visuals.static_box(self, cabinet, pos + Vector3(0, cabinet.y / 2.0, 0), Visuals.LAYER_WORLD)
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.42, 0.06, 0.46)), pos + Vector3(0, 0.68, 0), "baseplate")
	var record := CylinderMesh.new()
	record.top_radius = 0.17
	record.bottom_radius = 0.17
	record.height = 0.012
	record.radial_segments = 32
	Visuals.mesh_instance(self, record, pos + Vector3(0, 0.717, 0), "ink")
	var label := CylinderMesh.new()
	label.top_radius = 0.05
	label.bottom_radius = 0.05
	label.height = 0.014
	Visuals.mesh_instance(self, label, pos + Vector3(0, 0.718, 0), "coral")
	var arm := Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(0.02, 0.02, 0.22)), pos + Vector3(0.15, 0.74, 0.05), "metal")
	arm.rotation_degrees = Vector3(0, 20, 0)


func _build_lofi_filter() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0  # por debajo de la interfaz, que no lleva grano
	add_child(layer)
	var shader := Shader.new()
	shader.code = LOFI_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var rect := ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
