extends  Camera3D

@export var follow_target: Node

@export var target_height: int = 5
@export var target_distance: int = 5
@export var move_transform_speed: int = 5


@export var target_drift_distance: float = 2.5
@export var target_drift_height: float = 1.5
@export var move_transform_drift_speed: float = 10.0

@export var max_look_follow_speed: float = 16.0
@export var look_follow_speed: float

@export var max_drift_follow_speed: float = 18.0
@export var drift_follow_speed: float

var last_lookat: Vector3
var can_follow: bool = true
var rng = RandomNumberGenerator

func _ready():
	follow_target = get_parent()
	look_follow_speed = max_look_follow_speed
	drift_follow_speed = max_drift_follow_speed

	last_lookat = follow_target.global_position


func _physics_process(delta: float) -> void:
	if can_follow:
		# Calculate target location
		var target_location: Vector3
		
		if follow_target.current_state != follow_target.State.DRIFT:
			target_location = follow_target.global_transform.origin + follow_target.transform.basis.y * target_height +  follow_target.transform.basis.z * target_distance
		else:
			target_location = follow_target.global_transform.origin + follow_target.transform.basis.y * target_drift_height +  follow_target.transform.basis.z * target_drift_distance

		# Move to target location if car drifts away
		if global_transform.origin.distance_to(target_location) >= 0.1:
			if follow_target.current_state != follow_target.State.DRIFT:
				global_transform.origin = global_transform.origin.lerp(target_location, move_transform_speed * delta)
			else:
				global_transform.origin = global_transform.origin.lerp(target_location, move_transform_drift_speed * delta)
				
		# When close to car, lerp to target position
		else:
			global_transform.origin = global_transform.origin.lerp(target_location, delta)

		# Get look at target_at target
		var look_at_target: Vector3 = follow_target.global_position
		
		# Look_at the lagged last look_at target
		# Follw speed determined by player state

		if follow_target.current_state != follow_target.State.DRIFT:
			if int(look_follow_speed) != max_look_follow_speed:
				look_follow_speed = lerp(look_follow_speed, max_look_follow_speed, delta)
		# DRIFT state
		else:
			if int(look_follow_speed) != max_drift_follow_speed:
				look_follow_speed = lerp(look_follow_speed, max_drift_follow_speed, delta)
		
		# Calculate new location to look at from last_look_at
		look_at_target = last_lookat.lerp(follow_target.global_position, look_follow_speed * delta)
		# Face camera to target
		look_at(look_at_target, follow_target.transform.basis.y)
		# Store previous frame orientation 
		last_lookat = look_at_target
		
		# Shake camera if player is moving quickly :D
		if follow_target.normalized_speed > 0.75:
			var rand_y = randf_range(-0.008, 0.008)
			var rand_x = randf_range(-0.008, 0.008)
			global_position += Vector3(rand_x, rand_y, 0)
