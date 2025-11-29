# components/vehicle_stats_component.gd
# This component calculates a vehicle's final, real-time stats based on its
# chassis data and all equipped components.
extends Node
class_name VehicleStatsComponent

## The core data resource for the vehicle chassis.
@export var vehicle_data: VehicleData

# --- Calculated Live Stats ---
# These are the final stats after all calculations.
var can_move: bool = true
var total_weight: float = 0.0
var total_max_load: float = 0.0
var total_power_output: float = 0.0
var final_max_speed: float = 0.0
var final_acceleration: float = 0.0
var final_defense: int = 0
var final_resistances: Dictionary = {}

func _ready():
	if vehicle_data:
		recalculate_stats()

## Recalculates all vehicle stats. Call this whenever equipment changes.
func recalculate_stats():
	if not vehicle_data:
		return

	# --- Reset and Start with Base Stats ---
	total_weight = vehicle_data.base_weight
	total_max_load = 0.0
	total_power_output = 0.0
	final_defense = vehicle_data.base_defense
	final_resistances = vehicle_data.base_resistances.duplicate(true)

	# --- Process Engines ---
	for engine_res in vehicle_data.engine_slots:
		if engine_res is EngineData:
			var engine: EngineData = engine_res
			total_weight += engine.weight
			total_max_load += engine.max_load
			total_power_output += engine.power_output

	# --- Process Weapons and Special Equipment ---
	var all_equipment = []
	all_equipment.append_array(vehicle_data.main_cannon_slots)
	all_equipment.append_array(vehicle_data.sub_weapon_slots)
	all_equipment.append_array(vehicle_data.se_slots)

	for item_res in all_equipment:
		if item_res is SpecialEquipmentData:
			var item: SpecialEquipmentData = item_res
			total_weight += item.weight
			
			if item is ArmorData:
				var armor: ArmorData = item
				final_defense += armor.defense_bonus
				for key in armor.resistance_bonuses:
					final_resistances[key] = final_resistances.get(key, 0.0) + armor.resistance_bonuses[key]

	# --- Final Calculations & Checks ---
	# Check if the vehicle is overloaded.
	can_move = total_weight <= total_max_load

	# Calculate speed based on power-to-weight ratio.
	if can_move and total_weight > 0:
		# These formulas are placeholders and can be tuned for game balance.
		var power_to_weight_ratio = total_power_output / total_weight
		final_max_speed = power_to_weight_ratio * 500.0 # Tuning factor
		final_acceleration = power_to_weight_ratio * 5000.0 # Tuning factor
	else:
		final_max_speed = 0
		final_acceleration = 0
