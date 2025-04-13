class_name PlayerCamera extends Camera3D

# HUD
@onready var leader_board = $Hud/UI/LeaderBoard

@export var follow_target: Node

@export var target_distance = 3.25
@export var target_height = 2.0
@export var move_transform_speed: float = 8.5

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
	global_position = follow_target.get_node('CameraShowCase').get_child(0).global_position
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
		# DRIVE state
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


# Handle race start animation
func play_start_animation() -> void:
	current = true
	$motion_blur.get_surface_override_material(0).set_shader_parameter('start_radius', 0)
	var tween_bar = get_tree().create_tween()
	tween_bar.set_parallel()
	tween_bar.tween_property($Effects/ColorRectTop, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.tween_property($Effects/ColorRectBot, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.chain()
	await get_tree().create_timer(1.0).timeout

	var tween = get_tree().create_tween()
	for marker: Marker3D in follow_target.camera_points.get_children():
		tween.tween_property(self, 'global_transform', marker.global_transform, 2.0).set_trans(Tween.TRANS_SINE)

	await tween.finished
	$motion_blur.get_surface_override_material(0).set_shader_parameter('start_radius', 0.01)
	var tween_bar_out = get_tree().create_tween()
	tween_bar_out.set_parallel()
	tween_bar_out.tween_property($Effects/ColorRectTop, 'custom_minimum_size', Vector2(0, 0), 1 )
	tween_bar_out.tween_property($Effects/ColorRectBot, 'custom_minimum_size', Vector2(0, 0), 1 )
	tween_bar_out.chain()
	await get_tree().create_timer(1.0).timeout
	
	follow_target.race_ready.emit()
	leader_board.show()

# Reposition camer to set position
func move_to_position(new_position: Vector3) -> void:
	global_position = new_position
	can_follow = false


func update_lap_count_ui(new_current_lap: int) -> void:
	pass

func update_leader_board(sorted_leader_board: Array) -> void:
	for child in leader_board.get_children():
			child.queue_free()
	for card_info in sorted_leader_board:
		var lable = Label.new()
		lable.text = '%s, lap: %s, checkpoint: %s' % [card_info[0].name, card_info[1], card_info[2]]
		leader_board.add_child(lable)
