# player_data_global.gd
# This is an autoload singleton that holds the player's persistent data
# that should be accessible across all scenes.
extends Node

var player_name: String = "Player"
var actor_data: ActorData = ActorData.new()


func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"actor_data": actor_data.to_dict() if actor_data else {},
	}

func from_dict(data: Dictionary) -> void:

	if data.has("player_name"):
		player_name = data["player_name"]

	if data.has("actor_data"):
		if not actor_data:
			actor_data = ActorData.new()
		actor_data.from_dict(data["actor_data"])
