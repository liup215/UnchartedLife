# charge_component.gd
# Component for managing combat charge accumulation
extends Node
class_name ChargeComponent

## Current charge level (0-max_charge)
var current_charge: int = 0

## Maximum charge that can be accumulated
@export var max_charge: int = 5

## Whether charge is currently building from holding heavy attack
var is_charging_heavy: bool = false

## Time when heavy attack charge started
var charge_start_time: float = 0.0

## Charge time per level for heavy attacks (seconds)
@export var charge_time_per_level: float = 0.5

## Whether light attacks can accumulate charge
@export var light_attacks_build_charge: bool = true

# Signals
signal charge_changed(current: int, max: int)
signal charge_level_up(level: int)
signal charge_max_reached()

func _ready():
	current_charge = 0

func _process(delta: float):
	if is_charging_heavy:
		_update_heavy_charge()

## Start charging for heavy attack
func start_heavy_charge():
	if not is_charging_heavy:
		is_charging_heavy = true
		charge_start_time = Time.get_ticks_msec() / 1000.0
		print("[CHARGE] Started heavy attack charging")

## Stop charging and return the current charge level
func stop_heavy_charge() -> int:
	is_charging_heavy = false
	var charge_to_release = current_charge
	print("[CHARGE] Released heavy attack with charge level: ", charge_to_release)
	return charge_to_release

## Update charge level based on time held
func _update_heavy_charge():
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
	var new_charge = int(elapsed_time / charge_time_per_level)
	new_charge = clamp(new_charge, 0, max_charge)
	
	if new_charge != current_charge:
		var old_charge = current_charge
		current_charge = new_charge
		charge_changed.emit(current_charge, max_charge)
		charge_level_up.emit(current_charge)
		print("[CHARGE] Heavy charge increased: ", old_charge, " -> ", current_charge)
		
		if current_charge >= max_charge:
			charge_max_reached.emit()

## Add charge from light attack hit
func add_light_attack_charge(amount: int = 1):
	if not light_attacks_build_charge:
		return
	
	var old_charge = current_charge
	current_charge = clamp(current_charge + amount, 0, max_charge)
	
	if current_charge != old_charge:
		charge_changed.emit(current_charge, max_charge)
		print("[CHARGE] Light attack charge accumulated: ", old_charge, " -> ", current_charge)
		
		if current_charge >= max_charge:
			charge_max_reached.emit()

## Reset charge to zero (after heavy attack release)
func reset_charge():
	if current_charge > 0:
		current_charge = 0
		charge_changed.emit(current_charge, max_charge)
		print("[CHARGE] Charge reset to 0")

## Get current charge level
func get_current_charge() -> int:
	return current_charge

## Get max charge
func get_max_charge() -> int:
	return max_charge

## Set max charge (when weapon changes)
func set_max_charge(new_max: int):
	max_charge = new_max
	current_charge = clamp(current_charge, 0, max_charge)
	charge_changed.emit(current_charge, max_charge)

## Set charge time per level
func set_charge_time_per_level(time: float):
	charge_time_per_level = time
