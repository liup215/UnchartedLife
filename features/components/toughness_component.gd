# toughness_component.gd
# Manages toughness/poise system for stagger mechanics
extends Node
class_name ToughnessComponent

## Maximum toughness value
var max_toughness: float = 100.0

## Current toughness value
var current_toughness: float = 100.0

## Toughness recovery rate per second
var toughness_recovery_rate: float = 10.0

## Whether actor is currently staggered
var is_staggered: bool = false

## Duration of stagger state (seconds)
@export var stagger_duration: float = 2.0

## Minimum toughness threshold to trigger stagger (when below this, stagger occurs)
@export var stagger_threshold: float = 0.0

# Signals
signal toughness_changed(current: float, max: float)
signal toughness_broken()
signal stagger_started()
signal stagger_ended()

func _ready():
	pass

func _process(delta: float):
	# Recover toughness over time if not staggered
	if not is_staggered and current_toughness < max_toughness:
		current_toughness = min(max_toughness, current_toughness + toughness_recovery_rate * delta)
		toughness_changed.emit(current_toughness, max_toughness)

## Initialize toughness from ActorData
func set_actor_data(data: ActorData):
	if data:
		max_toughness = data.max_toughness
		current_toughness = data.current_toughness
		toughness_recovery_rate = data.toughness_recovery_rate
		toughness_changed.emit(current_toughness, max_toughness)

## Apply toughness damage
func apply_toughness_damage(damage: float, stagger_power: float = 0.0):
	if is_staggered:
		return  # Already staggered, no additional toughness damage
	
	# Stagger power increases toughness damage
	var toughness_damage = damage * (1.0 + stagger_power / 100.0)
	
	current_toughness -= toughness_damage
	toughness_changed.emit(current_toughness, max_toughness)
	
	print("[TOUGHNESS] Damage: ", toughness_damage, " Current: ", current_toughness, "/", max_toughness)
	
	# Check if toughness is broken
	if current_toughness <= stagger_threshold:
		_trigger_stagger()

## Trigger stagger state
func _trigger_stagger():
	if is_staggered:
		return
	
	is_staggered = true
	current_toughness = 0.0
	
	toughness_broken.emit()
	stagger_started.emit()
	
	print("[TOUGHNESS] Toughness broken! Entering stagger state for ", stagger_duration, "s")
	
	# Create timer for stagger duration
	await get_tree().create_timer(stagger_duration).timeout
	
	_end_stagger()

## End stagger state
func _end_stagger():
	if not is_staggered:
		return
	
	is_staggered = false
	# Restore some toughness when stagger ends
	current_toughness = max_toughness * 0.3  # Restore 30% toughness
	
	stagger_ended.emit()
	toughness_changed.emit(current_toughness, max_toughness)
	
	print("[TOUGHNESS] Stagger ended, toughness restored to ", current_toughness)

## Force reset toughness to max
func reset_toughness():
	current_toughness = max_toughness
	toughness_changed.emit(current_toughness, max_toughness)

## Get current toughness
func get_current_toughness() -> float:
	return current_toughness

## Get max toughness
func get_max_toughness() -> float:
	return max_toughness

## Check if currently staggered
func is_in_stagger() -> bool:
	return is_staggered

## Serialization
func to_dict() -> Dictionary:
	return {
		"max_toughness": max_toughness,
		"current_toughness": current_toughness,
		"toughness_recovery_rate": toughness_recovery_rate,
		"is_staggered": is_staggered
	}

func from_dict(data: Dictionary):
	max_toughness = data.get("max_toughness", max_toughness)
	current_toughness = data.get("current_toughness", current_toughness)
	toughness_recovery_rate = data.get("toughness_recovery_rate", toughness_recovery_rate)
	is_staggered = data.get("is_staggered", false)
	
	# If was staggered when saved, end the stagger on load
	if is_staggered:
		is_staggered = false
		current_toughness = max_toughness * 0.3
