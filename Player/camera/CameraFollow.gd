extends Camera3D

@onready var speed_kph = $Hud/speed

@export var follow_this: VehicleBody3D
@export var target_distance = 5
@export var target_height = 2
@export var speed:= 6.0

var last_lookat

func _ready():
	last_lookat = follow_this.global_transform.origin
	position = follow_this.global_position - Vector3(0, 2, -4)

func _physics_process(delta):
	var delta_v = global_transform.origin - follow_this.global_transform.origin
	var target_pos = global_position
	
	# ignore y
	delta_v.y = 0.0
	
	if delta_v.length() > target_distance:
		delta_v = delta_v.normalized() * target_distance
		delta_v.y = target_height
		target_pos = follow_this.global_transform.origin + delta_v

	else:
		target_pos.y = follow_this.global_transform.origin.y + target_height

	global_transform.origin = global_transform.origin.lerp(target_pos, delta * speed)

	last_lookat = last_lookat.lerp(follow_this.global_transform.origin, delta * speed)

	look_at(last_lookat, Vector3.UP)

func _process(delta: float) -> void:
	speed_kph.text=str(round(follow_this.speed*3.8))+"  KMPH"
