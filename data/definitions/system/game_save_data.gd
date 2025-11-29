extends Resource
class_name GameSaveData

var version: String = ProjectSettings.get_setting("application/config/version", "1.0")

var timestamp: int = 0

# Hold objects directly
var player_data: PlayerData = null
var game_properties: GameProperties = null

# For per-node saveable data
var custom_data: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "version": version,
        "timestamp": timestamp,
        "player_data": player_data and player_data.to_dict() or {},
        "game_properties": game_properties and game_properties.to_dict() or {},
        "custom_data": custom_data,
    }

func from_dict(data: Dictionary) -> void:
    version = data.get("version", version)
    timestamp = data.get("timestamp", timestamp)
    if player_data:
        player_data.from_dict(data.get("player_data", {}))
    if game_properties:
        game_properties.from_dict(data.get("game_properties", {}))
    custom_data = data.get("custom_data", custom_data)
