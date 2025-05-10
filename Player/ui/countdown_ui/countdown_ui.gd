class_name CountDown extends Control

@onready var count_down_timer: Timer = $StartTimer
@onready var main_count: Label = $HBoxContainer/MainCount
@onready var sub_count: Label = $HBoxContainer/SubCount


var start_timer: bool = false

func _ready() -> void:
	pass

func start_countdown() -> void:
	print('is here rn')
	visible = true
	start_timer = true
	count_down_timer.start()
	count_down_timer.timeout.connect(_on_start_timer_timeout)

func _process(delta: float) -> void:
	if start_timer:
		main_count.text = str(int(count_down_timer.time_left))
		sub_count.text = str(int((snapped(count_down_timer.time_left, 0.001) - int(count_down_timer.time_left)) * 1000))

func _on_start_timer_timeout() -> void:
	start_timer = false
	main_count.hide()
	sub_count.hide()
	$HBoxContainer/Dot.text = 'GO!'
	await get_tree().create_timer(0.75).timeout
	hide()
