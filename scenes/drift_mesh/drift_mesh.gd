extends MeshInstance3D

@onready var past_drifts = $"../PastDrifts"

@export var wheel_raidus: float = 0.9
@export var target: CustomWheel
@export var meep: float = 2.0

const OLD_DRIFT_MESH = preload('res://scenes/drift_mesh/old_drift_mesh/OldDriftMesh.tscn')

class Point:
	var bot_left_vertex: Vector3
	var bot_right_vertex: Vector3
	var top_left_vertex: Vector3
	var top_right_vertex: Vector3
	
	
	func _init(_bot_left_vertex: Vector3, _bot_right_vertex: Vector3, _top_left_vertex: Vector3, _top_right_vertex: Vector3 ) -> void:
		bot_left_vertex = _bot_left_vertex
		bot_right_vertex = _bot_right_vertex
		top_left_vertex = _top_left_vertex
		top_right_vertex = _top_right_vertex
	
var points: Array = []

func _ready() -> void:
	set_as_top_level(true)
	mesh = ImmediateMesh.new()


func _process(delta: float) -> void:
	# Build mesh if driting
	if target.is_drifting:
		build_drift_mesh()
	# When drift has ended, commit last drift mesh to past_drifts node
	elif !points.is_empty():
		build_previous_mesh(points)
		print('here')
		points.clear()

# Build and update a mesh at runtime, save mesh once drift is over
func build_drift_mesh() -> void:
	var bot_left: Vector3
	var bot_right: Vector3
	var top_left: Vector3 = Vector3(target.global_transform.origin.x, target.global_transform.origin.y - wheel_raidus + 0.4, target.global_transform.origin.z) + -target.global_transform.basis.x * 0.2 
	var top_right: Vector3 = Vector3(target.global_transform.origin.x, target.global_transform.origin.y - wheel_raidus + 0.4, target.global_transform.origin.z) + target.global_transform.basis.x * 0.2 
	var new_point: Point

	# If starting a new mesh, save old mesh if it exists
	if points.is_empty() or target.start_drift:
		if !points.is_empty():
			build_previous_mesh(points)
	
		# Build points
		points.clear()
		bot_left = Vector3(target.global_transform.origin.x, target.global_transform.origin.y - wheel_raidus + 0.4, target.global_transform.origin.z) + -target.global_transform.basis.x * 0.2
		bot_right = Vector3(target.global_transform.origin.x, target.global_transform.origin.y - wheel_raidus + 0.4, target.global_transform.origin.z) + target.global_transform.basis.x * 0.2

		# Store new mesh strip as Point in points 
		new_point = Point.new(bot_left, bot_right, top_left, top_right)
		points.push_back(new_point)
		target.start_drift = false
	# If building on existing mesh, connect bottom coordinates to previous top coordinates
	else:
		top_left = Vector3(target.global_transform.origin.x, target.global_transform.origin.y - wheel_raidus + 0.4, target.global_transform.origin.z) + -target.global_transform.basis.x * 0.2 
		top_right = Vector3(target.global_transform.origin.x, target.global_transform.origin.y -wheel_raidus + 0.4, target.global_transform.origin.z) + target.global_transform.basis.x * 0.2 
		var last_rect: Point = points[-1]
		new_point = Point.new(last_rect.top_left_vertex, last_rect.top_right_vertex, top_right, top_left)
		points.push_back(new_point)
	
	# Update mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for index: int in points.size():
		# Create rectanlge from vertices ( triangles) :D
		mesh.surface_set_normal(Vector3(0, -1, 0))
		mesh.surface_set_uv(Vector2(0, 1))
		mesh.surface_add_vertex(points[index].bot_left_vertex)

		mesh.surface_set_normal(Vector3(0, -1, 0))
		mesh.surface_set_uv(Vector2(1, 1))
		mesh.surface_add_vertex(points[index].bot_right_vertex)

		mesh.surface_set_normal(Vector3(0, -1, 0))
		mesh.surface_set_uv(Vector2(0, 0))
		mesh.surface_add_vertex(points[index].top_left_vertex)
		
		mesh.surface_set_normal(Vector3(0, -1, 0))
		mesh.surface_set_uv(Vector2(1, 0))
		mesh.surface_add_vertex(points[index].top_right_vertex)

	# End drawing.
	mesh.surface_end()

# Build past drift mesh
func build_previous_mesh(_points) -> void:
	var saved_mesh: OldDriftMesh = OLD_DRIFT_MESH.instantiate()
	saved_mesh.points = _points
	saved_mesh.transform = transform
	past_drifts.add_child(saved_mesh)
