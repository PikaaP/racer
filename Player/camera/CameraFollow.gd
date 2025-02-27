class_name PlayerCamera extends Camera3D

@onready var speed_kph = $Hud/speed

@export var follow_target: Node
@export var target_distance = 4
@export var target_height = 2
@export var speed:= 16

var last_lookat: Vector3
var can_follow: bool = true
var delta_v: Vector3
var target_pos: Vector3
var rng = RandomNumberGenerator

func _ready():
	#global_position = follow_target.start_position.global_position + Vector3(0, target_height, target_distance)
	print(follow_target.global_position)
	last_lookat = follow_target.global_position
	
func _physics_process(delta):
	if can_follow:
		#var target_location = Vector3(follow_target.global_position.x, follow_target.transform.basis.y + Vector3.UP * target_height, follow_target.transform.basis.z + Vector3.BACK * target_distance)
		#var target_location = Vector3(follow_target.global_position.x)
		#if global_position.distance_to(target_location) >= 2:
			#print('follow')
			#global_position = global_position.lerp(target_location, 2 *  delta)
		#else:
			#print('its ok')
			##global_position = target_location
		
		#global_position = follow_target.global_position + Vector3(follow_target.global_transform.basis.x.x, (follow_target.global_transform.basis.y + Vector3.UP * target_height).y, (follow_target.global_transform.basis.z + Vector3.BACK * target_distance).z)
		
		var look_at_target: Vector3 = follow_target.global_position
		
		look_at_target = last_lookat.lerp(follow_target.global_position, speed* delta)
		look_at(look_at_target)
		last_lookat = look_at_target
		

#
#func _process(delta: float) -> void:
	#speed_kph.text=str(round(follow_this.speed*3.8))+"  KMPH"

func move_to_checkpoint(new_position: Vector3) -> void:
	global_position = new_position
	print(new_position, ' cam pos')
	can_follow = false
	print('moved')
	
	
