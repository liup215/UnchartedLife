# actor_runtime_state.gd
# Holds all mutable (runtime-only) state for an actor.
# This is NOT a Resource and is never serialized to .tres files.
# It is created at runtime by actor.gd and persisted via save_data()/load_data().
extends RefCounted
class_name ActorRuntimeState

# Health
var max_health: int = 100
var current_health: int = 100

# Speed
var base_speed: float = 250.0
var current_speed: float = 250.0

# Toughness / Poise
var max_toughness: float = 100.0
var current_toughness: float = 100.0
var toughness_recovery_rate: float = 10.0

# ATP (short-term energy)
var max_atp: float = 100.0
var current_atp: float = 100.0

# Glucose (long-term fuel)
var max_glucose: float = 100.0
var current_glucose: float = 100.0

# Metabolic rates
var atp_consume_rate: float = 1.0
var glucose_consume_rate: float = 0.1
var atp_production_rate: float = 5.0
var atp_conversion_rate: float = 5.0

# Equipped weapons (runtime assignment, not template)
var equipped_weapons: Array[ItemData] = []

# Other transient flags
var is_staggered: bool = false

## Initialize all runtime values from a template ActorData.
## Called once in actor._ready() when the actor is first spawned.
func initialize_from_template(data: ActorData) -> void:
	max_health = data.max_health
	current_health = data.max_health
	
	base_speed = data.base_speed
	current_speed = data.base_speed
	
	max_toughness = data.max_toughness
	current_toughness = data.max_toughness
	toughness_recovery_rate = data.toughness_recovery_rate
	
	max_atp = data.max_atp
	current_atp = data.max_atp
	
	max_glucose = data.max_glucose
	current_glucose = data.max_glucose
	
	atp_consume_rate = data.atp_consume_rate
	glucose_consume_rate = data.glucose_consume_rate
	atp_production_rate = data.atp_production_rate
	atp_conversion_rate = data.atp_conversion_rate

## Serialize this runtime state to a plain Dictionary (for SaveManager).
func to_dict() -> Dictionary:
	return {
		"max_health": max_health,
		"current_health": current_health,
		"base_speed": base_speed,
		"current_speed": current_speed,
		"max_toughness": max_toughness,
		"current_toughness": current_toughness,
		"toughness_recovery_rate": toughness_recovery_rate,
		"max_atp": max_atp,
		"current_atp": current_atp,
		"max_glucose": max_glucose,
		"current_glucose": current_glucose,
		"atp_consume_rate": atp_consume_rate,
		"glucose_consume_rate": glucose_consume_rate,
		"atp_production_rate": atp_production_rate,
		"atp_conversion_rate": atp_conversion_rate,
		"equipped_weapons": _serialize_weapons(equipped_weapons),
	}

## Restore runtime state from a Dictionary (loaded by SaveManager).
func from_dict(data: Dictionary) -> void:
	max_health = data.get("max_health", max_health)
	current_health = data.get("current_health", current_health)
	base_speed = data.get("base_speed", base_speed)
	current_speed = data.get("current_speed", current_speed)
	max_toughness = data.get("max_toughness", max_toughness)
	current_toughness = data.get("current_toughness", current_toughness)
	toughness_recovery_rate = data.get("toughness_recovery_rate", toughness_recovery_rate)
	max_atp = data.get("max_atp", max_atp)
	current_atp = data.get("current_atp", current_atp)
	max_glucose = data.get("max_glucose", max_glucose)
	current_glucose = data.get("current_glucose", current_glucose)
	atp_consume_rate = data.get("atp_consume_rate", atp_consume_rate)
	glucose_consume_rate = data.get("glucose_consume_rate", glucose_consume_rate)
	atp_production_rate = data.get("atp_production_rate", atp_production_rate)
	atp_conversion_rate = data.get("atp_conversion_rate", atp_conversion_rate)
	
	var paths = data.get("equipped_weapons", [])
	equipped_weapons = _deserialize_weapons(paths)

func _serialize_weapons(weapons: Array[ItemData]) -> Array[String]:
	var paths: Array[String] = []
	for w in weapons:
		if w and w.resource_path != "":
			paths.append(w.resource_path)
	return paths

func _deserialize_weapons(paths: Array) -> Array[ItemData]:
	var weapons: Array[ItemData] = []
	for p in paths:
		var loaded = load(p)
		if loaded is ItemData:
			weapons.append(loaded)
	return weapons
