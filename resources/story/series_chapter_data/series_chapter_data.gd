class_name SeriesChapterData extends Resource

enum {NA, BRONZE, SILVER, GOLD}

@export var locked = true
@export var chapter_name: String
@export var thumnail: Texture
@export var best_time: float
@export_enum('N/A', 'Bronze', 'Silver', 'Gold') var medal_achived: int = NA

@export var track_scene_path: String
@export var success_condition: String
@export var car_path: String
@export_range(1, 7, 1.0) var start_pos_index = 7

@export var unlock_series_id: int
@export var unlock_chapter_id: int

@export var completed: bool = false

@export var series_id: int
@export var chapter_id: int

@export var game_instance: GameInstance

func _handle_unluck_reward(result) -> bool:
	if result is bool:
		if result:
			return true
		else:
			return false
	
	else:
		match success_condition:
			'win':
				if result == 1:
					return true
			'3':
				if result <= 2:
					return true
			'finish':
				return true
		return false

func generate_unlock_path() -> String:
	return 'user://data/story/series_{series_id}/chapter_{chapter_id}.tres'.format({'series_id':unlock_series_id, 'chapter_id':unlock_chapter_id})
