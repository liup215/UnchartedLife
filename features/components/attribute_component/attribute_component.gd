# attribute_component.gd
# Dynamically discovers and manages health, metabolism, speed, and toughness sub-components.
# New sub-components can be added as children without modifying this script.
extends Node2D
class_name AttributeComponent

## Discovered sub-components (auto-populated in _ready)
var health_component: HealthComponent = null
var metabolism_component: MetabolismComponent = null
var speed_component: SpeedComponent = null
var toughness_component: ToughnessComponent = null

var _sub_components: Array[Node] = []

func _ready():
	_discover_sub_components()

## Scans children and registers any known attribute sub-components by type.
func _discover_sub_components() -> void:
	for child in get_children():
		if child is HealthComponent:
			health_component = child
			_sub_components.append(child)
		elif child is MetabolismComponent:
			metabolism_component = child
			_sub_components.append(child)
		elif child is SpeedComponent:
			speed_component = child
			_sub_components.append(child)
		elif child is ToughnessComponent:
			toughness_component = child
			_sub_components.append(child)
	
	if not health_component:
		push_warning("AttributeComponent: No HealthComponent found among children.")
	if not metabolism_component:
		push_warning("AttributeComponent: No MetabolismComponent found among children.")
	if not speed_component:
		push_warning("AttributeComponent: No SpeedComponent found among children.")

func set_runtime_state(rs: ActorRuntimeState) -> void:
	for comp in _sub_components:
		if comp.has_method("set_runtime_state"):
			comp.set_runtime_state(rs)

# ATP delegation (used by combat, dodge, and item systems)
# During Wave 2 migration: prefer StatSystem if the actor has an entity_id.
func _get_actor_entity_id() -> int:
	# AttributeComponent's parent should be the Actor (CharacterBody2D)
	var parent = get_parent()
	if parent and parent.get("entity_id"):
		return int(parent.entity_id)
	return -1

func get_current_atp() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp", 0.0)
	if metabolism_component:
		return metabolism_component.get_current_atp()
	return 0.0

func consume_atp(amount: float) -> bool:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var pool_system: ResourcePoolSystem = ServiceRegistry.get_service("ResourcePoolSystem")
		if pool_system:
			pool_system.consume(eid, "atp", amount)
	# Always write to old system to trigger signals
	if metabolism_component:
		metabolism_component.consume_atp(amount)
		return true
	return false

# 批量存档
func to_dict() -> Dictionary:
	var result = {}
	if health_component:
		result["health"] = health_component.to_dict()
	if metabolism_component:
		result["metabolism"] = metabolism_component.to_dict()
	if speed_component:
		result["speed"] = speed_component.to_dict()
	if toughness_component:
		result["toughness"] = toughness_component.to_dict()
	return result

# 批量恢复
func from_dict(data: Dictionary) -> void:
	if health_component and data.has("health"):
		health_component.from_dict(data["health"])
	if metabolism_component and data.has("metabolism"):
		metabolism_component.from_dict(data["metabolism"])
	if speed_component and data.has("speed"):
		speed_component.from_dict(data["speed"])
	if toughness_component and data.has("toughness"):
		toughness_component.from_dict(data["toughness"])
