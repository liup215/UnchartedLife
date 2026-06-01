# systems/metabolism/metabolism_system.gd
# Central authority for ALL biological energy processing.
# Replaces metabolism logic scattered in Player.gd, Vehicle.gd, and components.
# Processes on_tick for ALL registered entities.
# No node references; operates purely on entity_id through StatSystem / ResourcePoolSystem.
extends Node
class_name MetabolismSystem

## Per-entity runtime context for sprint/movement state
## These are NOT persistent stats; they are transient flags for metabolism calculation.
var _entity_context: Dictionary[int, Dictionary] = {}

## Constants (match old Player.gd values)
const BASE_ATP_CONSUMPTION: float = 2.0  # ATP/sec at rest
const MOVEMENT_ATP_CONSUMPTION: float = 3.0  # ATP/sec during movement
const SPRINT_ATP_CONSUMPTION: float = 6.0  # ATP/sec when sprinting
const GLUCOSE_BASAL_FACTOR: float = 0.3  # 30% of glucose_consume_rate
const VEHICLE_BASAL_FACTOR: float = 0.2  # 20% of glucose_consume_rate (for vehicles/in_vehicle)

## Depletion damage constants
const ATP_DEPLETION_DAMAGE_AMOUNT: int = 1
const ATP_DEPLETION_DAMAGE_INTERVAL: float = 1.0
const ATP_DEPLETION_THRESHOLD: float = 0.001

## Per-entity depletion timer tracking
var _depletion_timers: Dictionary[int, float] = {}

## --- Registration ---

func register_entity(entity_id: int) -> void:
	if not _entity_context.has(entity_id):
		_entity_context[entity_id] = {
			"is_sprinting": false,
			"is_moving": false,
			"mode": "on_foot",  # "on_foot" or "in_vehicle"
		}
		_depletion_timers[entity_id] = 0.0

func unregister_entity(entity_id: int) -> void:
	_entity_context.erase(entity_id)
	_depletion_timers.erase(entity_id)

## Called by PlayerStateMachine or Player when state changes.
func set_entity_movement_context(entity_id: int, is_moving: bool, is_sprinting: bool, mode: String = "on_foot") -> void:
	register_entity(entity_id)
	_entity_context[entity_id]["is_moving"] = is_moving
	_entity_context[entity_id]["is_sprinting"] = is_sprinting
	_entity_context[entity_id]["mode"] = mode

## --- Core Processing ---

func on_tick(delta: float) -> void:
	for entity_id in _entity_context.keys():
		_process_entity_metabolism(entity_id, delta)

func _process_entity_metabolism(entity_id: int, delta: float) -> void:
	var ctx = _entity_context[entity_id]
	var is_moving = ctx.get("is_moving", false)
	var is_sprinting = ctx.get("is_sprinting", false)
	var mode = ctx.get("mode", "on_foot")

	# 1. ATP Consumption (Rest base + movement + sprinting)
	var total_atp_consumption = _calculate_atp_consumption(entity_id, is_moving, is_sprinting, mode, delta)
	_consume_atp(entity_id, total_atp_consumption)

	# 2. ATP Recovery (glucose -> ATP conversion)
	_process_atp_recovery(entity_id, delta)

	# 3. Basal Glucose Consumption (cellular maintenance)
	var basal_glucose_cost = _calculate_basal_glucose(entity_id, mode, delta)
	_consume_glucose(entity_id, basal_glucose_cost)

	# 4. ATP Depletion Damage
	_process_atp_depletion_damage(entity_id, delta)

func _calculate_atp_consumption(entity_id: int, is_moving: bool, is_sprinting: bool, mode: String, delta: float) -> float:
	var base = BASE_ATP_CONSUMPTION * delta
	if mode == "in_vehicle":
		# In vehicle, player/occupant only does basal ATP consumption
		return base
	var movement = 0.0
	var sprint = 0.0
	if is_moving:
		movement = MOVEMENT_ATP_CONSUMPTION * delta
	if is_sprinting and is_moving:
		# Only consume sprint ATP if actually moving
		sprint = SPRINT_ATP_CONSUMPTION * delta
	return base + movement + sprint

func _calculate_basal_glucose(entity_id: int, mode: String, delta: float) -> float:
	var consume_rate = _get_stat(entity_id, "glucose_consume_rate", 5.0)
	var factor = VEHICLE_BASAL_FACTOR if mode == "in_vehicle" else GLUCOSE_BASAL_FACTOR
	return consume_rate * delta * factor

func _process_atp_recovery(entity_id: int, delta: float) -> void:
	var current_atp = _get_stat(entity_id, "atp", 0.0)
	var max_atp = _get_stat(entity_id, "max_atp", 100.0)
	if current_atp >= max_atp:
		return

	var atp_needed = max_atp - current_atp
	var production_rate = _get_stat(entity_id, "atp_production_rate", 5.0)
	var atp_to_recover = min(production_rate * delta, atp_needed)

	var conversion_rate = _get_stat(entity_id, "atp_conversion_rate", 1.0)
	if conversion_rate <= 0:
		return

	var glucose_for_atp = atp_to_recover / conversion_rate
	var current_glucose = _get_stat(entity_id, "glucose", 0.0)

	if current_glucose >= glucose_for_atp:
		_consume_glucose(entity_id, glucose_for_atp)
		_recover_atp(entity_id, atp_to_recover)
	elif current_glucose > 0:
		var partial_atp = current_glucose * conversion_rate
		_consume_glucose(entity_id, current_glucose)
		_recover_atp(entity_id, partial_atp)

func _process_atp_depletion_damage(entity_id: int, delta: float) -> void:
	var current_atp = _get_stat(entity_id, "atp", 1.0)
	if current_atp < ATP_DEPLETION_THRESHOLD:
		_depletion_timers[entity_id] += delta
		if _depletion_timers[entity_id] >= ATP_DEPLETION_DAMAGE_INTERVAL:
			var current_hp = _get_stat(entity_id, "health", 100.0)
			if current_hp > 1:
				var new_hp = max(current_hp - ATP_DEPLETION_DAMAGE_AMOUNT, 1)
				_set_stat(entity_id, "health", new_hp)
			_depletion_timers[entity_id] = fmod(_depletion_timers[entity_id], ATP_DEPLETION_DAMAGE_INTERVAL)
	else:
		_depletion_timers[entity_id] = 0.0

## --- Stat / Pool helpers ---

func _get_stat(entity_id: int, stat_id: String, default_val: float) -> float:
	var stat_system = ServiceRegistry.get_service("StatSystem")
	if stat_system:
		return stat_system.get_stat_value(entity_id, stat_id, default_val)
	return default_val

func _set_stat(entity_id: int, stat_id: String, value: float) -> void:
	var stat_system = ServiceRegistry.get_service("StatSystem")
	if stat_system:
		stat_system.set_stat_value(entity_id, stat_id, value)

func _consume_atp(entity_id: int, amount: float) -> void:
	var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
	if pool_system:
		pool_system.consume(entity_id, "atp", amount)

func _recover_atp(entity_id: int, amount: float) -> void:
	var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
	if pool_system:
		pool_system.recover(entity_id, "atp", amount)

func _consume_glucose(entity_id: int, amount: float) -> void:
	var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
	if pool_system:
		pool_system.consume(entity_id, "glucose", amount)
