class_name HideBackButton extends Button

signal back_pressed()

@export var node_to_hide: Node
@export var back_button_endpoint: Node

func _ready() -> void:
	pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	node_to_hide.hide()
	back_pressed.emit()
	back_button_endpoint.show()
