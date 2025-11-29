extends Node

# Holds settings for new game creation and starts the game

var current_settings: WorldGeneratingSettings = null
var TutorialState: Dictionary = {}
var current_slot : String = ""
var player_data : PlayerData = null

static func StartNewGame(settings) -> GameProperties:
    var game = preload("res://systems/game_properties.gd").new()
    game.current_settings = settings
    game.TutorialState = {"Enabled": true}
    return game

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
