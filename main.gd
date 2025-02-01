extends Node
@onready var main_menu: MainMenu = $MainMenu

func _ready() -> void:
	Input.joy_connection_changed.connect(main_menu._handle_joy_connection)
