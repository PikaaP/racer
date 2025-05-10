class_name Game extends Node

@onready var viewport_holder = $ViewportHolder
@onready var track_holder: Node = $ViewportHolder/PlayerViewport/TrackHolder


@export var selected_track: Track

const PLAYER_CAMERA = preload("res://player/camera/PlayerCamera.tscn")
const PLAYER_VIEWPORT = preload('res://scenes/player_viewport/PlayerViewport.tscn')

func _ready() -> void:
	GameManager.current_game = self
	var game_data: GameInstance = GameManager.get_game_data()
	selected_track = load(game_data.selected_track_dict['path']).instantiate()
	selected_track.max_lap_count = game_data.selected_lap_count
	selected_track.bot_count = game_data.selected_bot_count
	selected_track.enable_ai = game_data.selected_bot_binary

	track_holder.add_child(selected_track)
	for i in PlayerManager.num_players:
		var player: PlayerCar = load(PlayerManager.players[i]['selected_car']).instantiate()
		if i == 0:
			selected_track.add_player_to_grid(player, i)
			var camera: PlayerCamera = PLAYER_CAMERA.instantiate()
			player.camera = camera
			camera.follow_target = player
			var port = get_tree().get_nodes_in_group('sub_viewport')[i]
			port.add_child(camera)
		else:
			selected_track.add_player_to_grid(player, i)
			var viewport = PLAYER_VIEWPORT.instantiate()
			viewport_holder.add_child(viewport)
			var camera:  = PLAYER_CAMERA.instantiate()
			player.camera = camera
			camera.follow_this = player
			var port = get_tree().get_nodes_in_group('viewport')[i]
			port.add_child(camera)
