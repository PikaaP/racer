extends Control

signal go_back()

@onready var back_button: HideBackButton = $BackButton

@export var back_button_endpoint: Node

func _ready() -> void:
	# Set up back button
	back_button.back_button_endpoint = back_button_endpoint
	back_button.node_to_hide = self
	back_button.back_pressed.connect(_notify_parent_backing)


# Emit signal to notify parent back button is pressed
func _notify_parent_backing() -> void:
	go_back.emit()
