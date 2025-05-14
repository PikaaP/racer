class_name StoryGame extends Node

@onready var track_holder: Node = $TrackHolder
@onready var countdown_ui = $UI/CountdownUI
@onready var race_over_menu = $UI/RaceOverMenu

const PLAYER_CAMERA = preload("res://player/camera/PlayerCamera.tscn")

@export var series_chapter_data: SeriesChapterData
@export var game_data: GameInstance
@export var player_car_path: String
@export var grid_start_pos: int

var selected_track: StoryTrack

var current_packed_scene: PackedScene

func _ready() -> void:
	SceneManager.call_deferred('fade_scene_in')
	add_to_group('story_game')
	var temp = load(game_data.selected_track_dict['path']).instantiate()
	temp.set_script(load("res://tracks/story_track/story_track.gd"))
	temp.set_process(true)
	selected_track = temp
	selected_track.max_lap_count = game_data.selected_lap_count
	selected_track.enable_ai = game_data.selected_bot_binary
	selected_track.bot_count = game_data.selected_bot_count
	selected_track.series_chapter_data = series_chapter_data
	
	selected_track.player_start_position = grid_start_pos -1
	
	print('event details: ')
	print(selected_track.max_lap_count, ' ml count')
	print(selected_track.bot_count, ' bot coint')
	print(selected_track.enable_ai, ' ai bool')

	selected_track.show_post_race_ui.connect(show_race_over_ui)
	
	track_holder.add_child(selected_track)

	var player = load(player_car_path).instantiate()
	selected_track.add_story_labplayer_to_grid(player, 0)
	
	var camera: PlayerCamera = PLAYER_CAMERA.instantiate()
	player.camera = camera
	camera.follow_target = player
	
	track_holder.add_child(camera)
	
	# Generate Packed instance to restart to
	current_packed_scene = PackedScene.new()
	# Instance scene ready to edit
	var story_instance = preload("res://scenes/game_instances/story_game_instance/StoryGame.tscn").instantiate(1)
	# Pack scene with game data
	story_instance.series_chapter_data = game_data
	story_instance.game_data = game_data.game_instance
	story_instance.player_car_path = game_data.car_path
	story_instance.grid_start_pos = game_data.start_pos_index
	current_packed_scene.pack(story_instance)

	# Connect data to restart button
	race_over_menu.current_scene_packed = current_packed_scene


# Show race over menu after race
func show_race_over_ui() -> void:
	race_over_menu.show()

# Display countdown ui
func start_race_countdown() -> void:
	get_tree().call_group('in_game_ui', 'show')
	await get_tree().create_timer(1.0).timeout
	countdown_ui.start_countdown()

# Handle race start animation
func show_post_race_black_bars() -> void:
	$UI/Effects.show()
	var tween_bar = get_tree().create_tween()
	tween_bar.set_parallel()
	tween_bar.tween_property($UI/Effects/ColorRectTop, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.tween_property($UI/Effects/ColorRectBot, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.chain()
