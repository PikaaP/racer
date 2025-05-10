class_name GameInstance extends Resource

@export var selected_lap_count: int = 3
@export var selected_bot_count: int = 10
@export var selected_bot_difficulty: String = 'Elite'
@export var selected_bot_binary: bool = true

@export var selected_track_dict: Dictionary = {
	'track_name': 'xx.xx.xxxx',
	'thumbnail': "res://icon.svg",
	'path': "res://tracks/test_tracks/BotOvalTester.tscn",
}
