# systems/ecs/entity_manager.gd
# Lightweight ECS-style entity registry.
# All game entities (Actor, Vehicle, Projectile) register here with a stable int ID.
# This enables cross-system communication without node references.
extends Node
class_name EntityManager

## Fired when a new entity is registered.
signal entity_registered(entity_id: int, node: Node)
signal entity_unregistered(entity_id: int)

## Registry: entity_id -> { type: String, node: Node, components: Dictionary }
var _entities: Dictionary[int, Dictionary] = {}
var _node_to_id: Dictionary[Node, int] = {}
var _next_entity_id: int = 1

## Register a scene node as an entity and return a stable int ID.
func register_entity(node: Node, entity_type: String = "unknown") -> int:
	if _node_to_id.has(node):
		push_warning("EntityManager: node %s already registered with id %d" % [node.name, _node_to_id[node]])
		return _node_to_id[node]
	var id: int = _next_entity_id
	_next_entity_id += 1
	_entities[id] = {
		"type": entity_type,
		"node": node,
		"components": Dictionary()
	}
	_node_to_id[node] = id
	entity_registered.emit(id, node)
	return id

func unregister_entity(entity_id: int) -> void:
	if not _entities.has(entity_id):
		return
	var data: Dictionary = _entities[entity_id]
	var node: Node = data.get("node") as Node
	if node and _node_to_id.has(node):
		_node_to_id.erase(node)
	_entities.erase(entity_id)
	entity_unregistered.emit(entity_id)

func get_entity(entity_id: int) -> Dictionary:
	return _entities.get(entity_id, {})

func get_node(entity_id: int) -> Node:
	var data: Dictionary = _entities.get(entity_id, {})
	return data.get("node", null)

func get_entity_id(node: Node) -> int:
	return _node_to_id.get(node, -1)

func add_component(entity_id: int, component_name: String, component: Object) -> void:
	var data: Dictionary = _entities.get(entity_id, {})
	if data.is_empty():
		push_error("EntityManager: entity %d does not exist" % entity_id)
		return
	var comps: Dictionary = data.get("components", {}) as Dictionary
	comps[component_name] = component
	data["components"] = comps

func get_component(entity_id: int, component_name: String) -> Object:
	var data: Dictionary = _entities.get(entity_id, {})
	var comps: Dictionary = data.get("components", {}) as Dictionary
	return comps.get(component_name, null)

func has_component(entity_id: int, component_name: String) -> bool:
	return get_component(entity_id, component_name) != null

func get_component_from_node(node: Node, component_name: String) -> Object:
	var id: int = get_entity_id(node)
	if id < 0:
		return null
	return get_component(id, component_name)

func get_all_entities_with_component(component_name: String) -> Array[int]:
	var result: Array[int] = []
	for entity_id in _entities:
		var data: Dictionary = _entities[entity_id]
		var comps: Dictionary = data.get("components", {}) as Dictionary
		if comps.has(component_name):
			result.append(entity_id)
	return result

func has_entity(entity_id: int) -> bool:
	return _entities.has(entity_id)

func get_entity_count() -> int:
	return _entities.size()
