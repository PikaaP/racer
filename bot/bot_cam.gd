extends Camera3D

@export var follow_this: Node3D
@export var target_distance = 5
@export var target_height = 20
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
