class_name Track extends Node3D

@onready var player_holder = $PlayerHolder
@onready var bot_holder = $BotHolder

@onready var track_path: Path3D = $TrackPath
@onready var start_grid = $StartGrid
@onready var countdown_ui: CountDown = $UI/CountdownUI

@export var bot_count: int = 2

var ready_confirmation_count: int = 0
var go_confirmation_count: int = 0

var test_car = preload('res://player/test/test_physics/custom_lambo/custom_racer.tscn')
var test_bot = preload('res://bot/Bot.tscn')

var is_debug: bool = false

func _ready() -> void:
	countdown_ui.race_start.connect(_start_race)
	add_player_to_grid(test_car.instantiate(), 5)
	add_bot_to_grid()

# Add player to track TODO, add player type
func add_player_to_grid(player, index: int) -> void:
	player.ready.connect(_race_ready_confirmation)
	player.race_ready.connect(_start_count_down)
	player.start_position = start_grid.get_child(index).global_position
	player.path = track_path
	player_holder.add_child(player)

# Add bot to track
func add_bot_to_grid() -> void:
	for i in bot_count:
		if i >= 5:
			i += 1
		var start_marker: Marker3D = start_grid.get_child(i)
		var bot: Bot = test_bot.instantiate()
		bot.start_position = start_marker.global_position
		bot.path = track_path
		bot_holder.add_child(bot)

# Call all player to start car opening
func get_ready_showcase() -> void:
	get_tree().call_group('player_camera', 'play_start_animation')

# Once all players are set to ready in the tree, start car display openings
func _race_ready_confirmation() -> void:
	if is_debug:
		_start_race()
		return
	
	ready_confirmation_count += 1
	if ready_confirmation_count == player_holder.get_child_count():
		get_ready_showcase()

# Once all players have finished their car openings start race countdown
func _start_count_down() -> void:
	go_confirmation_count += 1
	if go_confirmation_count == player_holder.get_child_count():
		countdown_ui.start_countdown()

# Allow all player to move :D
func _start_race() -> void:
	get_tree().call_group('player', 'start_race')
	get_tree().call_group('bot', 'start_race')
