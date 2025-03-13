class_name PlayerCamera extends Camera3D

@onready var speed_kph = $Hud/speed

@export var follow_target: CustomCar
@export var target_distance = 3.25
@export var target_height = 2.0
@export var move_transform_speed: float = 8.5
@export var look_follow_speed:= 16

var last_lookat: Vector3
var can_follow: bool = true
var rng = RandomNumberGenerator

func _ready():
	global_position= follow_target.get_node('CameraShowCase').get_child(0).global_position
	last_lookat = follow_target.global_position

func _physics_process(delta: float) -> void:
	if can_follow:
		# Calculate target location
		var target_location: Vector3 = follow_target.global_transform.origin + follow_target.transform.basis.y * target_height +  follow_target.transform.basis.z * target_distance

		# Move to target location if car drifts away
		if global_transform.origin.distance_to(target_location) >= 0.1:
			global_transform.origin = global_transform.origin.lerp(target_location, move_transform_speed * delta)
		# When close to car, lerp to target position
		else:
			global_transform.origin = global_transform.origin.lerp(target_location, delta)

		# Get look at target_at target
		var look_at_target: Vector3 = follow_target.global_position
		
		# Look_at the lagged last look_at target
		look_at_target = last_lookat.lerp(follow_target.global_position, look_follow_speed * delta)
		look_at(look_at_target)
		last_lookat = look_at_target
		
		if follow_target.normalized_speed > 0.75:
			var rand_y = randf_range(-0.008, 0.008)
			var rand_x = randf_range(-0.008, 0.008)
			global_position += Vector3(rand_x, rand_y, 0)


func _process(delta: float) -> void:
	speed_kph.text=str(round(follow_target.speed*3.8))+"  KMPH"

# Handle race start animation
func play_start_animation() -> void:
	$motion_blur.get_surface_override_material(0).set_shader_parameter('start_radius', 0)
	var tween_bar = get_tree().create_tween()
	tween_bar.set_parallel()
	tween_bar.tween_property($Hud/ColorRectTop, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.tween_property($Hud/ColorRectBot, 'custom_minimum_size', Vector2(0, 100), 1 )
	tween_bar.chain()
	await get_tree().create_timer(1.0).timeout

	var tween = get_tree().create_tween()
	for marker: Marker3D in follow_target.camera_points.get_children():
		tween.tween_property(self, 'global_transform', marker.global_transform, 2.0).set_trans(Tween.TRANS_SINE)

	await tween.finished
	$motion_blur.get_surface_override_material(0).set_shader_parameter('start_radius', 0.01)
	var tween_bar_out = get_tree().create_tween()
	tween_bar_out.set_parallel()
	tween_bar_out.tween_property($Hud/ColorRectTop, 'custom_minimum_size', Vector2(0, 0), 1 )
	tween_bar_out.tween_property($Hud/ColorRectBot, 'custom_minimum_size', Vector2(0, 0), 1 )
	tween_bar_out.chain()
	
	await get_tree().create_timer(1.0).timeout
	
	follow_target.race_ready.emit()

# Reposition camer to player
func move_to_checkpoint(new_position: Vector3) -> void:
	global_position = new_position
	print(new_position, ' cam pos')
	can_follow = false
	print('moved')
