# systems/combat/charge_system.gd
# Replaces the node-based ChargeComponent with a pure data-driven charge state.
# Each weapon on each entity has its own charge level and progress.
# No node references; only entity_id keyed data.
extends Node
class_name ChargeSystem

## entity_id -> {weapon_index: ChargeState}
var _entity_charges: Dictionary[int, Dictionary] = {}

class ChargeState:
	var charge_level: int = 0
	var charge_progress: float = 0.0  # progress within current level (0.0-100.0)
	var is_charging: bool = false
	var charge_rate: float = 10.0  # progress per second
	var progress_per_level: float = 100.0
	var max_level: int = 5
	## Whether light attacks add charge progress.
	var light_attacks_build_charge: bool = false

	func reset() -> void:
		charge_level = 0
		charge_progress = 0.0
		is_charging = false

func register_entity(entity_id: int) -> void:
	if not _entity_charges.has(entity_id):
		_entity_charges[entity_id] = {}

func unregister_entity(entity_id: int) -> void:
	_entity_charges.erase(entity_id)

## Configure a weapon slot's charge parameters.
func configure_weapon(entity_id: int, weapon_index: int,
		charge_rate: float, progress_per_level: float, max_level: int,
		light_attacks_build: bool = false) -> void:
	register_entity(entity_id)
	var state := ChargeState.new()
	state.charge_rate = charge_rate
	state.progress_per_level = progress_per_level
	state.max_level = max_level
	state.light_attacks_build_charge = light_attacks_build
	_entity_charges[entity_id][weapon_index] = state

## --- Queries ---

func get_charge_state(entity_id: int, weapon_index: int = 0) -> ChargeState:
	if _entity_charges.has(entity_id):
		return _entity_charges[entity_id].get(weapon_index, null)
	return null

func get_charge_level(entity_id: int, weapon_index: int = 0) -> int:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		return state.charge_level
	return 0

func get_effective_charge(entity_id: int, weapon_index: int = 0) -> float:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		return state.charge_level + (state.charge_progress / state.progress_per_level)
	return 0.0

func is_charging(entity_id: int, weapon_index: int = 0) -> bool:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		return state.is_charging
	return false

## --- Commands ---

func start_charge(entity_id: int, weapon_index: int = 0) -> void:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		state.is_charging = true

func stop_charge(entity_id: int, weapon_index: int = 0) -> float:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		state.is_charging = false
		return get_effective_charge(entity_id, weapon_index)
	return 0.0

func reset_charge(entity_id: int, weapon_index: int = 0) -> void:
	var state = get_charge_state(entity_id, weapon_index)
	if state:
		state.reset()

func add_light_attack_charge_progress(entity_id: int, progress: float, weapon_index: int = 0) -> void:
	var state = get_charge_state(entity_id, weapon_index)
	if not state or not state.light_attacks_build_charge:
		return
	state.charge_progress += progress
	while state.charge_progress >= state.progress_per_level and state.charge_level < state.max_level:
		state.charge_progress -= state.progress_per_level
		state.charge_level += 1
	if state.charge_level >= state.max_level:
		state.charge_progress = 0.0
		state.charge_level = state.max_level

## Per-frame tick: charge builds while holding.
func on_tick(delta: float) -> void:
	for entity_id in _entity_charges:
		var weapons = _entity_charges[entity_id]
		for weapon_index in weapons:
			var state: ChargeState = weapons[weapon_index]
			if state.is_charging:
				state.charge_progress += state.charge_rate * delta
				while state.charge_progress >= state.progress_per_level and state.charge_level < state.max_level:
					state.charge_progress -= state.progress_per_level
					state.charge_level += 1
				if state.charge_level >= state.max_level:
					state.charge_progress = 0.0
					state.charge_level = state.max_level
