class_name StoryRaceOverMenu extends PanelContainer

@onready var restart_button: Button = $VBoxContainer/Restart
@onready var race_select_button: Button = $VBoxContainer/RaceSelect
@onready var main_mennu_button: Button = $VBoxContainer/MainMenu

@export var current_scene_packed: PackedScene

func _ready() -> void:
	restart_button.pressed.connect(_handle_restart)
	restart_button.process_mode = PROCESS_MODE_ALWAYS

	race_select_button.pressed.connect(_handle_select_new_race)
	race_select_button.process_mode = PROCESS_MODE_ALWAYS
	
	main_mennu_button.pressed.connect(_handle_quit_to_main_button)
	main_mennu_button.process_mode = PROCESS_MODE_ALWAYS

# Restart race instance
func _handle_restart() -> void:
	get_tree().paused = false
	SceneManager.change_scene_to_packed(current_scene_packed)

# Quit to select track menu
func _handle_select_new_race() -> void:
	get_tree().paused = false

	# Generate Packed instance to restart to
	var packed_scene = PackedScene.new()
	# Instance scene ready to edit
	var main_menu_instance = preload("res://menus/main_menu/MainMenu.tscn").instantiate(1)
	# Pack scene with game data
	main_menu_instance.direct_open_state = main_menu_instance.OpenTo.STORY
	packed_scene.pack(main_menu_instance)
	
	SceneManager.change_scene_to_packed(packed_scene)

# Quit to main menu
func _handle_quit_to_main_button() -> void:
	get_tree().paused = false
	SceneManager.change_scene_to_file("res://menus/main_menu/MainMenu.tscn")
