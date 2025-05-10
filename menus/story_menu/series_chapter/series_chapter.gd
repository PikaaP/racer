class_name SeriesChapter extends PanelContainer

@onready var name_lable =   $VBoxContainer/NameLabel
@onready var best_time_lable =  $VBoxContainer/BestTimeLabel
@onready var thumbnail_image =  $VBoxContainer/Thumbnail
@onready var medal_image =  $PanelContainer/Medal

@export var game_data: SeriesChapterData
@export var user_data: PlayerStoryData

func _ready() -> void:
	set_up_chapter_button()
	$Button.pressed.connect(_handle_on_press)

# Set up  button to lead to game instance
# If user data exists, Add best time details and medal image
func set_up_chapter_button() -> void:
	if game_data:
		name_lable.text = game_data.chapter_name
		thumbnail_image.texture = game_data.thumnail
		
		if user_data:
			print('has user data!')
			print(user_data , ' ud')
			best_time_lable.text = 'Best time: '+ format_lap_time(user_data.best_time)
			match user_data.medal_achieved:
				'':
					pass
				_:
					medal_image.texture = preload('res://icon.svg')
			
			medal_image.show()
		else:
			print('no user data in button')
			best_time_lable.text = 'Best time: '+ '--:--:---'

		$Button.disabled = false if user_data or !game_data.locked else true
	else:
		return

# Handle button pressed
# Create story instance with game data
func _handle_on_press() -> void:
	# Create packed Story scene
	var scene = PackedScene.new()
	# Instance scene ready to edit
	var story_instance = preload("res://scenes/game_instances/story_game_instance/StoryGame.tscn").instantiate(1)
	# Pack scene with game data
	story_instance.series_chapter_data = game_data
	story_instance.game_data = game_data.game_instance
	story_instance.player_car_path = game_data.car_path
	story_instance.grid_start_pos = game_data.start_pos_index
	
	scene.pack(story_instance)
	# Make new scene scene root
	get_tree().change_scene_to_packed(scene)

func format_lap_time(time: float) -> String:
	var finish_time_delta: float = time
	var msec: float = fmod(finish_time_delta, 1) * 1000
	var sec: float  = fmod(finish_time_delta, 60)
	var m: float = finish_time_delta /60
	
	var formatted_m_s_ms: String = '%02d:%02d:%02d' % [m, sec, msec]
	var actual_m_s_ms = '%s:%s:%s' % [str(m), str(sec), str(msec)]
	return formatted_m_s_ms
