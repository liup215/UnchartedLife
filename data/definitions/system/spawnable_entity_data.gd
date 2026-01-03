# spawnable_entity_data.gd
# Resource class to define a spawnable entity (NPC, vehicle, enemy, interactive object)
extends Resource
class_name SpawnableEntityData

# Entity type identifier - determines which scene/prefab to instantiate
@export var entity_type: String = ""

# Reference to the scene to spawn (e.g., "res://features/actor/base_actor.tscn")
@export var scene_path: String = ""

# Position where the entity should spawn
@export var spawn_position: Vector2 = Vector2.ZERO

# Optional: Data resource for the entity (e.g., ActorData, VehicleData)
@export var entity_resource: Resource = null

# Optional: Unique identifier for this spawn point
@export var spawn_id: String = ""

# Optional: Additional configuration data as dictionary
@export var additional_config: Dictionary = {}

# Convert to dictionary for saving
func to_dict() -> Dictionary:
	# Helper to safely get resource path
	var resource_path_str: String = ""
	if entity_resource and entity_resource.resource_path:
		resource_path_str = entity_resource.resource_path
	
	return {
		"entity_type": entity_type,
		"scene_path": scene_path,
		"spawn_position": {"x": spawn_position.x, "y": spawn_position.y},
		"entity_resource": resource_path_str,
		"spawn_id": spawn_id,
		"additional_config": additional_config
	}

# Load from dictionary
func from_dict(data: Dictionary) -> void:
	entity_type = data.get("entity_type", entity_type)
	scene_path = data.get("scene_path", scene_path)
	spawn_id = data.get("spawn_id", spawn_id)
	additional_config = data.get("additional_config", additional_config)
	
	# Load spawn position
	if data.has("spawn_position"):
		var pos_data = data["spawn_position"]
		spawn_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
	
	# Load entity resource
	if data.has("entity_resource") and not data["entity_resource"].is_empty():
		entity_resource = load(data["entity_resource"])
