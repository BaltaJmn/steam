extends Node
## Registra los controles por código para que el proyecto funcione sin tocar
## Project Settings > Input Map. Si defines una acción ahí, se respeta la tuya.

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E],
	"drop": [KEY_Q],
}
const MOUSE_BUTTONS := {
	"interact": [MOUSE_BUTTON_LEFT],
}


func _ready() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEYS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key
			InputMap.action_add_event(action, key_event)
		for button in MOUSE_BUTTONS.get(action, []):
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = button
			InputMap.action_add_event(action, mouse_event)
