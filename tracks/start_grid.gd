@tool
extends Node3D

@export_tool_button('set grid') var set_grid = set_grid_slots
@export var path: Path3D

var grid_sep_space: int = 10
var center_offset: int = 3
var curve_length: float

func _ready() -> void:
	set_grid_slots()

func set_grid_slots():
	for child in get_children():
		child.queue_free()
	
	center_offset = 3
	grid_sep_space = 10
	curve_length = path.curve.get_baked_length()
	
	for i in get_parent().bot_count + 2:
		var point: Transform3D = path.curve.sample_baked_with_rotation(curve_length - grid_sep_space * i - grid_sep_space, false, true)
		if i % 2 == 0.0:
			point.origin = point.origin - point.basis.x * center_offset
		else:
			point.origin = point.origin + point.basis.x * center_offset
		
		point.origin = point.origin + point.basis.y * 2
		var marker = Marker3D.new()
		marker.global_transform = point
		var sprite = Sprite3D.new()
		sprite.texture = preload('res://icon.svg')
		marker.add_child(sprite)
		add_child(marker)
