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
	var background := ColorRect.new()
	background.color = Color(0.07, 0.05, 0.04)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(460, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "COUCH CREW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Prototipo · encontrad el mando de la tele sin despertar a %s" % Balance.SLEEPER_NAME
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	box.add_child(HSeparator.new())
	var name_label := Label.new()
	name_label.text = "Tu nombre"
	box.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.text = Network.player_name
	_name_edit.max_length = 20
	box.add_child(_name_edit)

	_add_button(box, "Jugar solo", _on_solo)
	_add_button(box, "Crear partida (host)", _on_host)
	var join_row := HBoxContainer.new()
	box.add_child(join_row)
	_address_edit = LineEdit.new()
	_address_edit.text = "127.0.0.1"
	_address_edit.placeholder_text = "IP del host"
	_address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(_address_edit)
	_add_button(join_row, "Unirse", _on_join)
	_add_button(box, "Salir", get_tree().quit)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.6))
	box.add_child(_status)


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
		_status.text = "No se pudo crear la partida (¿el puerto %d está ocupado?)." % Network.PORT
		return
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_join() -> void:
	_save_name()
	if Network.join(_address_edit.text.strip_edges()) != OK:
		_status.text = "Dirección no válida."
		return
	_status.text = "Conectando..."
	_set_busy(true)


func _on_connected() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)


func _on_connection_failed(reason: String) -> void:
	_status.text = reason
	_set_busy(false)
