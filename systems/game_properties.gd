extends Node

# Holds settings for new game creation and starts the game

var current_settings: WorldGeneratingSettings = null
var TutorialState: Dictionary = {}

func start_new_game(settings: WorldGeneratingSettings) -> void:
	current_settings = settings
	TutorialState = {"Enabled": true}

func to_dict() -> Dictionary:
	return {
		"current_settings": current_settings.to_dict() if current_settings else {},
		"TutorialState": TutorialState,
	}

func from_dict(data: Dictionary) -> void:
	if data.has("current_settings"):
		current_settings = WorldGeneratingSettings.new()
		current_settings.from_dict(data["current_settings"])
	if data.has("TutorialState"):
		TutorialState = data["TutorialState"]

# SaveManager-compatible methods
func save_data() -> Dictionary:
	return to_dict()

func load_data(data: Dictionary) -> void:
	from_dict(data)
