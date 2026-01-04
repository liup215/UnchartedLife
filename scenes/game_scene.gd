# game_scene.gd
# Generic game scene controller that loads from GameSceneData
# Implements the data-driven "Soul-Container-Brain" pattern
extends Node2D

# The data that defines this game scene
@export var game_scene_data: GameSceneData = null

# References to instantiated nodes
var map_container: Node2D = null
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
	
	# 3. Spawn dynamic entities
	_spawn_entities()
	
	# 4. Setup audio
	_setup_audio()
	
	# 5. Execute on_start events (ECA system)
	_execute_on_start_events()
	
	# 6. Bind interaction triggers (ECA system)
	_bind_triggers()
	
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

# ============ ECA SYSTEM METHODS ============

func _execute_on_start_events() -> void:
	"""Execute all on_start events when the scene loads"""
	if not game_scene_data or game_scene_data.on_start_events.is_empty():
		return
	
	print("GameScene: Executing %d on_start events" % game_scene_data.on_start_events.size())
	
	for event in game_scene_data.on_start_events:
		if event:
			event.try_execute(self)

func _bind_triggers() -> void:
	"""Bind Area2D triggers to interaction events"""
	if not game_scene_data or game_scene_data.interaction_events.is_empty():
		return
	
	print("GameScene: Binding %d interaction triggers" % game_scene_data.interaction_events.size())
	
	for area_name in game_scene_data.interaction_events.keys():
		var event_data: GameEventData = game_scene_data.interaction_events[area_name]
		if not event_data:
			continue
		
		# Find the Area2D node in the scene
		var area: Area2D = _find_area2d(area_name)
		if not area:
			push_warning("GameScene: Area2D '%s' not found for interaction event" % area_name)
			continue
		
		# Connect the body_entered signal to trigger the event
		if not area.body_entered.is_connected(_on_trigger_area_entered):
			area.body_entered.connect(_on_trigger_area_entered.bind(event_data))
			print("GameScene: Bound trigger '%s' to event '%s'" % [area_name, event_data.event_id])

func _find_area2d(area_name: String) -> Area2D:
	"""Find an Area2D node by name in the scene hierarchy"""
	# Try direct child lookup
	var area: Node = get_node_or_null(area_name)
	if area and area is Area2D:
		return area as Area2D
	
	# Try recursive search
	return _recursive_find_area2d(self, area_name)

func _recursive_find_area2d(node: Node, area_name: String) -> Area2D:
	"""Recursively search for Area2D by name"""
	if node.name == area_name and node is Area2D:
		return node as Area2D
	
	for child in node.get_children():
		var result = _recursive_find_area2d(child, area_name)
		if result:
			return result
	
	return null

func _on_trigger_area_entered(body: Node, event_data: GameEventData) -> void:
	"""Handle trigger area entered by checking if it's the player and executing the event"""
	# Check if the body that entered is the player
	if not body.is_in_group("player"):
		return
	
	print("GameScene: Player entered trigger area, executing event '%s'" % event_data.event_id)
	event_data.try_execute(self)

