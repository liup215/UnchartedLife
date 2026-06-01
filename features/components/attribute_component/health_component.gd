# health_component.gd
extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal died

# @export var data_source: ActorData # 与 metabolism_component、speed_component 一致

var max_health: int = 100
var current_health: int = 100
var is_invincible: bool = false  # Invincibility flag for dodge and other effects

func _ready():
	pass

func set_runtime_state(rs: ActorRuntimeState):
	max_health = rs.max_health
	current_health = rs.current_health
	emit_signal("health_changed", current_health, max_health)

## Sync a health value change to the new StatSystem.
func _sync_new_system_health() -> void:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			stat_system.set_stat_value(eid, "health", float(current_health))

func set_current_health(value: int):
	var old = current_health
	current_health = clamp(value, 0, max_health)
	_sync_new_system_health()
	if current_health != old:
		emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		emit_signal("died")

func take_damage(amount: int):
	# Check invincibility flag
	if is_invincible:
		return  # No damage taken when invincible
	
	set_current_health(current_health - amount)

func heal(amount: int):
	set_current_health(current_health + amount)

func set_max_health(new_max: int, heal_to_full: bool = true):
	# data_source.max_health = new_max
	# if heal_to_full:
	# 	data_source.current_health = data_source.max_health
	# else:
	# 	data_source.current_health = min(data_source.current_health, data_source.max_health)
	# emit_signal("health_changed", data_source.current_health, data_source.max_health)
	max_health = new_max
	if heal_to_full:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

## Get actor entity_id from parent chain (HealthComponent -> AttributeComponent -> Actor)
func _get_actor_entity_id() -> int:
	var attribute_comp: Node = get_parent()
	if attribute_comp and attribute_comp.get_parent():
		var actor = attribute_comp.get_parent()
		if actor and actor.get("entity_id"):
			return int(actor.entity_id)
	return -1

func get_current_health() -> int:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return int(stat_system.get_stat_value(eid, "health", float(current_health)))
	return current_health

func get_max_health() -> int:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return int(stat_system.get_stat_value(eid, "max_health", float(max_health)))
	return max_health

func set_invincible(invincible: bool):
	"""Set invincibility state"""
	is_invincible = invincible

func get_is_invincible() -> bool:
	"""Get invincibility state"""
	return is_invincible
