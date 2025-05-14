# SceneManager
extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_scene_in()

func fade_scene_in() -> void:
	animation_player.play_backwards("fade")

func change_scene_to_file(file_path) -> void:
	animation_player.play("fade")
	get_tree().change_scene_to_file(file_path)

func change_scene_to_packed(packed_scene: PackedScene) -> void:
	animation_player.play("fade")
	await animation_player.animation_finished
	get_tree().change_scene_to_packed(packed_scene)

func _handle_node_enter_tree(node) -> void:
	print(node)
	print(' fading in')
	#fade_scene_in()
