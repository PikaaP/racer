extends PanelContainer

@export var player_name: String
@export var selected_car: String

@onready var player_label = $VBoxContainer/PlayerLabel

var car_pointer: int = 0

var car_list = [
	"res://player/test/test_physics/custom_lambo/custom_racer.tscn",
]

func _ready() -> void:
	player_label.text = player_name
	selected_car = car_list[0]
	player_label.text_submitted.connect(_on_player_name_submittied)

func _on_find_right_pressed() -> void:
	car_pointer += 1
	if car_pointer >= car_list.size():
		car_pointer = 0
	
	selected_car = car_list[car_pointer]


func _on_find_left_pressed() -> void:
	car_pointer -= 1
	if car_pointer < 0:
		car_pointer =  car_list.size() -1

	selected_car = car_list[car_pointer]

# Store and update name ui variable if player selects a name
func _on_player_name_submittied(new_text: String) -> void:
	player_name = new_text
	player_label.text = new_text
