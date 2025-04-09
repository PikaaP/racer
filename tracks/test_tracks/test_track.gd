class_name Track extends Node3D

@onready var player_holder = $PlayerHolder
@onready var bot_holder = $BotHolder

@onready var track_path: Path3D = $TrackPath
@onready var start_grid = $StartGrid

@export var bot_count: int = 0
@export var enable_ai: bool

@export var max_lap_count: int = 3


var ready_confirmation_count: int = 0
var go_confirmation_count: int = 0

var all_racers: Array = []
var all_checkpoints: Array = []
var test_bot = preload('res://bot/Bot.tscn')

var avalible_grid_slots: Array = []
var max_grid_slot_size: int = 7

@onready var leaderboard_timer = $LeaderboardTimer
@onready var track_timer: Timer = $TrackTimer

var time: float = 0.0
var start_timer: bool = false
var results_table: Array = []

func _ready() -> void:

	# Store all checkpoint data
	all_checkpoints = get_tree().get_nodes_in_group('checkpoint')

	# If bots enabled, add bots to grid (number given by bot count)
	if enable_ai:
		# Set grid avaible grid slot size to bot count
		avalible_grid_slots.resize(bot_count + PlayerManager.num_players)
	
		# For each bot, add an slot index to grid slot array ( bot count inclusive with +1)
		for i in bot_count + PlayerManager.num_players:
			avalible_grid_slots[i] == i

		# Add all bots to grid
		add_bot_to_grid()
	
	else:
		avalible_grid_slots.resize(PlayerManager.num_players)
		for i in PlayerManager.num_players:
			avalible_grid_slots[i] = i

	# Setup leaderboard tickrate timer
	leaderboard_timer.timeout.connect(_update_leaderboard_ticker)
	# Setup Track countdown timer
	track_timer.timeout.connect(_start_race)

func _process(delta: float) -> void:
	# Race timer, to trrace_startack finish time and lap times
	if start_timer:
		time += delta

# Add player to track TODO, add player type
func add_player_to_grid(player: PlayerCar, player_index) -> void:
	# Starting grid position
	var start_grid_index: int
	
	var random_index = randi_range(0, avalible_grid_slots.size() -1)
	start_grid_index = avalible_grid_slots.pop_at(random_index)
	
	player.race_ready.connect(_start_count_down)
	player.race_over.connect(_race_over_player)

	player.player_index = player_index
	player.start_position = start_grid.get_child(start_grid_index).global_position
	player.path = track_path
	player.max_lap_count = max_lap_count
	player.checkpoint_array = all_checkpoints
	player.inputs = PlayerManager.players[player_index]['inputs']

	player_holder.add_child(player)
	all_racers.append(player)

# Add bots to track
func add_bot_to_grid() -> void:
	for i in bot_count:
		var random_index = randi_range(0, avalible_grid_slots.size() -1)
		var grid_position = avalible_grid_slots.pop_at(random_index)
		print(grid_position)
		var start_marker: Marker3D = start_grid.get_child(grid_position)
		var bot: Bot = test_bot.instantiate()
		bot.start_position = start_marker.global_position
		bot.path = track_path
		bot.max_lap_count = max_lap_count
		bot.checkpoint_array = all_checkpoints
		bot.race_over.connect(_race_over_bot)
		bot_holder.add_child(bot)

		all_racers.append(bot)

# Finds and returns (in ascending order) the ranking of each racers progression in the race
func sort_racer_order() -> Array:
	# All lap data will be appended to answer
	var answer: Array = []
	# Duplicate of all racers
	var leader_board: Array = []
	# Bucket for the unique set of lapped data
	var lap_dict: Dictionary = {}
	
	# Add all racers to local_leaderboard... TODO might redo later
	for racer in all_racers:
		leader_board.append(racer)

	# Bucket all racers by lap and store leaderboard index position in dict of arrays
	# Store current instance of racer distamce varibles
	for racer_index in leader_board.size():
		if !lap_dict.has(leader_board[racer_index].current_lap):
			lap_dict[leader_board[racer_index].current_lap] = [
				{
					'current_lap': leader_board[racer_index].current_lap,
					'current_checkpoint': leader_board[racer_index].current_checkpoint,
					'distance_to_checkpoint': leader_board[racer_index].distance_to_checkpoint,
					'index': racer_index,
				}
			]
		else:
			lap_dict[leader_board[racer_index].current_lap].append(
				{
					'current_lap': leader_board[racer_index].current_lap,
					'current_checkpoint': leader_board[racer_index].current_checkpoint,
					'distance_to_checkpoint': leader_board[racer_index].distance_to_checkpoint,
					'index': racer_index,
				}
			)
	
	# Assert keys are in descending order
	# Sort dict so keys start in ascending order
	lap_dict.sort()
	# Populate new dict with keys inserted in descending order
	var sorted_lap_dict: Dictionary = {}
	# Get keys
	var keys = lap_dict.keys()
	
	# Assert keys are sorted
	keys.sort()
	# Reverse order of keys e.g: (key 3 -> key 1) as bigger lap is better
	keys.reverse()

	# Set correct value to each key in lap_dict
	for key in keys:
		sorted_lap_dict[key] = lap_dict[key]
	

	# For each bucket of laps, find and bucket each checkpoint data groups
	for lap_sub_array: Array in sorted_lap_dict.values():
		# Final sorted bucked holder
		var lap_ans: Array = []
		# Sort by current_checkpoint per lap_dict array
		var checkpoint_holder: Array = []
		# Add racer data to checkpoint holder and sort by checkpoint
		for car_data in lap_sub_array:
			checkpoint_holder.append([car_data.current_checkpoint, car_data.distance_to_checkpoint, car_data.index])
		
		# Sort data by current_checkpoint
		# Sort is returned in descending order (checkpoint 15 -> checkpint 2), like lap, big checkpoint is better
		checkpoint_holder.sort_custom(func(a, b): return a[0] > b[0])
		
		# Bucket holder for each checkpoint
		var checkpoint_dict: Dictionary = {}
		
		# Populate checkpoint_dict bucket with unique keys of checkpoint indexes
		# Parse distance_to_checkpoint [1] and index in leaderboard [2]
		for car_data in checkpoint_holder:
			var key = car_data[0]
			if !checkpoint_dict.has(key):
				checkpoint_dict[key] = [[car_data[1], car_data[2]]]
			else:
				checkpoint_dict[key].append([car_data[1], car_data[2]])

		# For each checkpoint key, append racer index to lap_ans
		# in ascending order (closest, 0.1 -> furthest, 20)
		for checkpoint_sub_array: Array in checkpoint_dict.values():
			# Distance holder for comparison
			var distance_holder: Array = []
			
			# Populate distance_holder with distance_to_checkpoint [0], racer_index [1]
			for car_data in checkpoint_sub_array:
				distance_holder.append([car_data[0], car_data[1]])

			# Sort in ascending order (closest, 0.1 -> furthest, 20)
			distance_holder.sort_custom(func(a, b): return a[0] < b[0])
			
			# Append the racer index of the corresponding distance in distance_holder (sorted_ans_data[1] == racer_index)
			for sorted_ans_data in distance_holder:
				lap_ans.append(sorted_ans_data[1])
		
		# Append array all bucketed lap data into 1 big array :D
		answer.append_array(lap_ans)
	
	# THE sorted leaderboard :D! 
	# Loop over each element and extract the nessacary data to show on leaderboard
	var sorted_leader_board: Array = []
	for racer_index in answer:
		sorted_leader_board.append([leader_board[racer_index], [leader_board[racer_index].current_lap], [leader_board[racer_index].current_checkpoint], [leader_board[racer_index].distance_to_checkpoint]])
	
	# Check what cars have finished theh race and re-insert them into leaderboard
	if !results_table.is_empty():
		for fin_car_index in results_table.size():
			var car = results_table[fin_car_index][1]

			for data_index in sorted_leader_board.size():
				if sorted_leader_board[data_index][0] == car:
					var temp_data = sorted_leader_board.pop_at(data_index)
					sorted_leader_board.insert(fin_car_index, temp_data)
					break


	return sorted_leader_board

# Update leaderboard in .x seconds intervals
func _update_leaderboard_ticker() -> void:
	var sorted_leader_board = sort_racer_order()
	get_tree().call_group('player_camera', 'update_leader_board', sorted_leader_board)

# Once all players have finished their car openings start race countdown
func _start_count_down() -> void:
	go_confirmation_count += 1
	if go_confirmation_count == player_holder.get_child_count():
		get_tree().call_group('player_viewport', 'start_race_countdown')
		track_timer.start()

# Allow all players/ bots to move :D
func _start_race() -> void:
	get_tree().call_group('player', 'start_race')
	get_tree().call_group('bot', 'start_race')
	start_timer = true

func _race_over_player(player: PlayerCar) -> void:
	# Get position
	player.finish_race()
	var finish_data = get_finish_position(player)
	print(player.name, ': ', finish_data)
	# Play finish animation
	
	
	print('*****\n')
	for i in results_table:
		print(i)
	print('\n*****')
	
	# Check if other plays are present and also finished
	var is_last_player: bool = false
	for fin_player in get_tree().get_nodes_in_group("player"):
		for element: Array in results_table:
			if element[1] == fin_player:
				is_last_player = true
				break

	# If all players finished
	# bring up restart, return home menu
	if is_last_player:
		#$UI/RaceOverMenu.show()
		pass
	# Else spectator mode
	# Set other player camera to player
	else:
		var should_break: bool =  false
		for i: PlayerCar in all_racers:
			for element: Array in results_table:
				if !element.has(i):
					player.camera = i.camera
					player.camera.current = true
					should_break = true
					break
			if should_break:
				break

func _race_over_bot(bot: Bot) -> void:
	bot.finish_race()
	var finish_data = get_finish_position(bot)
	print(bot.name, ' :',finish_data)

# Returns race finish position by time
func get_finish_position(car) -> Dictionary:
	var finish_time_delta: float = time
	var msec: float = fmod(finish_time_delta, 1) * 1000
	var sec: float  = fmod(finish_time_delta, 60)
	var m: float = finish_time_delta /60
	
	var formatted_m_s_ms: String = '%02d:%02d:%02d' % [m, sec, msec]
	var actual_m_s_ms = '%s:%s:%s' % [str(m), str(sec), str(msec)]

	results_table.append([finish_time_delta, car])
	results_table.sort_custom(func(a, b): return a[0] < b[0])

	var ans: int
	for i in results_table.size():
		if results_table[i][0] == finish_time_delta and results_table[i][1] == car:
			ans = i
			break
	
	return {'completion_time' : actual_m_s_ms, 'race_result': ans + 1, 'format': formatted_m_s_ms }

# Show pause menu to correct viewport when player presses pause
func _handle_pause(index: int) -> void:
	var target_viewport: PlayerViewport
	if index >= 1:
		target_viewport = get_tree().get_nodes_in_group('player_viewport')[index]
	else:
		target_viewport = get_tree().get_first_node_in_group('player_viewport')
	
	target_viewport.toggle_race_options_menu()
	get_tree().paused = true

func show_race_over_menu() -> void:
	get_tree().call_group('player_viewport', 'show_race_over_ui')
