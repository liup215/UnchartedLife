# game_scene_data.gd
# Resource class to define a complete game scene configuration
# Combines static map data with dynamic entity spawns
extends Resource
class_name GameSceneData

# Scene identifier
@export var scene_id: String = ""

# Display name
@export var scene_name: String = ""

# ============ STATIC DATA ============
# Reference to MapData for map/level loading
# MapData defines map configuration including:
# - map_id: Unique identifier for the map
# - chunk_scenes: Dictionary of Vector2i -> scene paths for chunk-based maps
# - default_spawn_position: Where player spawns when entering the map
# - use_chunk_loading: Whether to use chunk-based loading
@export var map_data: MapData = null

# ============ DYNAMIC DATA ============
# Player spawn configuration
@export var player_spawn: PlayerSpawnData = null

# Array of entities to spawn (NPCs, vehicles, enemies, interactive objects)
@export var spawnable_entities: Array[SpawnableEntityData] = []

# ============ METADATA ============
# Optional background music
@export var background_music: AudioStream = null

# Optional ambient sound
@export var ambient_sound: AudioStream = null

# Optional scene-specific settings
@export var scene_settings: Dictionary = {}

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	var entities_array: Array = []
	for entity in spawnable_entities:
		if entity:
			entities_array.append(entity.to_dict())
	
	return {
		"scene_id": scene_id,
		"scene_name": scene_name,
		"map_data": map_data.resource_path if map_data else "",
		"player_spawn": player_spawn.to_dict() if player_spawn else {},
		"spawnable_entities": entities_array,
		"background_music": background_music.resource_path if background_music else "",
		"ambient_sound": ambient_sound.resource_path if ambient_sound else "",
		"scene_settings": scene_settings
	}

# Load from dictionary
func from_dict(data: Dictionary) -> void:
	scene_id = data.get("scene_id", scene_id)
	scene_name = data.get("scene_name", scene_name)
	scene_settings = data.get("scene_settings", scene_settings)
	
	# Load map data
	if data.has("map_data") and not data["map_data"].is_empty():
		map_data = load(data["map_data"])
	
	# Load player spawn
	if data.has("player_spawn") and not data["player_spawn"].is_empty():
		player_spawn = PlayerSpawnData.new()
		player_spawn.from_dict(data["player_spawn"])
	
	# Load spawnable entities
	if data.has("spawnable_entities"):
		spawnable_entities.clear()
		for entity_dict in data["spawnable_entities"]:
			var entity = SpawnableEntityData.new()
			entity.from_dict(entity_dict)
			spawnable_entities.append(entity)
	
	# Load audio resources
	if data.has("background_music") and not data["background_music"].is_empty():
		background_music = load(data["background_music"])
	
	if data.has("ambient_sound") and not data["ambient_sound"].is_empty():
		ambient_sound = load(data["ambient_sound"])
