class_name StoryRaceOverMenu extends PanelContainer

@onready var restart_button: Button = $VBoxContainer/Restart
@onready var race_select_button: Button = $VBoxContainer/RaceSelect
@onready var main_mennu_button: Button = $VBoxContainer/MainMenu

func _ready() -> void:
	restart_button.pressed.connect(_handle_restart)
	restart_button.process_mode = PROCESS_MODE_ALWAYS

	race_select_button.pressed.connect(_handle_select_new_track)
	race_select_button.process_mode = PROCESS_MODE_ALWAYS
	
	main_mennu_button.pressed.connect(_handle_quit_button)
	main_mennu_button.process_mode = PROCESS_MODE_ALWAYS

# Restart race instance
func _handle_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# Quit to select track menu
func _handle_select_new_track() -> void:
	pass
	#get_tree().paused = false
	#get_tree().change_scene_to_file("res://menus/car_select_menu/CarSelectMenu.tscn")

# Quit to main menu
func _handle_quit_button() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/car_select_menu/CarSelectMenu.tscn")

# Unpause and return to race ;D
func _handle_back_button_pressed() -> void:
	get_parent().hide()
	get_tree().paused = false
