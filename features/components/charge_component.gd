# charge_component.gd
# Component for managing combat charge accumulation
extends Node
class_name ChargeComponent

## Current charge level (0-max_charge)
var current_charge_level: int = 0

## Current progress within the level (0-100)
var current_charge_progress: float = 0.0

## Progress needed to advance one level
@export var progress_per_level: float = 100.0

## Maximum charge levels that can be accumulated
@export var max_charge_level: int = 5

## Whether charge is currently building from holding heavy attack
var is_charging_heavy: bool = false

## Time when heavy attack charge started
var charge_start_time: float = 0.0

## Charge progress increase per second when holding heavy attack
@export var charge_rate_per_second: float = 50.0

## Whether light attacks can accumulate charge
@export var light_attacks_build_charge: bool = true

# Signals
signal charge_changed(level: int, progress: float, max_level: int)
signal charge_level_up(level: int)
signal charge_max_reached()

func _ready():
	current_charge_level = 0
	current_charge_progress = 0.0

func _process(delta: float):
	if is_charging_heavy:
		_update_heavy_charge(delta)

## Start charging for heavy attack
func start_heavy_charge():
	if not is_charging_heavy:
		is_charging_heavy = true
		charge_start_time = Time.get_ticks_msec() / 1000.0
		print("[CHARGE] Started heavy attack charging from level %d (%.1f%%)" % [current_charge_level, current_charge_progress])

## Stop charging and return the current charge level
func stop_heavy_charge() -> int:
	is_charging_heavy = false
	var charge_to_release = current_charge_level
	print("[CHARGE] Released heavy attack with charge level: %d (%.1f%% progress)" % [charge_to_release, current_charge_progress])
	return charge_to_release

## Update charge based on delta time
func _update_heavy_charge(delta: float):
	# Already at max level and max progress - stop charging
	if current_charge_level >= max_charge_level and current_charge_progress >= progress_per_level:
		if current_charge_level == max_charge_level:
			charge_max_reached.emit()
		return
	
	var old_level = current_charge_level
	var old_progress = current_charge_progress
	
	# Increase progress based on charge rate
	current_charge_progress += charge_rate_per_second * delta
	
	# Check if we've completed a level
	while current_charge_progress >= progress_per_level and current_charge_level < max_charge_level:
		current_charge_progress -= progress_per_level
		current_charge_level += 1
		charge_level_up.emit(current_charge_level)
		print("[CHARGE] Level up! Now at level %d" % current_charge_level)
		
		if current_charge_level >= max_charge_level:
			# Cap progress at max for the max level
			current_charge_progress = min(current_charge_progress, progress_per_level)
			charge_max_reached.emit()
			break
	
	# Emit change signal if anything changed
	if old_level != current_charge_level or abs(old_progress - current_charge_progress) > 0.1:
		charge_changed.emit(current_charge_level, current_charge_progress, max_charge_level)

## Add charge from light attack hit (adds progress, not full levels)
func add_light_attack_charge(progress_amount: float = 20.0):
	if not light_attacks_build_charge:
		return
	
	var old_level = current_charge_level
	current_charge_progress += progress_amount
	
	# Check if we leveled up
	while current_charge_progress >= progress_per_level and current_charge_level < max_charge_level:
		current_charge_progress -= progress_per_level
		current_charge_level += 1
		charge_level_up.emit(current_charge_level)
		print("[CHARGE] Light attack level up! Now at level %d" % current_charge_level)
		
		if current_charge_level >= max_charge_level:
			current_charge_progress = min(current_charge_progress, progress_per_level)
			charge_max_reached.emit()
			break
	
	charge_changed.emit(current_charge_level, current_charge_progress, max_charge_level)
	print("[CHARGE] Light attack charge accumulated: level %d -> %d (%.1f%% progress)" % [old_level, current_charge_level, current_charge_progress])

## Reset charge to zero (after heavy attack release)
func reset_charge():
	if current_charge_level > 0 or current_charge_progress > 0:
		current_charge_level = 0
		current_charge_progress = 0.0
		charge_changed.emit(current_charge_level, current_charge_progress, max_charge_level)
		print("[CHARGE] Charge reset to 0")

## Get current charge level
func get_current_charge_level() -> int:
	return current_charge_level

## Get current charge progress within level
func get_current_charge_progress() -> float:
	return current_charge_progress

## Get max charge level
func get_max_charge_level() -> int:
	return max_charge_level

## Set max charge level (when weapon changes)
func set_max_charge_level(new_max: int):
	max_charge_level = new_max
	current_charge_level = clamp(current_charge_level, 0, max_charge_level)
	if current_charge_level >= max_charge_level:
		current_charge_progress = min(current_charge_progress, progress_per_level)
	charge_changed.emit(current_charge_level, current_charge_progress, max_charge_level)

## Set charge rate per second
func set_charge_rate(rate: float):
	charge_rate_per_second = rate

## Backward compatibility - deprecated
func get_current_charge() -> int:
	return current_charge_level

func get_max_charge() -> int:
	return max_charge_level
