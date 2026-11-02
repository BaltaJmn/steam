@tool
class_name UiStyle
extends RefCounted
## Estilo de la interfaz: creamy, minimalista y bonito. Tarjetas crema con
## esquinas muy redondeadas y una sombra suave, texto cacao, botones rosa
## empolvado y la tipografía Nunito (redondeada, licencia OFL en fonts/).
## Todo lo que es interfaz usa theme() y estas piezas, así queda coherente.

const FONT_PATH := "res://fonts/Nunito.ttf"

const CREAM := Color(0.98, 0.95, 0.9)
const CARD := Color(1.0, 0.985, 0.96)
const TEXT := Color(0.38, 0.31, 0.3)
const TEXT_SOFT := Color(0.6, 0.53, 0.5)
const ROSE := Color(0.89, 0.64, 0.6)
const ROSE_LIGHT := Color(0.93, 0.72, 0.68)
const ROSE_DARK := Color(0.8, 0.54, 0.5)
const LINE := Color(0.9, 0.85, 0.79)
const TRACK := Color(0.93, 0.89, 0.84)
const SHADOW := Color(0.45, 0.32, 0.25, 0.12)

static var _theme: Theme
static var _fonts := {}


## Nunito con el grosor pedido (400 normal, 700 negrita...). Si no está la
## fuente, la de Godot.
static func font(weight := 600) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var result: Font = ThemeDB.fallback_font
	if ResourceLoader.exists(FONT_PATH):
		var variation := FontVariation.new()
		variation.base_font = load(FONT_PATH)
		variation.variation_opentype = {"wght": weight}
		result = variation
	_fonts[weight] = result
	return result


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(600)
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)

	# Botones: rosa empolvado, muy redondeados.
	t.set_stylebox("normal", "Button", box(ROSE, 16, 20, 10))
	t.set_stylebox("hover", "Button", box(ROSE_LIGHT, 16, 20, 10))
	t.set_stylebox("pressed", "Button", box(ROSE_DARK, 16, 20, 10))
	t.set_stylebox("disabled", "Button", box(TRACK, 16, 20, 10))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", CARD)
	t.set_color("font_disabled_color", "Button", TEXT_SOFT)
	t.set_font("font", "Button", font(700))

	# Botón discreto (solo texto), para "salir", "cerrar"...
	t.set_type_variation("GhostButton", "Button")
	for state in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(state, "GhostButton", box(Color(0, 0, 0, 0), 16, 12, 6))
	for state in ["font_color", "font_focus_color"]:
		t.set_color(state, "GhostButton", TEXT_SOFT)
	t.set_color("font_hover_color", "GhostButton", ROSE_DARK)
	t.set_color("font_pressed_color", "GhostButton", ROSE_DARK)

	# Campos de texto
	var field := box(CARD, 14, 14, 10)
	field.set_border_width_all(2)
	field.border_color = LINE
	field.shadow_size = 0
	var field_focus := field.duplicate() as StyleBoxFlat
	field_focus.border_color = ROSE
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_SOFT)
	t.set_color("caret_color", "LineEdit", ROSE_DARK)
	t.set_color("selection_color", "LineEdit", Color(ROSE, 0.35))

	# Tarjetas y barras
	t.set_stylebox("panel", "PanelContainer", card())
	var track := box(TRACK, 8, 0, 0)
	track.shadow_size = 0
	var fill := box(ROSE, 8, 0, 0)
	fill.shadow_size = 0
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", fill)
	var line := StyleBoxLine.new()
	line.color = LINE
	line.thickness = 2
	t.set_stylebox("separator", "HSeparator", line)
	_theme = t
	return t


## Caja redondeada con un poco de sombra.
static func box(color: Color, radius: int, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.shadow_color = SHADOW
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.anti_aliasing = true
	return style


## Tarjeta crema (la base de casi toda la interfaz).
static func card(alpha := 0.96) -> StyleBoxFlat:
	return box(Color(CARD, alpha), 22, 22, 16)


## Pastilla pequeña (avisos, lo que llevas en la cesta...).
static func pill(alpha := 0.92) -> StyleBoxFlat:
	return box(Color(CARD, alpha), 999, 18, 8)


static func label(text: String, size := 20, color := TEXT, weight := 600) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Una tecla dibujada como una pastillita ("E", "Q").
static func keycap(key: String) -> PanelContainer:
	var cap := PanelContainer.new()
	var style := box(TRACK, 8, 8, 2)
	style.shadow_size = 0
	style.border_width_bottom = 3
	style.border_color = LINE
	cap.add_theme_stylebox_override("panel", style)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(label(key, 16, TEXT, 800))
	return cap


## Puntito redondo de color (los colores de las piezas).
static func dot(color: Color, size := 14) -> Panel:
	var circle := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(size)
	style.anti_aliasing = true
	circle.add_theme_stylebox_override("panel", style)
	circle.custom_minimum_size = Vector2(size, size)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return circle
