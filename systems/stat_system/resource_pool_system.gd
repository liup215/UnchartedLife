# systems/stat_system/resource_pool_system.gd
# High-level API for consuming / recovering resource-pool stats (HP, ATP, glucose, toughness).
# Sits on top of StatSystem and adds semantic events like "depleted" and "insufficient".
extends Node
class_name ResourcePoolSystem

signal resource_depleted(entity_id: int, resource_type: String)
signal resource_insufficient(entity_id: int, resource_type: String, requested: float, available: float)
signal resource_changed(entity_id: int, resource_type: String, current: float, max_value: float)
signal resource_recovered(entity_id: int, resource_type: String, amount: float, current: float, max_value: float)

var _stat_system = null

func _ready() -> void:
	_stat_system = ServiceRegistry.get_service("stat_system") as StatSystem
	if _stat_system:
		_stat_system.stat_changed.connect(_on_stat_changed)

func _on_stat_changed(entity_id: int, stat_id: String, current: float, max_val: float) -> void:
	resource_changed.emit(entity_id, stat_id, current, max_val)

## Try to consume an amount of a resource. Returns true if fully consumed.
## If insufficient, consumes what it can, emits resource_depleted, and returns false.
func consume(entity_id: int, resource_type: String, amount: float) -> bool:
	var stat := _stat_system.get_stat(entity_id, resource_type) if _stat_system else null
	if not stat:
		push_error("ResourcePoolSystem: stat '%s' not found for entity %d" % [resource_type, entity_id])
		return false

	var available: float = stat.get_current()
	if available < amount:
		stat.set_current(0.0)
		resource_depleted.emit(entity_id, resource_type)
		resource_insufficient.emit(entity_id, resource_type, amount, available)
		resource_changed.emit(entity_id, resource_type, 0.0, stat.get_effective_max())
		return false

	stat.set_current(available - amount)
	resource_changed.emit(entity_id, resource_type, stat.get_current(), stat.get_effective_max())
	return true

## Recover an amount (clamped to max).
func recover(entity_id: int, resource_type: String, amount: float) -> void:
	var stat := _stat_system.get_stat(entity_id, resource_type) if _stat_system else null
	if not stat:
		return
	var old: float = stat.get_current()
	var effective_max: float = stat.get_effective_max()
	stat.set_current(min(old + amount, effective_max))
	var current: float = stat.get_current()
	if current != old:
		resource_recovered.emit(entity_id, resource_type, amount, current, effective_max)
		resource_changed.emit(entity_id, resource_type, current, effective_max)

## Get current value. Returns -1 if stat missing.
func get_current(entity_id: int, resource_type: String) -> float:
	var stat := _stat_system.get_stat(entity_id, resource_type) if _stat_system else null
	if stat:
		return stat.get_current()
	return -1.0

## Get max value (after modifiers). Returns -1 if stat missing.
func get_max(entity_id: int, resource_type: String) -> float:
	var stat := _stat_system.get_stat(entity_id, resource_type) if _stat_system else null
	if stat:
		return stat.get_effective_max()
	return -1.0

## Check if entity has enough of resource.
func has_enough(entity_id: int, resource_type: String, amount: float) -> bool:
	var current: float = get_current(entity_id, resource_type)
	return current >= amount

## Set current directly (use sparingly, prefer consume/recover).
func set_current(entity_id: int, resource_type: String, value: float) -> void:
	if _stat_system:
		_stat_system.set_current(entity_id, resource_type, value)
