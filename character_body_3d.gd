extends CharacterBody3D

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed('ui_right'):
		position.x += 1
	if Input.is_action_pressed('ui_left'):
		position.x -= 1
	if Input.is_action_pressed('ui_up'):
		position.y += 1
	if Input.is_action_pressed('ui_down'):
		position.y -= 1
