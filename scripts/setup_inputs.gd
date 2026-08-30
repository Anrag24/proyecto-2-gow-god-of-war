@tool
extends EditorScript

func _run():
	_add_input_action("jump", KEY_SPACE, JOY_BUTTON_A)
	_add_input_action("light_attack", KEY_J, JOY_BUTTON_X)
	_add_input_action("heavy_attack", KEY_K, JOY_BUTTON_Y)
	_add_input_action("block", KEY_L, JOY_BUTTON_LEFT_SHOULDER)
	
	var err = ProjectSettings.save()
	if err == OK:
		print("Entradas configuradas correctamente y guardadas en project.godot")
	else:
		print("Error al guardar project.godot: ", err)

func _add_input_action(action_name: String, key_code: int, joy_btn: int):
	if not ProjectSettings.has_setting("input/" + action_name):
		var events = []
		
		var key_event = InputEventKey.new()
		key_event.physical_keycode = key_code
		events.append(key_event)
		
		var joy_event = InputEventJoypadButton.new()
		joy_event.button_index = joy_btn
		events.append(joy_event)
		
		var setting = {
			"deadzone": 0.5,
			"events": events
		}
		
		ProjectSettings.set_setting("input/" + action_name, setting)
		ProjectSettings.set_initial_value("input/" + action_name, setting)
