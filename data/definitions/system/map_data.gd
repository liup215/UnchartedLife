# map_data.gd
# Resource class to define a map/level configuration
extends Resource
class_name MapData

# Unique identifier for this map
@export var map_id: String = ""

# Display name for the map
@export var map_name: String = ""

# Description of the map
@export var map_description: String = ""

# The main scene file for this map (chunk container or full map scene)
@export var map_scene_path: String = ""

# Dictionary of chunk scenes for chunk-based maps
# Key: Vector2i(x, y) coordinates of the chunk
# Value: String path to the chunk scene
@export var chunk_scenes: Dictionary = {}

# Default spawn position for the player when entering this map
@export var default_spawn_position: Vector2 = Vector2.ZERO

# Whether this map uses chunk-based loading
@export var use_chunk_loading: bool = true

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	var chunk_dict = {}
	for key in chunk_scenes.keys():
		if key is Vector2i:
			chunk_dict[str(key)] = chunk_scenes[key]
	
	return {
		"map_id": map_id,
		"map_name": map_name,
		"map_description": map_description,
		"map_scene_path": map_scene_path,
		"chunk_scenes": chunk_dict,
		"default_spawn_position": {"x": default_spawn_position.x, "y": default_spawn_position.y},
		"use_chunk_loading": use_chunk_loading
	}

# Load from dictionary
func from_dict(data: Dictionary) -> void:
	map_id = data.get("map_id", map_id)
	map_name = data.get("map_name", map_name)
	map_description = data.get("map_description", map_description)
	map_scene_path = data.get("map_scene_path", map_scene_path)
	use_chunk_loading = data.get("use_chunk_loading", use_chunk_loading)
	
	# Convert chunk dictionary back to Vector2i keys
	if data.has("chunk_scenes"):
		chunk_scenes.clear()
		var chunk_dict = data["chunk_scenes"]
		for key_str in chunk_dict.keys():
			# Parse "Vector2i(x, y)" or "(x, y)" format
			var coords_str = key_str.replace("Vector2i", "").replace("(", "").replace(")", "").strip_edges()
			var coords = coords_str.split(",")
			if coords.size() == 2:
				var x = int(coords[0].strip_edges())
				var y = int(coords[1].strip_edges())
				chunk_scenes[Vector2i(x, y)] = chunk_dict[key_str]
	
	# Load spawn position
	if data.has("default_spawn_position"):
		var pos_data = data["default_spawn_position"]
		default_spawn_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
