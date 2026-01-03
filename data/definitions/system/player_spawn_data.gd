# player_spawn_data.gd
# Resource class to define player spawn configuration
extends Resource
class_name PlayerSpawnData

# Spawn position for the player
@export var spawn_position: Vector2 = Vector2.ZERO

# Optional: Spawn ID for identification
@export var spawn_id: String = "default"

# Optional: Player data override (if different from global PlayerData)
@export var player_data: Resource = null

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"spawn_position": {"x": spawn_position.x, "y": spawn_position.y},
		"spawn_id": spawn_id,
		"player_data": player_data.resource_path if player_data else ""
	}

# Load from dictionary
func from_dict(data: Dictionary) -> void:
	spawn_id = data.get("spawn_id", spawn_id)
	
	# Load spawn position
	if data.has("spawn_position"):
		var pos_data = data["spawn_position"]
		spawn_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
	
	# Load player data resource
	if data.has("player_data") and not data["player_data"].is_empty():
		player_data = load(data["player_data"])
