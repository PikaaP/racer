class_name CarSelectMenu extends Control

signal go_back()

@onready var select_car  = $PlayerConatiner/SelectCar
@onready var player_container  = $PlayerConatiner

@onready var select_track: SelectTrackMenu = $SelectTrack
@onready var select_track_button: Button = $PlayerConatiner/MarginContainer/SelectTrack
@onready var back_button: HideBackButton = $PlayerConatiner/MarginContainer/BackButton

@export var back_button_endpoint: Node

const PLAYER_SELECTION = preload('res://menus/car_select_menu/player_selection/PlayerSelection.tscn')

var input_maps = [
]

func _ready() -> void:
	Input.joy_connection_changed.connect(_handle_joy_connection)

	back_button.back_button_endpoint = back_button_endpoint
	back_button.back_pressed.connect(_notify_parent_backing)
	back_button.node_to_hide = self

	for player_key in PlayerManager.players:
		_handle_joy_connection(player_key, true)


func _on_select_track_pressed() -> void:
	set_player_choice()
	player_container.hide()
	select_track.show()

# Handle Player controller connect/disconnect
func _handle_joy_connection(index: int, is_connecting: bool) -> void:
	print('controller connected')
	if index >= 3 and is_connecting:
		print('too many players, returning')
		return

	if is_connecting:
		if !PlayerManager.players.has(index):
			PlayerManager.num_players  += 1
		print('new player connected: ', index)
		PlayerManager.players[index] = {'name': 'player_%s' % index}
		select_car.get_child(index).get_child(0).queue_free()
		var player_select = PLAYER_SELECTION.instantiate()
		player_select.player_name = 'Player %s' % index
		select_car.get_child(index).add_child(player_select)
		add_player_controls(index)

		# Enable track select button if atleast one track is avalible
		if select_track_button.disabled:
			select_track_button.disabled = false
		
	else:
		# Remove count from total player count
		PlayerManager.num_players  -= 1

		# Disable select track button if there are no connected controllers
		if PlayerManager.num_players < 1:
			select_track_button.disabled = true
		
		# Remove player index from PlayerManager
		PlayerManager.players.erase(index)
		# Remove UI instance and replace with default join panel
		select_car.get_child(index).get_child(0).queue_free()
		var join_label = Label.new()
		join_label.text = 'Press "X" to join'
		join_label.set_horizontal_alignment(1)
		select_car.get_child(index).add_child(join_label)

		# Remove input map
		input_maps.remove_at(index)

# Store new player contorls as Dict and store them in Game
func add_player_controls(player_index: int) -> void:
	var input_map = {
		"motions": {
			"right": {'control_string': "ui_right_%s" % player_index, 'axis': JOY_AXIS_LEFT_X, 'value': -1.0},
			'left': {'control_string': "ui_left_%s" % player_index, 'axis': JOY_AXIS_LEFT_X, 'value': 1.0},
			'up': {'control_string': "ui_up_%s" % player_index, 'axis': JOY_AXIS_TRIGGER_RIGHT, 'value': 1.0},
			'down': {'control_string': "ui_down_%s" % player_index, 'axis': JOY_AXIS_TRIGGER_LEFT, 'value': 1.0}, 
			},
		
		"buttons":{
			'boost': {'control_string': "boost_%s" % player_index, 'button_index': JOY_BUTTON_A},
			'drift': {'control_string': "drift_%s" % player_index, 'button_index': JOY_BUTTON_X},
			'menu': {'control_string': "menu_%s" % player_index, 'button_index': JOY_BUTTON_START},
		}
	}
	
	input_maps.append(input_map)
	# Set contorls in game
	set_player_controls()

# Set player controls in game
func set_player_controls():
	for player_index in input_maps.size():
		print('addinging controls for: ', player_index)
		for j in input_maps[player_index]['motions'].size():
			var action: String = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['control_string']
			var action_event: InputEventJoypadMotion
			# Check if action is already registered
			if !InputMap.has_action(action):
				InputMap.add_action(action)
			# Creat a new InputEvent instance to assign to the InputMap.
			action_event = InputEventJoypadMotion.new()
			action_event.device = player_index
			action_event.axis = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['axis']
			action_event.axis_value = input_maps[player_index]['motions'][input_maps[player_index]['motions'].keys()[j]]['value']
			InputMap.action_add_event(action, action_event)

		for b in input_maps[player_index]['buttons'].size():
			var action: String = input_maps[player_index]['buttons'][input_maps[player_index]['buttons'].keys()[b]]['control_string']
			# Check if action is already registered
			if !InputMap.has_action(action):
				InputMap.add_action(action)
			# Creat a new InputEvent instance to assign to the InputMap.
			var action_event: InputEventJoypadButton = InputEventJoypadButton.new()
			action_event.device = player_index
			action_event.button_index = input_maps[player_index]['buttons'][input_maps[player_index]['buttons'].keys()[b]]['button_index']
			InputMap.action_add_event(action, action_event)

# Store all player variables in global script PlayerManager
func set_player_choice() -> void:
	for player_index in PlayerManager.players:
		# Get chosen car
		PlayerManager.players[player_index]['selected_car'] = select_car.get_child(player_index).get_child(0).selected_car
		# Get chosen name
		PlayerManager.players[player_index]['player_name'] = select_car.get_child(player_index).get_child(0).player_name
		# Get input map
		PlayerManager.players[player_index]['inputs'] = input_maps[player_index]

# Emit signal to notify parent back button is pressed
func _notify_parent_backing() -> void:
	go_back.emit()
