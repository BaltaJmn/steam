extends Control
## Menú principal: jugar solo, crear partida (host) o unirse por IP.

const WORLD_SCENE := "res://scenes/world.tscn"

var _name_edit: LineEdit
var _address_edit: LineEdit
var _status: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Network.connected_ok.connect(_on_connected)
	Network.connection_failed.connect(_on_connection_failed)
	_build()
	_status.text = Network.last_message
	Network.last_message = ""


func _build() -> void:
	theme = UiStyle.theme()
	var background := ColorRect.new()
	background.color = UiStyle.CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)

	# Tres bloques de colores, el título y una frase.
	var bricks := HBoxContainer.new()
	bricks.alignment = BoxContainer.ALIGNMENT_CENTER
	bricks.add_theme_constant_override("separation", 10)
	column.add_child(bricks)
	for kind in ["coral", "yellow", "sky"]:
		bricks.add_child(_brick(Visuals.COLORS[kind]))
	var title := UiStyle.label("the floor is bricks", 60, UiStyle.ROSE_DARK, 800)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := UiStyle.label("busca las piezas por el suelo y monta las 10 figuras", 19, UiStyle.TEXT_SOFT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	# Tarjeta con el nombre y los botones.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	box.add_child(UiStyle.label("tu nombre", 16, UiStyle.TEXT_SOFT))
	_name_edit = LineEdit.new()
	_name_edit.text = Network.player_name
	_name_edit.max_length = 20
	box.add_child(_name_edit)
	_add_button(box, "jugar solo", _on_solo)
	_add_button(box, "crear partida", _on_host)
	box.add_child(HSeparator.new())
	box.add_child(UiStyle.label("unirse a una partida", 16, UiStyle.TEXT_SOFT))
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	box.add_child(join_row)
	_address_edit = LineEdit.new()
	_address_edit.text = "127.0.0.1"
	_address_edit.placeholder_text = "IP del host"
	_address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(_address_edit)
	_add_button(join_row, "unirse", _on_join)

	_status = UiStyle.label("", 16, UiStyle.ROSE_DARK)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	var quit := Button.new()
	quit.text = "salir"
	quit.theme_type_variation = "GhostButton"
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(get_tree().quit)
	column.add_child(quit)


## Un bloque de construcción dibujado: rectángulo redondeado con dos pivotes.
func _brick(color: Color) -> Control:
	var brick := VBoxContainer.new()
	brick.add_theme_constant_override("separation", 0)
	var studs := HBoxContainer.new()
	studs.alignment = BoxContainer.ALIGNMENT_CENTER
	studs.add_theme_constant_override("separation", 12)
	brick.add_child(studs)
	for i in 2:
		var stud := Panel.new()
		var stud_style := StyleBoxFlat.new()
		stud_style.bg_color = color
		stud_style.corner_radius_top_left = 5
		stud_style.corner_radius_top_right = 5
		stud.add_theme_stylebox_override("panel", stud_style)
		stud.custom_minimum_size = Vector2(16, 8)
		studs.add_child(stud)
	var body := Panel.new()
	var body_style := UiStyle.box(color, 10, 0, 0)
	body.add_theme_stylebox_override("panel", body_style)
	body.custom_minimum_size = Vector2(64, 34)
	brick.add_child(body)
	return brick


func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	_buttons.append(button)


func _set_busy(busy: bool) -> void:
	for button in _buttons:
		button.disabled = busy


func _save_name() -> void:
	var player_name := _name_edit.text.strip_edges()
	if player_name != "":
		Network.player_name = player_name


func _on_solo() -> void:
	_save_name()
	Network.start_solo()
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_host() -> void:
	_save_name()
	if Network.host() != OK:
		_status.text = "no se pudo crear la partida (¿el puerto %d está ocupado?)" % Network.PORT
		return
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_join() -> void:
	_save_name()
	if Network.join(_address_edit.text.strip_edges()) != OK:
		_status.text = "esa dirección no es válida"
		return
	_status.text = "conectando..."
	_set_busy(true)


func _on_connected() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_connection_failed(reason: String) -> void:
	_status.text = reason
	_set_busy(false)
