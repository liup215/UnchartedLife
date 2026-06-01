# systems/stat_system/stat_system.gd
# Central authority for all numeric stats across ALL entities.
# Replaces AttributeComponent and its hard-coded sub-component discovery.
# Every entity gets a stat dictionary keyed by stat_id.
extends Node
class_name StatSystem

const StatDefinition = preload("res://data/definitions/stat/stat_definition.gd")
const StatModifier = preload("res://systems/stat_system/stat_modifier.gd")

## Debug grouping for GameLogger
const LOG_DOMAIN: String = "stat"

## signal emitted whenever any stat value changes.
signal stat_changed(entity_id: int, stat_id: String, current: float, max_val: float)
signal stat_max_changed(entity_id: int, stat_id: String, new_max: float)

## Stat instance held per entity/stat pair.
class StatInstance:
	var stat_id: String
	var base_value: float = 0.0
	var current_value: float = 0.0
	var modifiers: Array[StatModifier] = []
	var min_value: float = -999999.0
	var max_value: float = 999999.0
	var is_resource_pool: bool = false  # If true, has current/max pair managed here.

	func initialize(p_base: float, p_min: float = -999999.0, p_max: float = 999999.0,
			p_pool: bool = false) -> void:
		base_value = p_base
		current_value = p_base
		min_value = p_min
		max_value = p_max
		is_resource_pool = p_pool

	## Recompute final value after all modifiers.
	func get_final_value() -> float:
		var result: float = base_value
		for mod in modifiers:
			result = mod.apply(result)
		return clamp(result, min_value, max_value)

	## Set current value (for resource-pool stats like HP, ATP).
	func set_current(val: float) -> bool:
		var old: float = current_value
		var effective_max: float = get_effective_max()
		current_value = clamp(val, min_value, effective_max)
		return current_value != old

	func get_current() -> float:
		return current_value

	func get_effective_max() -> float:
		if is_resource_pool:
			return get_final_value()
		return max_value

	func add_modifier(mod: StatModifier) -> void:
		modifiers.append(mod)
		_sort_modifiers()

	func remove_modifier(mod: StatModifier) -> void:
		modifiers.erase(mod)

	func remove_modifiers_by_source(source: String) -> void:
		modifiers = modifiers.filter(func(m: StatModifier) -> bool: return m.source_id != source)

	func _sort_modifiers() -> void:
		modifiers.sort_custom(func(a: StatModifier, b: StatModifier) -> int:
			return a.priority - b.priority
		)

	func to_dict() -> Dictionary:
		return {
			"base_value": base_value,
			"current_value": current_value,
			"min_value": min_value,
			"max_value": max_value,
			"is_resource_pool": is_resource_pool
		}

	func from_dict(data: Dictionary) -> void:
		base_value = data.get("base_value", base_value)
		current_value = data.get("current_value", current_value)
		min_value = data.get("min_value", min_value)
		max_value = data.get("max_value", max_value)
		is_resource_pool = data.get("is_resource_pool", is_resource_pool)

## Main storage: entity_id -> {stat_id: StatInstance}
var _entity_stats: Dictionary[int, Dictionary] = {}

## --- Entity lifecycle ---

func register_entity(entity_id: int) -> void:
	if not _entity_stats.has(entity_id):
		_entity_stats[entity_id] = {}

func unregister_entity(entity_id: int) -> void:
	_entity_stats.erase(entity_id)

## Initialize a stat from a StatDefinition resource.
func add_stat(entity_id: int, def: StatDefinition) -> void:
	register_entity(entity_id)
	var inst := StatInstance.new()
	inst.stat_id = def.stat_id
	inst.initialize(def.base_value, def.min_value, def.max_value, def.is_resource_pool)
	var entity_dict: Dictionary = _entity_stats[entity_id]
	entity_dict[def.stat_id] = inst
	stat_changed.emit(entity_id, def.stat_id, inst.current_value, inst.get_effective_max())

## Batch init multiple stats.
func add_stats_from_definitions(entity_id: int, definitions: Array[StatDefinition]) -> void:
	for def in definitions:
		add_stat(entity_id, def)

## Convenience: add a raw stat without a resource.
func add_raw_stat(entity_id: int, stat_id: String, base_value: float,
		min_val: float = -999999.0, max_val: float = 999999.0,
		is_pool: bool = false) -> void:
	register_entity(entity_id)
	var inst := StatInstance.new()
	inst.stat_id = stat_id
	inst.initialize(base_value, min_val, max_val, is_pool)
	var entity_dict: Dictionary = _entity_stats[entity_id]
	entity_dict[stat_id] = inst
	stat_changed.emit(entity_id, stat_id, inst.current_value, inst.get_effective_max())

## --- Queries ---

func has_stat(entity_id: int, stat_id: String) -> bool:
	if not _entity_stats.has(entity_id):
		return false
	var entity_dict: Dictionary = _entity_stats[entity_id]
	return entity_dict.has(stat_id)

func get_stat(entity_id: int, stat_id: String) -> StatInstance:
	if not _entity_stats.has(entity_id):
		return null
	var entity_dict: Dictionary = _entity_stats[entity_id]
	return entity_dict.get(stat_id, null)

func get_stat_value(entity_id: int, stat_id: String, default_value: float = 0.0) -> float:
	var stat := get_stat(entity_id, stat_id)
	if stat:
		return stat.get_final_value()
	return default_value

func get_stat_current(entity_id: int, stat_id: String) -> float:
	var stat := get_stat(entity_id, stat_id)
	if stat:
		return stat.get_current()
	return 0.0

func get_stat_base(entity_id: int, stat_id: String) -> float:
	var stat := get_stat(entity_id, stat_id)
	if stat:
		return stat.base_value
	return 0.0

## --- Modifiers ---

func add_modifier(entity_id: int, mod: StatModifier) -> void:
	var stat := get_stat(entity_id, mod.stat_id)
	if not stat:
		push_warning("StatSystem: stat '%s' not found for entity %d" % [mod.stat_id, entity_id])
		return
	stat.add_modifier(mod)
	stat_max_changed.emit(entity_id, mod.stat_id, stat.get_effective_max())

func remove_modifier(entity_id: int, mod: StatModifier) -> void:
	var stat := get_stat(entity_id, mod.stat_id)
	if stat:
		stat.remove_modifier(mod)
		stat_max_changed.emit(entity_id, mod.stat_id, stat.get_effective_max())

func remove_modifiers_by_source(entity_id: int, source_id: String) -> void:
	if not _entity_stats.has(entity_id):
		return
	var entity_dict: Dictionary = _entity_stats[entity_id]
	for stat_id in entity_dict:
		var stat = entity_dict[stat_id]
		stat.remove_modifiers_by_source(source_id)

## --- Modification API ---

func modify_base(entity_id: int, stat_id: String, delta: float) -> void:
	var stat := get_stat(entity_id, stat_id)
	if not stat:
		return
	stat.base_value += delta
	stat_changed.emit(entity_id, stat_id, stat.get_current(), stat.get_effective_max())

func set_base(entity_id: int, stat_id: String, value: float) -> void:
	var stat := get_stat(entity_id, stat_id)
	if not stat:
		return
	stat.base_value = value
	stat_changed.emit(entity_id, stat_id, stat.get_current(), stat.get_effective_max())

## --- Resource-pool API (sets current value) ---

## Alias for setting the current pool value. Used by old component bridge code.
func set_stat_value(entity_id: int, stat_id: String, value: float) -> bool:
	return set_current(entity_id, stat_id, value)

func set_current(entity_id: int, stat_id: String, value: float) -> bool:
	var stat := get_stat(entity_id, stat_id)
	if not stat:
		return false
	var changed: bool = stat.set_current(value)
	if changed:
		stat_changed.emit(entity_id, stat_id, stat.get_current(), stat.get_effective_max())
	return changed

func modify_current(entity_id: int, stat_id: String, delta: float) -> bool:
	var stat := get_stat(entity_id, stat_id)
	if not stat:
		return false
	return set_current(entity_id, stat_id, stat.get_current() + delta)

## --- Persistence ---

func get_entity_stats_dict(entity_id: int) -> Dictionary:
	if not _entity_stats.has(entity_id):
		return {}
	var result: Dictionary = {}
	var entity_dict: Dictionary = _entity_stats[entity_id]
	for stat_id in entity_dict:
		var stat = entity_dict[stat_id]
		result[stat_id] = stat.to_dict()
	return result

func load_entity_stats_dict(entity_id: int, data: Dictionary) -> void:
	register_entity(entity_id)
	var entity_dict: Dictionary = _entity_stats[entity_id]
	for stat_id in data:
		var stat_data: Dictionary = data[stat_id]
		var inst = entity_dict.get(stat_id) as StatInstance
		if inst:
			inst.from_dict(stat_data)
		else:
			inst = StatInstance.new()
			inst.stat_id = stat_id
			inst.from_dict(stat_data)
			entity_dict[stat_id] = inst
		stat_changed.emit(entity_id, stat_id, inst.get_current(), inst.get_effective_max())

## --- Tick: process timed modifiers ---

func on_tick(delta: float) -> void:
	for entity_id in _entity_stats:
		var entity_dict: Dictionary = _entity_stats[entity_id]
		for stat_id in entity_dict:
			var stat = entity_dict[stat_id]
			var expired: Array[StatModifier] = []
			for mod in stat.modifiers:
				if mod.duration >= 0.0:
					mod.duration -= delta
					if mod.duration <= 0.0:
						expired.append(mod)
			for mod in expired:
				stat.remove_modifier(mod)
				stat_changed.emit(entity_id, stat_id, stat.get_current(), stat.get_effective_max())
