class_name StoryPauseMenu extends PanelContainer

@onready var restart_button: Button = $VBoxContainer/Restart

@onready var main_mennu_button: Button = $VBoxContainer/MainMenu
@onready var back_button: Button = $VBoxContainer/MarginContainer/Back

func _ready() -> void:
	restart_button.pressed.connect(_handle_restart)
	restart_button.process_mode = PROCESS_MODE_ALWAYS
	
	main_mennu_button.pressed.connect(_handle_quit_button)
	main_mennu_button.process_mode = PROCESS_MODE_ALWAYS
	
	back_button.pressed.connect(_handle_back_button_pressed)
	back_button.process_mode = PROCESS_MODE_ALWAYS
	back_button.grab_focus()


# Restart race instance
func _handle_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# Quit to main menu
func _handle_quit_button() -> void:
	get_tree().paused = false
	SceneManager.change_scene_to_file("res://menus/car_select_menu/CarSelectMenu.tscn")

# Unpause and return to race ;D
func _handle_back_button_pressed() -> void:
	get_parent().hide()
	get_tree().paused = false
