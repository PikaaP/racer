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

func _ready() -> void:
	add_to_group('story_game')
	var temp = load(game_data.selected_track_dict['path']).instantiate()
	temp.set_script(load("res://tracks/story_track/story_track.gd"))
	temp.set_process(true)
	selected_track = temp
	selected_track.max_lap_count = game_data.selected_lap_count
	selected_track.enable_ai = game_data.selected_bot_binary
	selected_track.bot_count = game_data.selected_bot_count
	selected_track.series_chapter_data = series_chapter_data
	
	print('event details: ')
	print(selected_track.max_lap_count, ' ml count')
	print(selected_track.bot_count, ' bot coint')
	print(selected_track.enable_ai, ' ai bool')

	track_holder.add_child(selected_track)

	var player = load(player_car_path).instantiate()
	#selected_track.add_story_player_to_grid(player, 0, grid_start_pos)
	selected_track.add_story_labplayer_to_grid(player, 0, grid_start_pos)
	
	var camera: PlayerCamera = PLAYER_CAMERA.instantiate()
	player.camera = camera
	camera.follow_target = player
	
	track_holder.add_child(camera)


# Show race over menu after race
func show_race_over_ui() -> void:
	race_over_menu.show()

# Display countdown ui
func start_race_countdown() -> void:
	countdown_ui.start_countdown()
