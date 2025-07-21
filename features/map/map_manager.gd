# map_manager.gd
# Manages the loading and unloading of map chunks based on player position.
extends Node

# The size of one map chunk in pixels.
const CHUNK_SIZE = Vector2(1280, 720) # Assuming 40x22.5 tiles @ 32px

# A dictionary to keep track of currently loaded chunks.
# Key: Vector2i(x, y) coordinates of the chunk
# Value: The Node instance of the loaded chunk scene
var loaded_chunks: Dictionary = {}

# A dictionary to map chunk coordinates to their scene paths.
# In a real game, this might be loaded from a file.
const CHUNK_SCENES = {
    Vector2i(0, 0): "res://features/map/map_0_0.tscn"
}

# The root node in the main scene where map chunks will be added.
var map_parent: Node = null


func _ready():
    # It's crucial that the map parent is set before any updates are called.
    # The main game manager will be responsible for this.
    pass

func set_map_parent(parent: Node):
    map_parent = parent

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
        print("MapManager: No scene found for chunk coordinates: ", coords)
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
