class_name PlayerViewport extends SubViewportContainer

@onready var countdown_ui: CountDown = $UI/CountdownUI
@onready var options_menu: RaceOptionsMenu = $UI/OptionsMenu


# Display race countdown ui
func start_race_countdown() -> void:
	countdown_ui.start_countdown()

# Toggle pause menu visibility
func toggle_race_options_menu() -> void:
	options_menu.visible = !options_menu.visible


# Show race over screen
func show_race_over_ui() -> void:
	options_menu.visible = true
