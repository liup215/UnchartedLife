# game_scene.gd
# Generic game scene controller that loads from GameSceneData
# Implements the data-driven "Soul-Container-Brain" pattern
extends Node2D

# The data that defines this game scene
@export var game_scene_data: GameSceneData = null

# References to instantiated nodes
var map_container: Node2D = null
var player_instance: Node2D = null
var spawned_entities: Dictionary = {}  # spawn_id -> entity instance

func _ready() -> void:
	# If no data provided, try to get from external source or use default
	if not game_scene_data:
		push_warning("GameScene: No game_scene_data provided, cannot initialize scene")
		return
	
	# Setup scene based on data
	_setup_scene()

func _setup_scene() -> void:
	"""Setup the game scene from data"""
	print("GameScene: Setting up scene '%s'" % game_scene_data.scene_name)
	
	# 1. Setup map container for chunk loading
	_setup_map_container()
	
	# 2. Load static map data
	_load_map()
	
	# 3. Spawn player
	_spawn_player()
	
	# 4. Spawn dynamic entities
	_spawn_entities()
	
	# 5. Setup audio
	_setup_audio()
	
	print("GameScene: Scene setup complete")

func _setup_map_container() -> void:
	"""Create container for map chunks"""
	map_container = Node2D.new()
	map_container.name = "MapContainer"
	add_child(map_container)
	move_child(map_container, 0)  # Move to back for rendering order
	
	# Set as parent for MapManager
	MapManager.set_map_parent(map_container)

func _load_map() -> void:
	"""Load the map based on game_scene_data.map_data"""
	if not game_scene_data.map_data:
		push_warning("GameScene: No map_data in game_scene_data")
		return
	
	# Register the map with MapManager if not already registered
	var map_data: MapData = game_scene_data.map_data
	if not MapManager.get_map_data(map_data.map_id):
		MapManager.register_map(map_data)
	
	# Switch to this map (will load chunks if needed)
	var spawn_pos: Vector2 = Vector2.ZERO
	if game_scene_data.player_spawn:
		spawn_pos = game_scene_data.player_spawn.spawn_position
	
	MapManager.switch_to_map(map_data.map_id, spawn_pos)
	print("GameScene: Loaded map '%s'" % map_data.map_id)

func _spawn_player() -> void:
	"""Spawn the player at configured position"""
	if not game_scene_data.player_spawn:
		push_warning("GameScene: No player_spawn configuration")
		return
	
	# Load the player scene
	var player_scene: PackedScene = load("res://features/player/player.tscn")
	if not player_scene:
		push_error("GameScene: Failed to load player scene")
		return
	
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	# Set player position
	# If loading from save, player position is already set by load_data
	# Otherwise, use the spawn position from game_scene_data
	var should_use_spawn_position: bool = true
	
	if SaveManager and SaveManager.has_method("is_loading_from_save"):
		should_use_spawn_position = not SaveManager.is_loading_from_save()
	
	if should_use_spawn_position:
		player_instance.global_position = game_scene_data.player_spawn.spawn_position
		print("GameScene: Set player position to spawn default: %s" % game_scene_data.player_spawn.spawn_position)
	else:
		print("GameScene: Player position will be loaded from save file")
	
	# If custom player data provided, use it
	if game_scene_data.player_spawn.player_data:
		if player_instance.has_method("set_actor_data"):
			player_instance.set_actor_data(game_scene_data.player_spawn.player_data)
		elif "actor_data" in player_instance:
			player_instance.actor_data = game_scene_data.player_spawn.player_data
	
	print("GameScene: Spawned player")

func _spawn_entities() -> void:
	"""Spawn all dynamic entities from configuration"""
	if game_scene_data.spawnable_entities.is_empty():
		print("GameScene: No entities to spawn")
		return
	
	for entity_data in game_scene_data.spawnable_entities:
		_spawn_entity(entity_data)
	
	print("GameScene: Spawned %d entities" % spawned_entities.size())

func _spawn_entity(entity_data: SpawnableEntityData) -> void:
	"""Spawn a single entity from SpawnableEntityData"""
	if entity_data.scene_path.is_empty():
		push_warning("GameScene: Entity has empty scene_path")
		return
	
	# Load the entity scene
	var entity_scene: PackedScene = load(entity_data.scene_path)
	if not entity_scene:
		push_error("GameScene: Failed to load entity scene: %s" % entity_data.scene_path)
		return
	
	# Instantiate the entity
	var entity_instance: Node = entity_scene.instantiate()
	add_child(entity_instance)
	
	# Set position if entity is Node2D
	if entity_instance is Node2D:
		entity_instance.global_position = entity_data.spawn_position
	
	# Apply entity resource data if available
	if entity_data.entity_resource:
		_apply_entity_resource(entity_instance, entity_data.entity_resource)
	
	# Apply additional configuration
	if not entity_data.additional_config.is_empty():
		_apply_additional_config(entity_instance, entity_data.additional_config)
	
	# Store reference if spawn_id is provided
	if not entity_data.spawn_id.is_empty():
		spawned_entities[entity_data.spawn_id] = entity_instance
	
	print("GameScene: Spawned entity '%s' at position %s" % [entity_data.entity_type, entity_data.spawn_position])

func _apply_entity_resource(entity_instance: Node, resource: Resource) -> void:
	"""Apply resource data to entity instance"""
	# Try common property names
	if "actor_data" in entity_instance:
		entity_instance.actor_data = resource
	elif "vehicle_data" in entity_instance:
		entity_instance.vehicle_data = resource
	elif "data" in entity_instance:
		entity_instance.data = resource
	elif entity_instance.has_method("set_data"):
		entity_instance.set_data(resource)

func _apply_additional_config(entity_instance: Node, config: Dictionary) -> void:
	"""Apply additional configuration to entity"""
	for key in config.keys():
		if key in entity_instance:
			entity_instance.set(key, config[key])

func _setup_audio() -> void:
	"""Setup background music and ambient sound"""
	if game_scene_data.background_music and AudioManager.has_method("play_music"):
		AudioManager.play_music(game_scene_data.background_music)
	
	if game_scene_data.ambient_sound and AudioManager.has_method("play_ambient"):
		AudioManager.play_ambient(game_scene_data.ambient_sound)

func _physics_process(_delta: float) -> void:
	"""Update map chunks based on player position"""
	if is_instance_valid(player_instance):
		MapManager.update_chunks(player_instance.global_position)

# Public API for external access
func get_player() -> Node2D:
	"""Get the player instance"""
	return player_instance

func get_entity(spawn_id: String) -> Node:
	"""Get a spawned entity by its spawn_id"""
	return spawned_entities.get(spawn_id)

func get_all_entities() -> Array:
	"""Get all spawned entities"""
	return spawned_entities.values()

# Save/Load support
func save_data() -> Dictionary:
	"""Save game scene state"""
	var entity_states: Dictionary = {}
	for spawn_id in spawned_entities.keys():
		var entity = spawned_entities[spawn_id]
		if is_instance_valid(entity) and entity.has_method("save_data"):
			entity_states[spawn_id] = entity.save_data()
	
	return {
		"scene_id": game_scene_data.scene_id if game_scene_data else "",
		"entity_states": entity_states
	}

func load_data(data: Dictionary) -> void:
	"""Load game scene state"""
	if data.has("entity_states"):
		var entity_states = data["entity_states"]
		for spawn_id in entity_states.keys():
			var entity = spawned_entities.get(spawn_id)
			if is_instance_valid(entity) and entity.has_method("load_data"):
				entity.load_data(entity_states[spawn_id])
