extends Control

signal go_back()

@onready var back_button: HideBackButton = $MarginContainer/BackButton
@onready var series_holder: GridContainer = $MarginContainer/MarginContainer/SeriesHolder

@export var back_button_endpoint: Node

const SERIES_CHAPTER: PackedScene = preload("res://menus/story_menu/series_chapter/SeriesChapter.tscn")

var series_count: int = 1
var chapter_count: int = 10

var user_save_path = "user://data/story/series_{index}/chapter_{chapter}.tres"
var _save_path = "res://data/story/series_{index}/chapter_{chapter}.tres"

func _ready() -> void:
	# Set up back button
	back_button.back_button_endpoint = back_button_endpoint
	back_button.node_to_hide = self
	back_button.back_pressed.connect(_notify_parent_backing)
	
	# Set up series holder formatting
	series_holder.columns = chapter_count

	# Add a story button for each instance of data found in game files
	_load_story_data()

# Create buttons holding story game instance
func _load_story_data() -> void:
	for i in series_count:
		for j in chapter_count:
			# Generate save paths for file dir and user dir
			# User save path
			var user_save_path = user_save_path.format({'index': str(i), 'chapter': str(j)})
			print(user_save_path)
			var user_data = get_user_data(user_save_path)
			print(user_data)

			# File save path
			var _unique_save_path = _save_path.format({'index': str(i), 'chapter': str(j)})
			print(_unique_save_path, ' game data path')
			var game_data = get_game_data(_unique_save_path)
			# If game data is read, make new button instance from data
			if game_data:
				var new_series_chapter:  = SERIES_CHAPTER.instantiate()

				# If user data exists, parse user data in button for formatting
				if user_data:
					new_series_chapter.user_data = user_data

				# Parse game data
				new_series_chapter.game_data = game_data

				# Add button to scene tree
				series_holder.add_child(new_series_chapter)

# Set up remote calling for hiding current node and showing target node on back button pressed
func _setup_back_button() -> void:
	back_button.back_button_endpoint = back_button_endpoint
	back_button.node_to_hide = self

# Return user data if exists
func get_user_data(save_path: String) -> PlayerStoryData:
	if ResourceLoader.exists(save_path):
		return load(save_path)
	return null

# Return game data if exists
func get_game_data(save_path) -> SeriesChapterData:
	if ResourceLoader.exists(save_path):
		return load(save_path)
	return null

# Emit signal to notify parent back button is pressed
func _notify_parent_backing() -> void:
	go_back.emit()
