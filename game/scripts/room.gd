@tool
extends Node3D
## El cuarto, como un diorama cozy y minimalista: suelo de madera clara con una
## alfombra, luz cálida de tarde con sombras suaves y, al fondo, muebles
## enormes (somos figuritas): la cama, una pila de libros, una planta y la caja
## de juguetes volcada de donde salieron las piezas.

const WALL_HEIGHT := 4.0


func _ready() -> void:
	var half_x := Balance.ROOM_HALF_X + 1.0
	var half_z := Balance.ROOM_HALF_Z + 1.0
	_build_environment()
	_build_sun()
	# Suelo (más grande hacia el fondo para que quepan los muebles) y alfombra
	var floor_size := Vector3(46, 1, 46)
	var floor_pos := Vector3(0, -0.5, -4)
	Visuals.mesh_instance(self, Visuals.box_mesh(floor_size), floor_pos, "floor")
	Visuals.static_box(self, floor_size, floor_pos, Visuals.LAYER_WORLD)
	var rug := CylinderMesh.new()
	rug.top_radius = 13.0
	rug.bottom_radius = 13.0
	rug.height = 0.04
	rug.radial_segments = 64
	Visuals.mesh_instance(self, rug, Vector3(0, 0.02, 0), "rug")
	# Paredes invisibles en el borde de la zona de juego
	for side in [-1.0, 1.0]:
		Visuals.static_box(self, Vector3(1, WALL_HEIGHT, half_z * 2), Vector3(side * (half_x + 0.5), WALL_HEIGHT / 2.0, 0), Visuals.LAYER_WORLD)
		Visuals.static_box(self, Vector3(half_x * 2, WALL_HEIGHT, 1), Vector3(0, WALL_HEIGHT / 2.0, side * (half_z + 0.5)), Visuals.LAYER_WORLD)
	_build_furniture()


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.76, 0.83, 0.95)
	sky_material.sky_horizon_color = Color(0.99, 0.91, 0.85)
	sky_material.ground_horizon_color = Color(0.99, 0.91, 0.85)
	sky_material.ground_bottom_color = Color(0.93, 0.85, 0.8)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.2
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.02
	var world_environment := WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)


## Luz de tarde entrando por la ventana: cálida, baja y con sombras suaves.
func _build_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_color = Color(1.0, 0.93, 0.83)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.light_angular_distance = 1.5
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func _build_furniture() -> void:
	# La cama de Mateo, al fondo a la izquierda.
	Visuals.mesh_instance(self, Visuals.box_mesh(Vector3(16, 6, 10)), Vector3(-10, 3, -21), "blanket")
	var pillow := CapsuleMesh.new()
	pillow.radius = 1.8
	pillow.height = 9.0
	var pillow_instance := Visuals.mesh_instance(self, pillow, Vector3(-16, 7.6, -21), "pillow")
	pillow_instance.rotation_degrees = Vector3(90, 0, 0)
	# Pila de libros, al fondo a la derecha.
	var books := [["book_a", Vector3(9, 1.6, 7), 0.0], ["book_b", Vector3(8, 1.4, 6.5), 8.0], ["book_c", Vector3(8.5, 1.2, 6), -5.0]]
	var height := 0.0
	for book in books:
		var size: Vector3 = book[1]
		var instance := Visuals.mesh_instance(self, Visuals.box_mesh(size), Vector3(13, height + size.y / 2.0, -20), book[0])
		instance.rotation_degrees = Vector3(0, book[2], 0)
		height += size.y
	# Una planta en la esquina.
	var pot := CylinderMesh.new()
	pot.top_radius = 2.6
	pot.bottom_radius = 2.0
	pot.height = 3.5
	pot.radial_segments = 32
	Visuals.mesh_instance(self, pot, Vector3(19, 1.75, 13), "pot")
	for leaf in [Vector3(19, 5.0, 13), Vector3(17.6, 4.2, 12.2), Vector3(20.2, 4.4, 14.0)]:
		var sphere := SphereMesh.new()
		sphere.radius = 1.8
		sphere.height = 3.2
		Visuals.mesh_instance(self, sphere, leaf, "plant")
	# La caja de juguetes volcada (de aquí salieron las piezas).
	var toy_box := Node3D.new()
	toy_box.position = Vector3(-19, 0, 13)
	toy_box.rotation_degrees = Vector3(0, 25, 0)
	add_child(toy_box)
	Visuals.mesh_instance(toy_box, Visuals.box_mesh(Vector3(6, 0.3, 5)), Vector3(0, 0.15, 0), "sky")
	for wall in [[Vector3(6, 3.5, 0.3), Vector3(0, 1.75, -2.35)], [Vector3(0.3, 3.5, 5), Vector3(-2.85, 1.75, 0)], [Vector3(0.3, 3.5, 5), Vector3(2.85, 1.75, 0)]]:
		Visuals.mesh_instance(toy_box, Visuals.box_mesh(wall[0]), wall[1], "sky")
