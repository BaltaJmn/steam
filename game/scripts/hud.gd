extends CanvasLayer
## Interfaz del juego: creamy y minimalista (estilo en UiStyle).
## - Arriba a la izquierda, una tarjeta con el progreso.
## - En el centro, un puntito de mira y una pastilla con lo que puedes hacer,
##   con la tecla dibujada.
## - Abajo, lo que llevas en la cesta, con un puntito por color.
## - Avisos en pastilla, la tienda de cositas monas, la pausa y el final.

const HINT_SECONDS := 14.0

var _root: Control
var _figures_value: Label
var _pieces_bar: ProgressBar
var _pieces_value: Label
var _floor_value: Label
var _specials_row: HBoxContainer
var _specials_value: Label
var _stickers_value: Label
var _chicks_row: HBoxContainer
var _chicks_value: Label
var _prompt_pill: PanelContainer
var _prompt_key: PanelContainer
var _prompt_label: Label
var _carry_pill: PanelContainer
var _carry_box: HBoxContainer
var _toast_pill: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _hint_pill: PanelContainer
var _win_card: PanelContainer
var _noise_bar: ProgressBar
var _shop: PanelContainer
var _shop_list: VBoxContainer
var _shop_wallet: Label
var _shop_buttons := {}  # id de la cosita -> Button
var _shown_levels := ""
var _pause: PanelContainer


func _ready() -> void:
	add_to_group("hud")
	_build()
	Game.changed.connect(_on_game_changed)
	Game.game_event.connect(_on_game_event)
	_refresh_all()
	# La chuleta de controles se va sola al rato.
	var fade := create_tween()
	fade.tween_interval(HINT_SECONDS)
	fade.tween_property(_hint_pill, "modulate:a", 0.0, 1.5)


# --- API que usan el jugador y la tienda ---

## Texto de lo que puedes hacer. Si empieza por "[E] ", la tecla se dibuja aparte.
func set_prompt(text: String) -> void:
	_prompt_pill.visible = text != ""
	var has_key := text.begins_with("[E] ")
	_prompt_key.visible = has_key
	_prompt_label.text = (text.substr(4) if has_key else text).to_lower()


func is_menu_open() -> bool:
	return _shop.visible or _pause.visible


func open_upgrades() -> void:
	_rebuild_shop()
	_shop.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_upgrades() -> void:
	_shop.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toast(text: String) -> void:
	_toast_label.text = text
	_toast_pill.visible = true
	_toast_pill.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast_pill, "modulate:a", 0.0, 0.8)


# --- Construcción ---

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiStyle.theme()
	add_child(_root)
	_build_progress_card()
	_build_center()
	_build_bottom()
	_build_toast_and_win()
	_build_shop()
	_build_pause()


## Tarjeta de progreso, arriba a la izquierda.
func _build_progress_card() -> void:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiStyle.card(0.9))
	card.custom_minimum_size = Vector2(270, 0)
	_root.add_child(card)
	_place(card, 0, 0, 0, 0, 24, 22, 294, 22)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(UiStyle.label("tu habitación", 14, UiStyle.TEXT_SOFT, 800))
	_figures_value = _stat_row(box, "figuras", 24)
	_pieces_bar = ProgressBar.new()
	_pieces_bar.show_percentage = false
	_pieces_bar.custom_minimum_size = Vector2(0, 10)
	_pieces_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_pieces_bar)
	_pieces_value = _stat_row(box, "piezas colocadas", 17)
	_floor_value = _stat_row(box, "en el suelo", 17)
	_specials_value = _stat_row(box, "especiales por poner", 17)
	_specials_row = _specials_value.get_parent() as HBoxContainer
	_stickers_value = _stat_row(box, "pegatinas", 17, UiStyle.ROSE)
	_chicks_value = _stat_row(box, "pollitos", 17)
	_chicks_row = _chicks_value.get_parent() as HBoxContainer


## Fila "nombre ........ valor" (con un puntito delante si se pide).
func _stat_row(parent: Control, name_text: String, value_size: int, dot_color := Color(0, 0, 0, 0)) -> Label:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	if dot_color.a > 0.0:
		var dot_box := CenterContainer.new()
		dot_box.add_child(UiStyle.dot(dot_color, 12))
		row.add_child(dot_box)
	var name_label := UiStyle.label(name_text, 16, UiStyle.TEXT_SOFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value := UiStyle.label("", value_size, UiStyle.TEXT, 800)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return value


## Puntito de mira y la pastilla de "lo que puedes hacer".
func _build_center() -> void:
	var crosshair := UiStyle.dot(Color(UiStyle.TEXT, 0.65), 8)
	_root.add_child(crosshair)
	_place(crosshair, 0.5, 0.5, 0.5, 0.5, -4, -4, 4, 4)

	_prompt_pill = PanelContainer.new()
	_prompt_pill.add_theme_stylebox_override("panel", UiStyle.pill())
	_prompt_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_pill.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_pill.add_child(row)
	_prompt_key = UiStyle.keycap("E")
	row.add_child(_prompt_key)
	_prompt_label = UiStyle.label("", 19)
	row.add_child(_prompt_label)
	_center_under(_prompt_pill, 0.5, 34)


## Abajo: lo que llevas en la cesta y, al empezar, la chuleta de controles.
func _build_bottom() -> void:
	_carry_pill = PanelContainer.new()
	_carry_pill.add_theme_stylebox_override("panel", UiStyle.pill())
	_carry_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carry_pill.visible = false
	_carry_box = HBoxContainer.new()
	_carry_box.add_theme_constant_override("separation", 8)
	_carry_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carry_pill.add_child(_carry_box)
	_center_under(_carry_pill, 1.0, -84)

	_hint_pill = PanelContainer.new()
	_hint_pill.add_theme_stylebox_override("panel", UiStyle.pill(0.8))
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation", 6)
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_pill.add_child(hints)
	for pair in [["WASD", "moverte"], ["E", "coger y dejar"], ["Q", "soltar"], ["Esc", "pausa"]]:
		hints.add_child(UiStyle.keycap(pair[0]))
		hints.add_child(UiStyle.label(pair[1] + "   ", 15, UiStyle.TEXT_SOFT))
	_root.add_child(_hint_pill)
	_place(_hint_pill, 0, 1, 0, 1, 24, -62, 24, -24)
	_hint_pill.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_toast_and_win() -> void:
	_toast_pill = PanelContainer.new()
	_toast_pill.add_theme_stylebox_override("panel", UiStyle.pill(0.95))
	_toast_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_pill.visible = false
	_toast_label = UiStyle.label("", 20, UiStyle.TEXT, 700)
	_toast_pill.add_child(_toast_label)
	_center_under(_toast_pill, 0.0, 26)

	_win_card = PanelContainer.new()
	_win_card.add_theme_stylebox_override("panel", UiStyle.card())
	_win_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_card.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_card.add_child(box)
	var title := UiStyle.label("¡todo listo!", 34, UiStyle.ROSE_DARK, 800)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := UiStyle.label("las 10 figuras montadas y el suelo impecable.\nmañana nadie pisará una pieza.", 19, UiStyle.TEXT_SOFT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	_center_under(_win_card, 0.0, 120)


## Tienda de cositas monas.
func _build_shop() -> void:
	_shop = PanelContainer.new()
	_shop.visible = false
	_root.add_child(_shop)
	_place(_shop, 0.5, 0.5, 0.5, 0.5, -360, -300, 360, 300)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_shop.add_child(box)
	box.add_child(UiStyle.label("tienda de cositas monas", 30, UiStyle.TEXT, 800))
	_shop_wallet = UiStyle.label("", 17, UiStyle.TEXT_SOFT)
	box.add_child(_shop_wallet)
	box.add_child(HSeparator.new())
	_shop_list = VBoxContainer.new()
	_shop_list.add_theme_constant_override("separation", 10)
	_shop_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_shop_list)
	var close := Button.new()
	close.text = "cerrar"
	close.theme_type_variation = "GhostButton"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(close_upgrades)
	box.add_child(close)


func _build_pause() -> void:
	_pause = PanelContainer.new()
	_pause.visible = false
	_root.add_child(_pause)
	_place(_pause, 0.5, 0.5, 0.5, 0.5, -210, -150, 210, 150)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_pause.add_child(box)
	var title := UiStyle.label("pausa", 30, UiStyle.TEXT, 800)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	if multiplayer.is_server() and Network.is_online():
		var info := UiStyle.label("eres el host: los demás se unen con tu IP (puerto %d)" % Network.PORT, 15, UiStyle.TEXT_SOFT)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(info)
	var resume := Button.new()
	resume.text = "seguir jugando"
	resume.pressed.connect(_close_pause)
	box.add_child(resume)
	var quit := Button.new()
	quit.text = "salir al menú"
	quit.theme_type_variation = "GhostButton"
	quit.pressed.connect(_quit_to_menu)
	box.add_child(quit)
	if Balance.NOISE_ENABLED:
		_noise_bar = ProgressBar.new()
		_noise_bar.max_value = Balance.NOISE_MAX
		_noise_bar.show_percentage = false
		_noise_bar.custom_minimum_size = Vector2(260, 10)
		_noise_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(_noise_bar)
		_place(_noise_bar, 0.5, 0, 0.5, 0, -130, 24, 130, 34)


## Centra un control en horizontal, a la altura "anchor_y" de la pantalla
## (0 arriba, 0.5 en medio, 1 abajo) y desplazado "offset_y" píxeles.
func _center_under(control: Control, anchor_y: float, offset_y: float) -> void:
	_root.add_child(control)
	_place(control, 0.5, anchor_y, 0.5, anchor_y, 0, offset_y, 0, offset_y)
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN if anchor_y >= 1.0 else Control.GROW_DIRECTION_END


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
		if _shop.visible:
			close_upgrades()
		elif _pause.visible:
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
	_pause.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause() -> void:
	_pause.visible = false
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
			if _shop.visible:
				_refresh_shop()
		_:
			_refresh_all()


func _on_game_event(ev_name: String, data: Dictionary) -> void:
	match ev_name:
		"snort":
			toast("¡demasiado ruido! (%s)" % data.get("name", ""))
		"figure_done":
			toast("¡figura terminada: %s!" % str(data.get("name", "")).to_lower())
		"bought":
			var upgrade: Dictionary = Balance.UPGRADES.get(data.get("upgrade", ""), {})
			toast("%s ha comprado %s" % [data.get("name", ""), str(upgrade.get("name", "?")).to_lower()])
		"joined":
			toast("%s se ha unido" % data.get("name", ""))
		"left":
			toast("%s se ha ido" % data.get("name", ""))
		"complete":
			_win_card.visible = true


func _refresh_all() -> void:
	_refresh_info()
	_refresh_carry()
	_refresh_noise()
	_win_card.visible = Game.completed


func _refresh_info() -> void:
	_figures_value.text = "%d / %d" % [Game.figures_done(), Game.figures.size()]
	var total := maxi(1, Game.pieces_total())
	_pieces_bar.max_value = total
	_pieces_bar.value = Game.pieces_placed()
	_pieces_value.text = "%d / %d" % [Game.pieces_placed(), Game.pieces_total()]
	_floor_value.text = str(Game.floor_total())
	var hidden := Game.items.size() - Game.items_placed()
	_specials_value.text = str(hidden)
	_specials_row.visible = hidden > 0
	_stickers_value.text = str(Game.wallet)
	var chicks := int(Game.upgrade_value("workers"))
	_chicks_value.text = str(chicks)
	_chicks_row.visible = chicks > 0


## Lo que llevas: una pieza especial, o la cesta con un puntito por color.
func _refresh_carry() -> void:
	for child in _carry_box.get_children():
		_carry_box.remove_child(child)
		child.queue_free()
	var data: Dictionary = Game.me()
	if data.is_empty():
		_carry_pill.visible = false
		return
	var item_id := int(data["item"])
	if item_id != -1 and Game.items.has(item_id):
		_carry_box.add_child(UiStyle.label("llevas: %s" % Balance.item_name(Game.items[item_id]["type"]).to_lower(), 18))
		_carry_box.add_child(UiStyle.keycap("Q"))
		_carry_box.add_child(UiStyle.label("soltar", 16, UiStyle.TEXT_SOFT))
		_carry_pill.visible = true
		return
	if data["load_kind"] == "":
		_carry_pill.visible = false
		return
	_carry_box.add_child(UiStyle.label("cesta %d/%d" % [Game.load_total(data), Game.capacity()], 18, UiStyle.TEXT, 800))
	for kind in Balance.KINDS:
		var amount := int(data["load"].get(kind, 0))
		if amount > 0:
			var dot_box := CenterContainer.new()
			dot_box.add_child(UiStyle.dot(Visuals.COLORS[kind], 14))
			_carry_box.add_child(dot_box)
			_carry_box.add_child(UiStyle.label(str(amount), 18))
	_carry_box.add_child(UiStyle.keycap("Q"))
	_carry_box.add_child(UiStyle.label("devolver", 16, UiStyle.TEXT_SOFT))
	_carry_pill.visible = true


func _refresh_noise() -> void:
	if _noise_bar:
		_noise_bar.value = Game.noise


## Cambia el dinero muy a menudo: si no ha cambiado ningún nivel, solo se
## actualizan los botones para no perder clics.
func _refresh_shop() -> void:
	if str(Game.upgrades) != _shown_levels:
		_rebuild_shop()
		return
	_shop_wallet.text = _wallet_text()
	for id in _shop_buttons:
		var cost: int = Game.upgrade_cost(id)
		var button: Button = _shop_buttons[id]
		button.disabled = cost < 0 or Game.wallet < cost


func _wallet_text() -> String:
	return "tienes %d pegatinas · lo que compras es para todo el grupo" % Game.wallet


## Una tarjetita por cosita: icono redondo con su inicial, nombre, qué hace,
## puntitos de nivel y el precio.
func _rebuild_shop() -> void:
	for child in _shop_list.get_children():
		_shop_list.remove_child(child)
		child.queue_free()
	_shop_buttons.clear()
	_shown_levels = str(Game.upgrades)
	_shop_wallet.text = _wallet_text()
	var icon_colors := ["yellow", "coral", "sky", "mint", "cocoa", "yellow", "coral"]
	var index := 0
	for id in Balance.UPGRADE_ORDER:
		var definition: Dictionary = Balance.UPGRADES[id]
		var costs: Array = definition["costs"]
		var level := Game.upgrade_level(id)
		var row_card := PanelContainer.new()
		var row_style := UiStyle.box(UiStyle.CREAM, 16, 14, 8)
		row_style.shadow_size = 0
		row_card.add_theme_stylebox_override("panel", row_style)
		_shop_list.add_child(row_card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row_card.add_child(row)
		# Icono: círculo de color con la inicial.
		var icon := PanelContainer.new()
		var icon_style := UiStyle.box(Visuals.COLORS[icon_colors[index % icon_colors.size()]], 20, 0, 0)
		icon_style.shadow_size = 0
		icon.add_theme_stylebox_override("panel", icon_style)
		icon.custom_minimum_size = Vector2(40, 40)
		var initial := UiStyle.label(str(definition["name"]).left(1), 20, UiStyle.CARD, 800)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_child(initial)
		var icon_box := CenterContainer.new()
		icon_box.add_child(icon)
		row.add_child(icon_box)
		# Nombre y descripción
		var texts := VBoxContainer.new()
		texts.add_theme_constant_override("separation", 0)
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_child(UiStyle.label(str(definition["name"]).to_lower(), 19, UiStyle.TEXT, 800))
		texts.add_child(UiStyle.label(str(definition["desc"]).to_lower(), 15, UiStyle.TEXT_SOFT))
		row.add_child(texts)
		# Puntitos de nivel
		var dots := HBoxContainer.new()
		dots.add_theme_constant_override("separation", 4)
		for i in costs.size():
			dots.add_child(UiStyle.dot(UiStyle.ROSE if i < level else UiStyle.TRACK, 10))
		var dots_box := CenterContainer.new()
		dots_box.add_child(dots)
		row.add_child(dots_box)
		# Precio
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 0)
		var cost: int = Game.upgrade_cost(id)
		if cost < 0:
			button.text = "¡ya lo tienes!"
			button.disabled = true
		else:
			button.text = "%d pegatinas" % cost
			button.disabled = Game.wallet < cost
			button.pressed.connect(Game.request.bind("_srv_buy", [id]))
			_shop_buttons[id] = button
		var button_box := CenterContainer.new()
		button_box.add_child(button)
		row.add_child(button_box)
		index += 1
