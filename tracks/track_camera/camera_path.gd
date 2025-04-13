class_name CameraPath extends Path3D

signal track_showcase_over()

@export var index: int

@onready var path_follow: PathFollow3D = $PathFollow3D
@onready var camera: Camera3D = $PathFollow3D/TrackCamera

func _ready() -> void:
	var current_track: Track = get_tree().get_first_node_in_group("track")
	track_showcase_over.connect(current_track._handle_track_showcase_over)

func follow_path() -> void:
	camera.current = true
	var tween = create_tween()
	tween.tween_property(path_follow, 'progress_ratio', 1, 1)
	tween.finished.connect(_hanlde_tween_finished)
	print('follow')
	
func _hanlde_tween_finished() -> void:
	print('done follw')
	var paths: Array = get_tree().get_nodes_in_group("track_path")
	var next_index = index + 1
	if next_index >= paths.size():
		track_showcase_over.emit()
	else:
		for path in paths:
			if path.index == next_index:
				path.follow_path()
