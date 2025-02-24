class_name PlayerCamera extends Camera3D

@onready var speed_kph = $Hud/speed

@export var follow_this: Node
@export var target_distance = 5
@export var target_height = 2
@export var speed:= 16

var last_lookat
var can_follow: bool = true
var delta_v: Vector3
var target_pos: Vector3
var rng = RandomNumberGenerator

func _ready():
	global_transform.origin = follow_this.global_transform.origin - Vector3(0, 2, -4)
	last_lookat = follow_this.global_transform.origin

func _physics_process(delta):
	if can_follow:
		delta_v = global_transform.origin - follow_this.global_transform.origin
		
		## ignore y
		delta_v.y = 0.0
		if delta_v.length() > target_distance:
			delta_v = delta_v.normalized() * target_distance
			delta_v.y = target_height
			target_pos = follow_this.global_transform.origin + delta_v
		else:
			target_pos.y = follow_this.global_transform.origin.y + target_height

#
		global_transform.origin = global_transform.origin.lerp(target_pos, delta * speed)
#
		last_lookat = last_lookat.lerp(follow_this.global_transform.origin, delta * speed * 1.5) 

		look_at(last_lookat, Vector3.UP)
		
		#if follow_this.speed > 15:
			#look_at(last_lookat + Vector3(randf_range(0.0, 0.01), randf_range(0.0, 0.01),randf_range(0.0, 0.01)), Vector3.UP)
		#else:
			#look_at(last_lookat, Vector3.UP)
		#
#
#func _process(delta: float) -> void:
	#speed_kph.text=str(round(follow_this.speed*3.8))+"  KMPH"

func move_to_checkpoint(new_position: Vector3) -> void:
	global_position = new_position
	print(new_position, ' cam pos')
	can_follow = false
	print('moved')
	
	
