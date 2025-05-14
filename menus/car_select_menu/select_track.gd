class_name SelectTrackMenu extends PanelContainer

# Lap count display buttons
@onready var lap_count_button: MenuButton =  $VBoxContainer/Settings/LapSettings/MenuButton

# Enable bot buttons
@onready var ai_bool: CheckButton = $VBoxContainer/Settings/AISettings/AIToggle/AI
# Enable label
@onready var ai_bool_label: Label = $VBoxContainer/Settings/AISettings/AIToggle/AISelection

# Decrease bot count button
@onready var num_bot_left: Button = $VBoxContainer/Settings/AISettings/NumBots/HBoxContainer/LeftArrow
# Increase bot count button
@onready var num_bot_right: Button = $VBoxContainer/Settings/AISettings/NumBots/HBoxContainer/RightArrow
# bot count display label
@onready var bot_count_label: Label = $VBoxContainer/Settings/AISettings/NumBots/HBoxContainer/Label

# Increase bot difficulty button
@onready var bot_difficulty_right: Button = $VBoxContainer/Settings/AISettings/BotDifficulty/HBoxContainer2/RightArrow
# Decrease bot difficulty button
@onready var bot_difficulty_left: Button = $VBoxContainer/Settings/AISettings/BotDifficulty/HBoxContainer2/LeftArrow
# bot difficulty display label
@onready var bot_difficulty_label: Label = $VBoxContainer/Settings/AISettings/BotDifficulty/HBoxContainer2/Label

# Select track left
@onready var select_track_left: Button = $VBoxContainer/Track/HBoxContainer/MarginContainer/TrackSelectLeft
# Select track Right
@onready var select_track_right: Button = $VBoxContainer/Track/HBoxContainer/MarginContainer/TrackSelectRight
# Selected track lable
@onready var selected_track_label: Label = $VBoxContainer/Track/HBoxContainer/MarginContainer/TrackName
# Selected track thumbail
@onready var selected_track_thumbnail: TextureRect = $VBoxContainer/Track/TrackThumbnail

# Start game button
@onready var start_game_button: Button = $VBoxContainer/Settings/MarginContainer/StartGame

# Track data
var track_data: Array = [
	{
		'track_name': 'Bot Oval Track',
		'thumbnail': "res://icon.svg",
		'path': "res://tracks/test_tracks/BotOvalTester.tscn",
	},
	{
		'track_name': 'Home',
		'thumbnail': "res://icon.svg",
		'path': "res://tracks/track_series_0/Home.tscn",
	},
]

# Difficulty options
var difficulty_options: Array = [
	'Junior',
	'Elite',
	'AI',
]

# Game settings variables
# Selected number of laps
var selected_lap_count: int = 3
# Enable bots bool
var selected_bot_binary: bool = true
# Max number of bots
var max_bot_count: int = 7
# Selected difficulty reference to difficulty_options dict
var current_difficulty_index: int = 1
# Selected bot difficulty data
var selected_bot_difficulty: String
# Selected bot count
var selected_bot_count: int = 7
# Selected track refence to track_data dict
var current_selected_track_index: int = 0
# Selected track data
var selected_track_dict: Dictionary


func _ready() -> void:
	# Connect button functions
	# Lap counter
	lap_count_button.get_popup().id_pressed.connect(_set_lap_count)
	# Enable Bot bool
	ai_bool.toggled.connect(_set_ai_binary)
	# Select Left/Right bot count
	num_bot_left.pressed.connect(_update_bot_count.bind('left'))
	num_bot_right.pressed.connect(_update_bot_count.bind('right'))
	# Select Left/Right bot difficulty 
	bot_difficulty_left.pressed.connect(_update_bot_difficulty.bind('left'))
	bot_difficulty_right.pressed.connect(_update_bot_difficulty.bind('right'))
	# Select Left/Right track
	select_track_left.pressed.connect(_update_selected_track.bind('left'))
	select_track_right.pressed.connect(_update_selected_track.bind('right'))
	
	# Start game pressed
	start_game_button.pressed.connect(_on_start_game_pressed)

	# Set buttons to default state
	# Bot difficulty
	bot_difficulty_label.text = difficulty_options[1]
	# No bots
	ai_bool.set_pressed_no_signal(false)
	_set_ai_binary(false)
	
	# Display default track
	_update_selected_track('default')

# Update lap count text and internal variable
func _set_lap_count(index: int) -> void:
	# Update text
	lap_count_button.text = lap_count_button.get_popup().get_item_text(index)
	# Update internal variable
	selected_lap_count = int(lap_count_button.get_popup().get_item_text(index))

# Update use bot varible
func _set_ai_binary(toggled: bool) -> void:
	# Handle set to true
	# Update internal varible and set default values
	if toggled:
		# Update selection var
		selected_bot_binary = true
		# Set default varibles
		selected_bot_count = max_bot_count
		current_difficulty_index = 1
		selected_bot_difficulty = difficulty_options[1]
		
		# Update labels
		ai_bool_label.text = 'On'
		bot_count_label.text = str(max_bot_count)
		bot_difficulty_label.text = difficulty_options[current_difficulty_index]
		
		# Enable button features
		num_bot_left.disabled = false
		num_bot_right.disabled = false
		bot_difficulty_left.disabled = false
		bot_difficulty_right.disabled = false
	
	# Handle set to false
	# Update internal var and lables
	else:
		# Update reference varibles
		selected_bot_binary  = false
		selected_bot_count = 0
		
		# Update lables
		ai_bool_label.text = 'Off'
		bot_count_label.text = str(0)
		bot_difficulty_label.text = 'N/A'
		bot_difficulty_label.text = str('N/A')
		
		# Disable buttons
		num_bot_left.disabled = true
		num_bot_right.disabled = true
		bot_difficulty_left.disabled = true
		bot_difficulty_right.disabled = true

# Handle change in bot count
func _update_bot_count(dir: String):
	# Update internal var and displayed var for each input detected
	match dir:
		'left':
			selected_bot_count -= 1
			if selected_bot_count <= 0:
				selected_bot_count = max_bot_count
		'right':
			selected_bot_count += 1
			if selected_bot_count > max_bot_count:
				selected_bot_count = 1
		'default':
			bot_count_label.text = str(max_bot_count)
			return

	# Update display
	bot_count_label.text = str(selected_bot_count)


# Hadnle change in bot difficulty
func _update_bot_difficulty(dir: String) -> void:
	# Update internal var and displayed var for each input detected
	match dir:
		'left':
			current_difficulty_index -= 1
			if current_difficulty_index < 0:
				current_difficulty_index = difficulty_options.size() -1
		'right':
			current_difficulty_index += 1
			if current_difficulty_index >= difficulty_options.size():
				current_difficulty_index = 0
		'default':
			current_difficulty_index = 1
			bot_difficulty_label.text = difficulty_options[1]
			return
	
	# Update display
	bot_difficulty_label.text = difficulty_options[current_difficulty_index]
	selected_bot_difficulty = difficulty_options[current_difficulty_index]

# Hadnle change in selected track
func _update_selected_track(dir: String) -> void:
	# Update internal var and displayed var for each input detected
	match dir:
		'left':
			current_selected_track_index -= 1
			if current_selected_track_index < 0:
				current_selected_track_index = track_data.size() -1
		'right':
			current_selected_track_index += 1
			if current_selected_track_index >= track_data.size():
				current_selected_track_index = 0
		'default':
			current_selected_track_index = 0
	
	# Update internal var
	selected_track_dict = track_data[current_selected_track_index]
	
	# Update display
	selected_track_label.text = track_data[current_selected_track_index]['track_name']
	selected_track_thumbnail.texture = load(track_data[current_selected_track_index]['thumbnail'])

# Create a new game resource and parse data in GameManager singleton
# Remove current scene tree and replace with Game scene
func _on_start_game_pressed() -> void:
	# Generate game instance
	var game_instance = GameInstance.new()
	game_instance.selected_lap_count = selected_lap_count
	game_instance.selected_bot_count = selected_bot_count
	game_instance.selected_bot_difficulty = selected_bot_difficulty
	game_instance.selected_bot_binary = selected_bot_binary
	game_instance.selected_track_dict = selected_track_dict
	
	# Store game instance in singleton
	GameManager.game_instance_data = game_instance
	# Make Game scene new root instance
	SceneManager.change_scene_to_file('res://scenes/game_instances/coop_game_instance/CoopGame.tscn')
