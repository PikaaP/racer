class_name OldDriftMesh extends MeshInstance3D

@onready var fade_timer: Timer = $Timer

@export var points: Array
@export var fade_out_duration: float = 10
@export var new_global_transform: Transform3D

func _ready() -> void:
	set_as_top_level(true)
	transform = Transform3D.IDENTITY
	build_old_mesh()
	fade_timer.wait_time = fade_out_duration
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	fade_timer.start()

func _process(delta: float) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color.a = fade_timer.time_left/fade_out_duration
	set_surface_override_material(0, mat)

func build_old_mesh() -> void:
	mesh = ArrayMesh.new()
	# Initialize the ArrayMesh.
	var arrays = []
	var packed_vertices = PackedVector3Array()
	for point in points:
		packed_vertices.push_back(point.bot_left_vertex)
		packed_vertices.push_back(point.bot_right_vertex)
		packed_vertices.push_back(point.top_left_vertex)
		packed_vertices.push_back(point.top_right_vertex)

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = packed_vertices

	# Add vertices to mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)

func _on_fade_timer_timeout() -> void:
	queue_free()
