@tool
class_name CheckPoint extends Area3D

@onready var label = $Label3D

@export var checkpoint_index: int
@export var checkpoint_target: int
@export var is_start_finish: bool = false

func  _ready() -> void:
	label.text = 'Check Point %s , \n Target: %s ' % [str(checkpoint_index), str(checkpoint_target)]

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerCar or body is Bot:
		if body.target_checkpoint == checkpoint_index:
			if is_start_finish:
				body.add_checkpoint(0, checkpoint_target, true)
			else:
				body.add_checkpoint(checkpoint_index, checkpoint_target)
