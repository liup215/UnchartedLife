# heavy_attack_system.gd
# Manages heavy attack charge state, release, and data resolution
extends Node
class_name HeavyAttackSystem

const DAMAGE_CHARGE_SCALING_FACTOR: float = 0.4
const ATP_CHARGE_SCALING_FACTOR: float = 0.5

var is_charging_heavy: bool = false
var last_heavy_charge: float = 0.0

signal heavy_attack_performed(charge_level: int, heavy_data: HeavyAttackData)
signal heavy_charge_started()
signal heavy_charge_released(effective_charge: float)


func start_charge(charge_component: ChargeComponent) -> bool:
	if not charge_component:
		return false
	is_charging_heavy = true
	charge_component.start_heavy_charge()
	heavy_charge_started.emit()
	return true


func release_charge(charge_component: ChargeComponent) -> float:
	if not charge_component or not is_charging_heavy:
		return -1.0
	is_charging_heavy = false
	var effective_charge: float = charge_component.stop_heavy_charge()
	last_heavy_charge = effective_charge
	heavy_charge_released.emit(effective_charge)
	return effective_charge


func calculate_atp_cost(
	base_atp: float,
	effective_charge: float,
	heavy_data: HeavyAttackData
) -> float:
	var charge_multiplier: float = 1.0 + (effective_charge * ATP_CHARGE_SCALING_FACTOR)
	return base_atp * charge_multiplier * heavy_data.atp_cost_multiplier


func get_heavy_attack_data(weapon_data: WeaponData, effective_charge: float) -> HeavyAttackData:
	var charge_level_tier: int = max(1, int(ceil(effective_charge)))
	var heavy_data: HeavyAttackData = null

	for ha: HeavyAttackData in weapon_data.heavy_attacks:
		if ha.charge_level <= charge_level_tier:
			heavy_data = ha
		else:
			break

	if not heavy_data and weapon_data.heavy_attacks.size() > 0:
		heavy_data = weapon_data.heavy_attacks[0]

	return heavy_data
