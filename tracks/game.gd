class_name Game extends Node

@onready var viewport_holder = $ViewportHolder
@onready var track_holder: Node = $ViewportHolder/SubViewportContainer/SubViewport/Track

@export var selected_track: Track
@export var max_laps: int = 2


var player_camera = preload('res://Player/camera/camera_3d.tscn')
var player_paths = ["res://cars/lambo/Lambo_v1.tscn", "res://cars/lambo/Lambo_v1.tscn", "res://cars/lambo/Lambo_v1.tscn" ]
var multiplayer_viewport = preload('res://scenes/multiplayer_viewport/MultiPlayerViewport.tscn')

const track = 'res://tracks/test_tracks/TestTrackFlat.tscn'

func _ready() -> void:
	selected_track = preload(track).instantiate()
	track_holder.add_child(selected_track)
	for i in PlayerManager.num_players -1:
		if i == 0:
			var player: PlayerCar = load(player_paths[i]).instantiate()
			player.max_lap_count = max_laps
			player.inputs = PlayerManager.players[i]['inputs']
			player.player_index = i
			selected_track.add_to_grid(player, i)
			var camera = player_camera.instantiate()
			player.camera = camera
			camera.follow_this = player
			var port = get_tree().get_nodes_in_group('viewport')[i]
			port.add_child(camera)
		else:
			print(' adding in game for: ',  i)
			var viewport = multiplayer_viewport.instantiate()
			viewport_holder.add_child(viewport)
			var player: PlayerCar = load(player_paths[i]).instantiate()
			player.inputs = PlayerManager.players[i]['inputs']
			player.player_index = i
			player.max_lap_count = max_laps
			selected_track.add_to_grid(player, i)
			var camera = player_camera.instantiate()
			player.camera = camera
			camera.follow_this = player
			var port = get_tree().get_nodes_in_group('viewport')[i]
			port.add_child(camera)
			

func _handle_player_win(player: PlayerCar) -> void:
	print('Player %s has won' % player.name)
