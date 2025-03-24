extends PanelContainer

@onready var restart_button: Button = $VBoxContainer/Restart
@onready var change_car_button: Button = $VBoxContainer/TrackCarSelect
@onready var main_mennu_button: Button = $VBoxContainer/MainMenu

func _ready() -> void:
	restart_button.pressed.connect(_handle_restart)
	change_car_button.pressed.connect(_handle_select_new_track_car)
	main_mennu_button.pressed.connect(_handle_quit_button)

func _handle_restart() -> void:
	get_tree().reload_current_scene()

func _handle_select_new_track_car() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu/main_menu.tscn")

func _handle_quit_button() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu/main_menu.tscn")
