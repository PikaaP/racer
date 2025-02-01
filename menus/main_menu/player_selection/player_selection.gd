extends PanelContainer

@export var player_name: String
@export var selected_car: String

@onready var player_label = $PlayerLabel

var car_pointer: int = 0

var car_list = [
	'res://cars/lambo/Lambo_v1.tscn',
	'res://cars/dodge/Doge.tscn'
]

func _ready() -> void:
	player_label.text = player_name
	selected_car = car_list[0]


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
