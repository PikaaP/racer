class_name MainMenu extends Node

@onready var story_button: Button = $MenuOverlay/RootMenu/VBoxContainer/Play
@onready var coop_button: Button = $MenuOverlay/RootMenu/VBoxContainer/Coop
@onready var contorls_button: Button = $MenuOverlay/RootMenu/VBoxContainer/Controls

@onready var background_camera: Camera3D = $Background/SubViewportContainer/SubViewport/Camera3D
@onready var exit_game_button: Button = $MenuOverlay/RootMenu/Exit

enum OpenTo {MAIN, STORY}
@export var direct_open_state: OpenTo


func _ready() -> void:
	# Connect Exit button pressed
	exit_game_button.pressed.connect(_handle_exit_request)
	# Connect Story button pressed
	story_button.pressed.connect(_handle_start_story)
	# Connect Coop button pressed
	coop_button.pressed.connect(_handle_start_coop)
	# Connect Controls button pressed
	contorls_button.pressed.connect(_handle_open_controls)
	# Connect back buttons pressed to reset animation functions
	$MenuOverlay/StoryMenu.go_back.connect(transition_reset)
	$MenuOverlay/CarSelectMenu.go_back.connect(transition_reset)
	$MenuOverlay/ControlsMenu.go_back.connect(transition_reset)

	# Play backdrop animations
	$Background/AnimationPlayer.play("light")
	
	match direct_open_state:
		OpenTo.MAIN:
			pass
		OpenTo.STORY:
			_handle_start_story()

# Menu Controls //
func _handle_start_coop() -> void:
	$CameraAnimations.play("open_coop_menu")
	$MenuOverlay/RootMenu.hide()
	$MenuOverlay/CarSelectMenu.show()

func _handle_start_story() -> void:
	$CameraAnimations.play("open_story_menu")
	$MenuOverlay/RootMenu.hide()
	$MenuOverlay/StoryMenu.show()

func _handle_open_controls() -> void:
	$CameraAnimations.play("open_controls_menu")
	$MenuOverlay/RootMenu.hide()
	$MenuOverlay/ControlsMenu.show()

func _handle_exit_request() -> void:
	get_tree().quit()

func transition_to_story() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(background_camera, 'transform', $Background/CameraPoints/Story.transform, 0.5)

func transition_to_coop() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(background_camera, 'transform', $Background/CameraPoints/Coop.transform, 0.5)

func transition_to_controls() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(background_camera, 'transform', $Background/CameraPoints/Controls.transform, 0.5)

func transition_reset() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(background_camera, 'transform', $Background/CameraPoints/Start.transform, 0.5)
	$CameraAnimations.play("RESET")

# // Menu Controls
