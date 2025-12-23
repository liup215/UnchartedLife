# map_manager.gd
# Manages the loading and unloading of map chunks based on player position.
extends Node

# The size of one map chunk in pixels.
const CHUNK_SIZE = Vector2(1280, 720) # Assuming 40x22.5 tiles @ 32px

# A dictionary to keep track of currently loaded chunks.
# Key: Vector2i(x, y) coordinates of the chunk
# Value: The Node instance of the loaded chunk scene
var loaded_chunks: Dictionary = {}

# Chunks that need to be restored from a save file
var chunks_to_restore: Array[Vector2i] = []

# A dictionary to map chunk coordinates to their scene paths.
# In a real game, this might be loaded from a file.
const CHUNK_SCENES = {
	Vector2i(0, 0): "res://features/map/chunks/map_0_0.tscn"
}

# The root node in the main scene where map chunks will be added.
var map_parent: Node = null


func _ready():
	# It's crucial that the map parent is set before any updates are called.
	# The main game manager will be responsible for this.
	# MapManager is saved as a global singleton, not via the saveable group
	pass

func set_map_parent(parent: Node):
	map_parent = parent
	
	# If we have chunks to restore from a save, load them now
	if not chunks_to_restore.is_empty():
		for coords in chunks_to_restore:
			_load_chunk(coords)
		chunks_to_restore.clear()

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
	if not CHUNK_SCENES.has(coords):
		# print("MapManager: No scene found for chunk coordinates: ", coords)
		return

	var scene_path = CHUNK_SCENES[coords]
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
		"loaded_chunk_coords": loaded_chunk_coords
	}

func load_data(data: Dictionary) -> void:
	# Store the chunks that need to be restored
	if data.has("loaded_chunk_coords") and not data["loaded_chunk_coords"].is_empty():
		# Only clear if we have data to restore
		loaded_chunks.clear()
		chunks_to_restore.clear()
		
		for coord_dict in data["loaded_chunk_coords"]:
			var coords = Vector2i(coord_dict.get("x", 0), coord_dict.get("y", 0))
			if CHUNK_SCENES.has(coords):
				chunks_to_restore.append(coords)
		
		print("MapManager: Will restore %d chunks when map_parent is set" % chunks_to_restore.size())

# Reset MapManager state for a new game
func reset_for_new_game() -> void:
	loaded_chunks.clear()
	chunks_to_restore.clear()
	map_parent = null
	print("MapManager: Reset for new game")
