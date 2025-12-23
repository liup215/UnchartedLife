# player_data_global.gd
# This is an autoload singleton that holds the player's persistent data
# that should be accessible across all scenes.
extends Node

var player_name: String = "Player"
var actor_data: ActorData = ActorData.new()
var current_slot: String = ""


func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"actor_data": actor_data.to_dict() if actor_data else {},
		"current_slot": current_slot,
	}

func from_dict(data: Dictionary) -> void:

	if data.has("player_name"):
		player_name = data["player_name"]

	if data.has("actor_data"):
		if not actor_data:
			actor_data = ActorData.new()
		actor_data.from_dict(data["actor_data"])
	
	if data.has("current_slot"):
		current_slot = data["current_slot"]

# SaveManager-compatible methods
func save_data() -> Dictionary:
	return to_dict()

func load_data(data: Dictionary) -> void:
	from_dict(data)
