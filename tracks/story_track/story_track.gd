class_name StoryTrack extends Track

@export var series_chapter_data: SeriesChapterData

func _ready() -> void:
	add_to_group('track')
	track_cam_path.get_child(0).follow_path()

	# Store all checkpoint data
	all_checkpoints = get_tree().get_nodes_in_group('checkpoint')

	# If bots enabled, add bots to grid (number given by bot count)
	if enable_ai:
		# Set grid avaible grid slot size to bot count
		avalible_grid_slots.resize(bot_count + 1)
	
		# For each bot, add an slot index to grid slot array ( bot count inclusive with +1)
		for i in bot_count + 1:
			avalible_grid_slots[i] = i

		# Add all bots to grid
		#add_bot_to_grid()
	
	else:
		avalible_grid_slots.resize(1)
		for i in 1:
			avalible_grid_slots[i] = i
	
	# Setup leaderboard tickrate timer
	leaderboard_timer.timeout.connect(_update_leaderboard_ticker)
	# Setup Track countdown timer
	track_timer.timeout.connect(_start_race)

# Add sory player a specifc grid pos
func add_story_player_to_grid(player: PlayerCar, player_index, grid_position) -> void:
	# Starting grid position
	var start_grid_index: int
	
	var random_index = randi_range(0, avalible_grid_slots.size() -1)
	start_grid_index = avalible_grid_slots.pop_at(grid_position -1)
	
	player.race_ready.connect(_start_count_down)
	player.race_over.connect(_race_over_player)
	player.lap_completed.connect(_store_lap)

	player.player_index = player_index
	player.start_position = start_grid.get_child(start_grid_index).global_position
	player.path = track_path
	player.max_lap_count = max_lap_count
	player.checkpoint_array = all_checkpoints
	player.inputs = PlayerManager.players[player_index]['inputs']
	player.player_name = PlayerManager.players[player_index]['player_name']
	
	player_lap_table[player_index] = {'name': player.player_name}
	
	player_holder.add_child(player)
	all_racers.append(player)

func add_story_labplayer_to_grid(player, player_index, grid_position) -> void:
	print(player, ' player, here')
	# Starting grid position
	var start_grid_index: int
	start_grid_index = avalible_grid_slots.pop_at(grid_position -1)
	
	player.race_ready.connect(_start_count_down)
	player.race_over.connect(_race_over_player)
	player.lap_completed.connect(_store_lap)

	player.player_index = player_index
	player.start_position = start_grid.get_child(start_grid_index).global_position
	player.start_direction = start_grid.get_child(start_grid_index).global_position + -start_grid.get_child(start_grid_index).global_basis.z * 10

	player.path = track_path
	player.max_lap_count = max_lap_count
	player.checkpoint_array = all_checkpoints

	player_lap_table[player_index] = {'name': 'test_dev'}
	
	player_holder.add_child(player)
	all_racers.append(player)

# Once all players have finished their car openings start race countdown
func _start_count_down() -> void:
	get_tree().call_group('story_game', 'start_race_countdown')
	track_timer.start()

#func _race_over_player(player: PlayerCar) -> void:
func _race_over_player(player) -> void:
	# Get position
	player.finish_race()
	
	# Get dict of race result for player
	var finish_data = get_finish_position(player)
	
	# Store fastest lap variable
	var new_time = player_lap_table[player.player_index]['best_lap_time']
	
	# Generate user save path from series id and chapter id
	var user_save_path = "user://data/story/series_{index}/chapter_{chapter}.tres"
	user_save_path = user_save_path.format({'index': series_chapter_data.series_id, 'chapter': series_chapter_data.chapter_id})
	
	# Generate inernal save path from series id and chapter id
	var _save_path = "res://data/story/series_{index}/chapter_{chapter}.tres"

	save_story_progress(series_chapter_data, new_time, finish_data['race_result'], user_save_path)

func award_medal() -> void:
	pass

func save_story_progress(story_data: SeriesChapterData, new_time: float, medal_award, user_save_path: String) -> void:
	
	print('starting save')
	#user_save_path = user_save_path.format({'index': story_data.series_id, 'chapter': story_data.chapter_id})
	print(user_save_path, ' user save path')
	
	# Format save directory
	var user_save_dir = user_save_path.split('/chapter')[0]
	user_save_dir = user_save_dir.split('user://')[1]
	print(user_save_dir, 'user_save_dir')
	
	
	medal_award = story_data._handle_unluck_reward(medal_award)

	# If user has data, check existing data to update if better scored achived
	if ResourceLoader.exists(user_save_path):
		print('user data exists')
		var _existing_user_data: PlayerStoryData = ResourceLoader.load(user_save_path)
		print(_existing_user_data.best_time, ' existing besttime')
		print(new_time, ' new time comp')

		var new_best_time = null if _existing_user_data.best_time < new_time else new_time

		# Save user data if medal awarded and there is a new best time
		print(medal_award, ' medal award')
		print(new_best_time, ' new best time')
		if medal_award and new_best_time != null:
			print('has awards and best time')

			# Make new user data instance
			var new_user_data = PlayerStoryData.new()
			new_user_data.medal_achieved = medal_award
			new_user_data.best_time = new_best_time

			# Mark entry as completed if success condion is met
			# Make refernce to unlock level if applicable
			if story_data._handle_unluck_reward(medal_award) and !_existing_user_data.completed:
				print('should unlock new next level')
				new_user_data.completed = true
				# Create empty player data resource for newly unlocked file
				if ResourceLoader.exists(story_data.generate_unlock_path()):
					var empty_unlocked_data = PlayerStoryData.new()
					ResourceSaver.save(empty_unlocked_data, story_data.generate_unlock_path())

			# Save
			ResourceSaver.save(new_user_data, user_save_path)
		else:
			print('no awards so no save')
		
	# If there is no existing data
	# Create new player data
	# If race condition is cleared, unlock next race by storying reference in user files
	else:
		print('no existing data cirmcumstance')
		var dir = DirAccess.open('user://')
		var s = dir.make_dir_recursive(user_save_dir)
		print(user_save_dir,'dir to save to')
		print(s, ' make dir succesul')

		var new_user_data = PlayerStoryData.new()
		new_user_data.medal_achieved = medal_award
		new_user_data.best_time = new_time

		if story_data._handle_unluck_reward(medal_award):
			new_user_data.completed = true

			if ResourceLoader.exists(story_data.generate_unlock_path()):
				print('has unlock data')
				var empty_unlocked_data = PlayerStoryData.new()
				ResourceSaver.save(empty_unlocked_data, story_data.generate_unlock_path())

		ResourceSaver.save(new_user_data, user_save_path)
		print('save over')

func load_track_data() -> TrackData:
	if ResourceLoader.exists(save_path):
		return load(save_path)
	return null
