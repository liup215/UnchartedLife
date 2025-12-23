# map_manager.gd
# Manages the loading and unloading of map chunks based on player position.
# Supports multiple maps with map switching functionality.
extends Node

# The size of one map chunk in pixels.
const CHUNK_SIZE = Vector2(1280, 720) # Assuming 40x22.5 tiles @ 32px

# Dictionary of all available maps
# Key: map_id (String)
# Value: MapData resource
var available_maps: Dictionary = {}

# Current active map
var current_map_id: String = ""
var current_map_data: MapData = null

# A dictionary to keep track of currently loaded chunks.
# Key: Vector2i(x, y) coordinates of the chunk
# Value: The Node instance of the loaded chunk scene
var loaded_chunks: Dictionary = {}

# Chunks that need to be restored from a save file
var chunks_to_restore: Array[Vector2i] = []

# The root node in the main scene where map chunks will be added.
var map_parent: Node = null

# Default map ID for new games
const DEFAULT_MAP_ID: String = "main_world"


func _ready():
	# It's crucial that the map parent is set before any updates are called.
	# The main game manager will be responsible for this.
	# MapManager is saved as a global singleton, not via the saveable group
	_initialize_available_maps()

func set_map_parent(parent: Node):
	map_parent = parent
	
	# If we have chunks to restore from a save, load them now
	if not chunks_to_restore.is_empty():
		for coords in chunks_to_restore:
			_load_chunk(coords)
		chunks_to_restore.clear()

# Initialize available maps from resource files
func _initialize_available_maps():
	# Create default main world map
	var main_map = MapData.new()
	main_map.map_id = "main_world"
	main_map.map_name = "Main World"
	main_map.map_description = "The main game world"
	main_map.use_chunk_loading = true
	main_map.chunk_scenes = {
		Vector2i(0, 0): "res://features/map/chunks/map_0_0.tscn"
	}
	main_map.default_spawn_position = Vector2(631, 356)
	available_maps["main_world"] = main_map
	
	# Set default map if none is set
	if current_map_id.is_empty():
		current_map_id = DEFAULT_MAP_ID
		current_map_data = available_maps.get(current_map_id)

# Register a new map
func register_map(map_data: MapData) -> void:
	if map_data and not map_data.map_id.is_empty():
		available_maps[map_data.map_id] = map_data
		print("MapManager: Registered map '%s'" % map_data.map_id)
	else:
		push_error("MapManager: Cannot register map with empty map_id")

# Get map data by ID
func get_map_data(map_id: String) -> MapData:
	return available_maps.get(map_id)

# Switch to a different map
func switch_to_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> bool:
	if not available_maps.has(map_id):
		push_error("MapManager: Map '%s' not found" % map_id)
		return false
	
	# Unload current map chunks
	_unload_all_chunks()
	
	# Update current map
	current_map_id = map_id
	current_map_data = available_maps[map_id]
	
	# Use provided spawn position or default
	var target_spawn = spawn_position if spawn_position != Vector2.ZERO else current_map_data.default_spawn_position
	
	print("MapManager: Switched to map '%s' at position %s" % [map_id, target_spawn])
	
	# Load initial chunks if using chunk loading
	if current_map_data.use_chunk_loading and map_parent:
		update_chunks(target_spawn)
	
	# Emit signal for other systems to react (e.g., spawn vehicles, update UI)
	EventBus.map_changed.emit(map_id, target_spawn)
	
	return true

# Unload all currently loaded chunks
func _unload_all_chunks():
	for coords in loaded_chunks.keys():
		var chunk_instance = loaded_chunks[coords]
		if is_instance_valid(chunk_instance):
			chunk_instance.queue_free()
	loaded_chunks.clear()
	print("MapManager: Unloaded all chunks")

func update_chunks(player_position: Vector2):
	if not map_parent:
		printerr("MapManager: map_parent not set! Cannot update chunks.")
		return

	var player_chunk_coords = _get_chunk_coords_from_position(player_position)
	
	# For now, we only load the chunk the player is in.
	# If it's not loaded, load it.
	if not loaded_chunks.has(player_chunk_coords):
		_load_chunk(player_chunk_coords)

func _get_chunk_coords_from_position(position: Vector2) -> Vector2i:
	var x = floor(position.x / CHUNK_SIZE.x)
	var y = floor(position.y / CHUNK_SIZE.y)
	return Vector2i(x, y)

func _load_chunk(coords: Vector2i):
	if not current_map_data:
		push_error("MapManager: No current map data")
		return
	
	if not current_map_data.chunk_scenes.has(coords):
		# print("MapManager: No scene found for chunk coordinates: ", coords)
		return

	var scene_path = current_map_data.chunk_scenes[coords]
	var chunk_scene = load(scene_path)
	if chunk_scene:
		var chunk_instance = chunk_scene.instantiate()
		# Position the chunk correctly in the world
		chunk_instance.position = Vector2(coords.x * CHUNK_SIZE.x, coords.y * CHUNK_SIZE.y)
		
		loaded_chunks[coords] = chunk_instance
		map_parent.add_child(chunk_instance)
		print("Loaded chunk: ", coords)

func _unload_chunk(coords: Vector2i):
	if loaded_chunks.has(coords):
		var chunk_instance = loaded_chunks[coords]
		chunk_instance.queue_free()
		loaded_chunks.erase(coords)
		print("Unloaded chunk: ", coords)

# Save/Load support for SaveManager
func save_data() -> Dictionary:
	# Save the coordinates of currently loaded chunks
	var loaded_chunk_coords = []
	for coords in loaded_chunks.keys():
		loaded_chunk_coords.append({"x": coords.x, "y": coords.y})
	
	return {
		"current_map_id": current_map_id,
		"loaded_chunk_coords": loaded_chunk_coords
	}

func load_data(data: Dictionary) -> void:
	# Load the current map ID
	if data.has("current_map_id"):
		current_map_id = data["current_map_id"]
		current_map_data = available_maps.get(current_map_id)
		if not current_map_data:
			push_warning("MapManager: Loaded map_id '%s' not found in available_maps. Falling back to default map '%s'. Ensure custom maps are registered in _initialize_available_maps()." % [current_map_id, DEFAULT_MAP_ID])
			current_map_id = DEFAULT_MAP_ID
			current_map_data = available_maps.get(DEFAULT_MAP_ID)
	
	# Store the chunks that need to be restored
	if data.has("loaded_chunk_coords") and not data["loaded_chunk_coords"].is_empty():
		# Only clear if we have data to restore
		loaded_chunks.clear()
		chunks_to_restore.clear()
		
		for coord_dict in data["loaded_chunk_coords"]:
			var coords = Vector2i(coord_dict.get("x", 0), coord_dict.get("y", 0))
			# Check against current map's chunks
			if current_map_data and current_map_data.chunk_scenes.has(coords):
				chunks_to_restore.append(coords)
		
		print("MapManager: Will restore %d chunks when map_parent is set" % chunks_to_restore.size())

# Reset MapManager state for a new game
func reset_for_new_game() -> void:
	loaded_chunks.clear()
	chunks_to_restore.clear()
	map_parent = null
	current_map_id = DEFAULT_MAP_ID
	current_map_data = available_maps.get(DEFAULT_MAP_ID)
	print("MapManager: Reset for new game")
