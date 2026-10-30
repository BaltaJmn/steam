extends CanvasLayer
## Interfaz: contadores, ruido, aviso de interacción, avisos, mejoras y pausa.
## Se construye por código para no depender de escenas de UI todavía.

var _info: Label
var _carry: Label
var _prompt: Label
var _toast: Label
var _win: Label
var _noise_bar: ProgressBar
var _upgrades_panel: PanelContainer
var _upgrades_list: VBoxContainer
var _wallet_label: Label
var _pause_panel: PanelContainer
var _toast_tween: Tween
var _upgrade_buttons := {}  # id de mejora -> Button
var _shown_levels := ""


func _ready() -> void:
	add_to_group("hud")
	_build()
	Game.changed.connect(_on_game_changed)
	Game.game_event.connect(_on_game_event)
	_refresh_all()


# --- API que usan el jugador y el tablón ---

func set_prompt(text: String) -> void:
	_prompt.text = text


func is_menu_open() -> bool:
	return _upgrades_panel.visible or _pause_panel.visible


func open_upgrades() -> void:
	_rebuild_upgrades()
	_upgrades_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_upgrades() -> void:
	_upgrades_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toast(text: String, color := Color.WHITE) -> void:
	_toast.text = text
	_toast.modulate = color
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 1.0)


# --- Construcción ---

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_info = _label(root, 22)
	_place(_info, 0, 0, 0, 0, 24, 16, 600, 140)

	var crosshair := _label(root, 30, HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.text = "·"
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(crosshair, 0, 0.5, 1, 0.5, 0, -20, 0, 20)

	_prompt = _label(root, 24, HORIZONTAL_ALIGNMENT_CENTER)
	_place(_prompt, 0, 0.5, 1, 0.5, 0, 30, 0, 64)

	_carry = _label(root, 22, HORIZONTAL_ALIGNMENT_CENTER)
	_place(_carry, 0, 1, 1, 1, 0, -84, 0, -52)

	var help := _label(root, 16)
	help.text = "WASD mover · Shift correr (¡hace ruido!) · Espacio saltar · E / clic interactuar · Q soltar · Esc pausa"
	help.modulate = Color(1, 1, 1, 0.7)
	_place(help, 0, 1, 1, 1, 24, -36, -24, -10)

	var noise_title := _label(root, 18, HORIZONTAL_ALIGNMENT_CENTER)
	noise_title.text = "Ruido · no despiertes a %s" % Balance.SLEEPER_NAME
	_place(noise_title, 0.5, 0, 0.5, 0, -220, 10, 220, 34)
	_noise_bar = ProgressBar.new()
	_noise_bar.max_value = Balance.NOISE_MAX
	_noise_bar.show_percentage = false
	_noise_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_noise_bar)
	_place(_noise_bar, 0.5, 0, 0.5, 0, -170, 38, 170, 56)

	_toast = _label(root, 30, HORIZONTAL_ALIGNMENT_CENTER)
	_place(_toast, 0, 0.26, 1, 0.26, 0, 0, 0, 44)

	_win = _label(root, 44, HORIZONTAL_ALIGNMENT_CENTER)
	_win.text = "¡Ahí estaba el mando! %s lo coge sin abrir los ojos, pone el fútbol y sigue roncando." % Balance.SLEEPER_NAME_CAP
	_win.modulate = Color(1.0, 0.85, 0.4)
	_win.visible = false
	_place(_win, 0, 0.14, 1, 0.14, 0, 0, 0, 60)

	_build_upgrades_panel(root)
	_build_pause_panel(root)


func _build_upgrades_panel(root: Control) -> void:
	_upgrades_panel = PanelContainer.new()
	_upgrades_panel.visible = false
	root.add_child(_upgrades_panel)
	_place(_upgrades_panel, 0.5, 0.5, 0.5, 0.5, -360, -280, 360, 280)
	var box := _margin_box(_upgrades_panel)
	var title := _label(box, 30)
	title.text = "Mejoras de la cuadrilla"
	_wallet_label = _label(box, 22)
	_upgrades_list = VBoxContainer.new()
	_upgrades_list.add_theme_constant_override("separation", 8)
	_upgrades_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_upgrades_list)
	var close := Button.new()
	close.text = "Cerrar (Esc)"
	close.pressed.connect(close_upgrades)
	box.add_child(close)


func _build_pause_panel(root: Control) -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.visible = false
	root.add_child(_pause_panel)
	_place(_pause_panel, 0.5, 0.5, 0.5, 0.5, -220, -130, 220, 130)
	var box := _margin_box(_pause_panel)
	var title := _label(box, 30, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "Pausa"
	var info := _label(box, 16, HORIZONTAL_ALIGNMENT_CENTER)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if multiplayer.is_server() and Network.is_online():
		info.text = "Eres el host: los demás se unen con tu IP (puerto %d)." % Network.PORT
	var resume := Button.new()
	resume.text = "Continuar"
	resume.pressed.connect(_close_pause)
	box.add_child(resume)
	var quit := Button.new()
	quit.text = "Salir al menú"
	quit.pressed.connect(_quit_to_menu)
	box.add_child(quit)


func _margin_box(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box


func _label(parent: Control, size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _place(
	c: Control, anchor_l: float, anchor_t: float, anchor_r: float, anchor_b: float,
	off_l: float, off_t: float, off_r: float, off_b: float
) -> void:
	c.anchor_left = anchor_l
	c.anchor_top = anchor_t
	c.anchor_right = anchor_r
	c.anchor_bottom = anchor_b
	c.offset_left = off_l
	c.offset_top = off_t
	c.offset_right = off_r
	c.offset_bottom = off_b


# --- Actualización ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _upgrades_panel.visible:
			close_upgrades()
		elif _pause_panel.visible:
			_close_pause()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
	# Se recaptura al soltar el clic, para que ese mismo clic no interactúe.
	elif event is InputEventMouseButton and event.is_released() and not is_menu_open():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _open_pause() -> void:
	_pause_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause() -> void:
	_pause_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _quit_to_menu() -> void:
	var world = get_tree().get_first_node_in_group("world")
	if world:
		world.return_to_menu()


func _on_game_changed(what: String, id: int) -> void:
	match what:
		"noise":
			_refresh_noise()
		"workers":
			pass
		"player":
			if id == Game.my_id():
				_refresh_carry()
		"economy":
			_refresh_info()
			_refresh_carry()
			if _upgrades_panel.visible:
				_refresh_upgrades()
		_:
			_refresh_all()


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	match ev_name:
		"snort":
			toast("¡%s ronca, se revuelve y da un manotazo! %s sale volando" % [Balance.SLEEPER_NAME_CAP, data.get("name", "")], Color(1.0, 0.55, 0.35))
		"bought":
			var upgrade: Dictionary = Balance.UPGRADES.get(data.get("upgrade", ""), {})
			toast("%s ha comprado: %s (nivel %d)" % [data.get("name", ""), upgrade.get("name", "?"), int(data.get("level", 0))], Color(0.7, 1.0, 0.7))
		"joined":
			toast("%s se ha unido a la cuadrilla" % data.get("name", ""), Color(0.8, 0.9, 1.0))
		"left":
			toast("%s se ha ido" % data.get("name", ""), Color(0.8, 0.8, 0.8))
		"complete":
			_win.visible = true


func _refresh_all() -> void:
	_refresh_info()
	_refresh_carry()
	_refresh_noise()
	_win.visible = Game.completed


func _refresh_info() -> void:
	var lines := PackedStringArray()
	lines.append("Migas recogidas: %d / %d" % [Game.crumbs_sorted(), Game.crumbs_total()])
	lines.append("Objetos devueltos: %d / %d" % [Game.items_placed(), Game.items.size()])
	lines.append("Calderilla: %d" % Game.wallet)
	var workers := int(Game.upgrade_value("workers"))
	if workers > 0:
		lines.append("Hormigas contratadas: %d" % workers)
	_info.text = "\n".join(lines)


func _refresh_carry() -> void:
	var data: Dictionary = Game.me()
	if data.is_empty():
		_carry.text = ""
		return
	var item_id := int(data["item"])
	var load_kind: String = data["load_kind"]
	if item_id != -1 and Game.items.has(item_id):
		_carry.text = "Llevas: %s · [Q] soltar" % Balance.item_name(Game.items[item_id]["type"])
	elif load_kind == "mixed":
		_carry.text = "Llevas: %d / %d migas mezcladas · [Q] devolver" % [Game.load_total(data), Game.capacity()]
	elif load_kind != "":
		_carry.text = "Llevas: %d / %d migas de %s · [Q] devolver" % [Game.load_total(data), Game.capacity(), Balance.KIND_NAMES[load_kind]]
	else:
		_carry.text = ""


func _refresh_noise() -> void:
	_noise_bar.value = Game.noise
	var t := clampf(Game.noise / Balance.NOISE_MAX, 0.0, 1.0)
	_noise_bar.modulate = Color(0.45, 0.85, 0.45).lerp(Color(1.0, 0.3, 0.2), t)


## Cambia el dinero muy a menudo (tobogán, compañeros...): si no ha cambiado
## ningún nivel, solo se actualizan los botones para no perder clics.
func _refresh_upgrades() -> void:
	if str(Game.upgrades) != _shown_levels:
		_rebuild_upgrades()
		return
	_wallet_label.text = "Calderilla disponible: %d" % Game.wallet
	for id in _upgrade_buttons:
		var cost: int = Game.upgrade_cost(id)
		var button: Button = _upgrade_buttons[id]
		button.disabled = cost < 0 or Game.wallet < cost


func _rebuild_upgrades() -> void:
	for child in _upgrades_list.get_children():
		_upgrades_list.remove_child(child)
		child.queue_free()
	_upgrade_buttons.clear()
	_shown_levels = str(Game.upgrades)
	_wallet_label.text = "Calderilla disponible: %d" % Game.wallet
	for id in Balance.UPGRADE_ORDER:
		var definition: Dictionary = Balance.UPGRADES[id]
		var costs: Array = definition["costs"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text := Label.new()
		text.text = "%s  (nivel %d/%d)\n%s" % [definition["name"], Game.upgrade_level(id), costs.size(), definition["desc"]]
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 0)
		var cost: int = Game.upgrade_cost(id)
		if cost < 0:
			button.text = "Al máximo"
			button.disabled = true
		else:
			button.text = "Comprar (%d)" % cost
			button.disabled = Game.wallet < cost
			button.pressed.connect(Game.request.bind("_srv_buy", [id]))
		_upgrade_buttons[id] = button
		row.add_child(button)
		_upgrades_list.add_child(row)
