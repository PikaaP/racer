class_name MainMenu extends Control

@onready var select_car  = $PlayerConatiner
@onready var play_button = $Play
@onready var select_track = $SelectTrack

const PLAYER_SELECTION = preload('res://menus/main_menu/player_selection/PlayerSelection.tscn')

var input_maps = [
]

func _on_play_pressed() -> void:
	play_button.hide()
	select_car.show()

func _on_select_track_pressed() -> void:
	#set_player_controls()
	set_player_choice()
	select_car.hide()
	select_track.show()

func _on_start_game_pressed() -> void:
	#var game = preload('res://tracks/test_track/TestTrackOval.tscn').instantiate()
	#game.max_laps = 
	#game.selected_track = 
	#get_tree().change_scene_to_packed(game)
	get_tree().change_scene_to_file('res://tracks/Game.tscn')
	
	
	#get_tree().change_scene_to_packed()

# Handle Player controller connect/disconnect
func _handle_joy_connection(index: int, is_connecting: bool) -> void:
	print('controller connected')
	if index >= 3 and is_connecting:
		print('too many players, returning')
		return

	if is_connecting:
		print('new player connected: ', index)
		PlayerManager.players[index] = {'name': 'player_%s' % index}
		select_car.get_child(index).get_child(0).queue_free()
		var player_select = PLAYER_SELECTION.instantiate()
		player_select.player_name = 'Player %s' % index
		select_car.get_child(index).add_child(player_select)
		add_player_controls(index)
		PlayerManager.num_players  += 1
	else:
		PlayerManager.num_players  -= 1
		PlayerManager.players.erase(index)
		print('removing player: ', index)
		select_car.get_child(index).get_child(0).queue_free()
		var container = PanelContainer.new()
		container.set_h_size_flags(2)
		container.set_v_size_flags(2)
		var join_label = Label.new()
		join_label.text = 'Press "X" to join'
		join_label.set_horizontal_alignment(1)
		container.add_child(join_label)
		select_car.add_child(join_label)
		input_maps.remove_at(index)

func add_player_controls(player_index: int) -> void:
	var input_map = {
		"motions": {
			"right": {'control_string': "ui_right_%s" % player_index, 'axis': JOY_AXIS_LEFT_X, 'value': 1.0},
			'left': {'control_string': "ui_left_%s" % player_index, 'axis': JOY_AXIS_LEFT_X, 'value': -1.0},
			'up': {'control_string': "ui_up_%s" % player_index, 'axis': JOY_AXIS_TRIGGER_LEFT, 'value': 1.0},
			'down': {'control_string': "ui_down_%s" % player_index, 'axis': JOY_AXIS_TRIGGER_RIGHT, 'value': 1.0}, 
			},
		
		"buttons":{
			'drift': {'control_string': "drift_%s" % player_index, 'axis': JOY_BUTTON_X}
		}
	}
	
	input_maps.append(input_map)
	set_player_controls()

func set_player_controls():
	for player_index in input_maps.size():
		print('addinging controls for: ', player_index)
		for j in input_maps[player_index]['motions'].size():
			var action: String = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['control_string']
			var action_event: InputEventJoypadMotion
			InputMap.add_action(action)
			# Creat a new InputEvent instance to assign to the InputMap.
			action_event = InputEventJoypadMotion.new()
			action_event.device = player_index
			action_event.axis = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['axis']
			action_event.axis_value = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['value']
			InputMap.action_add_event(action, action_event)

		for b in input_maps[player_index]['buttons'].size():
			var action: String =   input_maps[player_index]['buttons'][input_maps[player_index]['buttons'].keys()[b]]['control_string']
			var action_event: InputEventJoypadButton
			InputMap.add_action(action)
			# Creat a new InputEvent instance to assign to the InputMap.
			action_event = InputEventJoypadButton.new()
			action_event.device = player_index
			InputMap.action_add_event(action, action_event)

func set_player_choice() -> void:
	for player_index in PlayerManager.num_players - 1:
		print('player_index in num players', player_index)
		PlayerManager.players[PlayerManager.players.keys()[player_index]]['selected_car'] = select_car
		PlayerManager.players[PlayerManager.players.keys()[player_index]]['inputs'] = input_maps[player_index]
