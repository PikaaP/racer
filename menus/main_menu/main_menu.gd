class_name MainMenu extends Control

@onready var select_car  = $PlayerConatiner
@onready var play_button = $Play
@onready var select_track = $SelectTrack

const PLAYER_SELECTION = preload('res://menus/main_menu/player_selection/PlayerSelection.tscn')

var input_maps = []

func _ready() -> void:
	_handle_joy_connection(0, true)
	

func _on_play_pressed() -> void:
	play_button.hide()
	select_car.show()

func _on_select_track_pressed() -> void:
	set_player_controls()
	set_player_choice()
	select_car.hide()
	select_track.show()

func _on_start_game_pressed() -> void:
	var game: Game = preload("res://tracks/Game.tscn").instantiate()
	#game.max_laps = 
	#game.selected_track = 
	
	
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
	else:
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

func add_player_controls(player_index: int) -> void:
	var input_map = {
		"ui_right_%s" % player_index: [JOY_AXIS_LEFT_X, 1.0],
		"ui_left_%s" % player_index: [JOY_AXIS_LEFT_X, -1.0],
		"ui_up_%s" % player_index: [JOY_AXIS_TRIGGER_RIGHT, 1.0],
		"ui_down_%s" % player_index: [JOY_AXIS_TRIGGER_LEFT, -1.0],
	}
	
	input_maps.append(input_map)

func set_player_controls():
	for player_index in input_maps.size():
		print('addinging controls for: ', player_index)
		for j in input_maps[player_index].size():
			var action: String = input_maps[player_index].keys()[j]
			var action_event: InputEventJoypadMotion
			InputMap.add_action(action)
			# Creat a new InputEvent instance to assign to the InputMap.
			action_event = InputEventJoypadMotion.new()
			action_event.device = player_index
			action_event.axis = input_maps[player_index][action][0] 
			action_event.axis_value =  input_maps[player_index][action][1]
			InputMap.action_add_event(action, action_event)

func set_player_choice() -> void:
	for player_index in get_tree().get_nodes_in_group('player_selection').size():
		PlayerManager.players[PlayerManager.players.keys()[player_index]]['selected_car'] = select_car
		
