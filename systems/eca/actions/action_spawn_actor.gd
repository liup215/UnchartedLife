# action_spawn_actor.gd
# Action that spawns an actor at a specific marker location in the scene.
extends GameAction
class_name ActionSpawnActor

# The ActorData resource defining the actor to spawn
@export var actor_data: ActorData = null

# The identifier of the marker node where the actor should spawn
# Marker should be a Node2D child of the context (GameScene)
@export var marker_id: String = ""

# Optional: Custom scene path if not using default base_actor.tscn
@export var custom_scene_path: String = ""

# Execute the action: find marker and spawn actor
func execute(context: Node) -> void:
	if not actor_data:
		push_error("ActionSpawnActor: No actor_data assigned")
		return
	
	if marker_id.is_empty():
		push_error("ActionSpawnActor: marker_id is empty")
		return
	
	# Find the marker node in the context's children
	var marker: Node = _find_marker(context, marker_id)
	if not marker:
		push_error("ActionSpawnActor: Marker '%s' not found in scene" % marker_id)
		return
	
	# Determine scene path
	var scene_path: String = custom_scene_path if not custom_scene_path.is_empty() else "res://features/actor/base_actor.tscn"
	
	# Load and instantiate the actor scene
	var actor_scene: PackedScene = load(scene_path)
	if not actor_scene:
		push_error("ActionSpawnActor: Failed to load actor scene: %s" % scene_path)
		return
	
	var actor_instance: Node = actor_scene.instantiate()
	if not actor_instance:
		push_error("ActionSpawnActor: Failed to instantiate actor scene")
		return
	
	# Set actor data
	if "actor_data" in actor_instance:
		actor_instance.actor_data = actor_data
	
	# Add to context and set position
	context.add_child(actor_instance)
	if actor_instance is Node2D and marker is Node2D:
		actor_instance.global_position = marker.global_position
	
	print("ActionSpawnActor: Spawned actor at marker '%s' with data: %s" % [marker_id, actor_data.resource_path])

# Helper function to find a marker by ID
func _find_marker(root: Node, id: String) -> Node:
	# First try direct child lookup
	var marker: Node = root.get_node_or_null(id)
	if marker:
		return marker
	
	# Try recursive search in all children
	return _recursive_find_marker(root, id)

func _recursive_find_marker(node: Node, id: String) -> Node:
	if node.name == id:
		return node
	
	for child in node.get_children():
		var result = _recursive_find_marker(child, id)
		if result:
			return result
	
	return null
