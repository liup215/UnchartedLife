# actor_data.gd
# A resource that holds all the defining data for an actor.
# This allows for easy creation of new actor types by creating new .tres files.
extends Resource

class_name ActorData

# This import is handled via class_name in the target script
# const AnimationData = preload("res://data/components/animation_data.gd")
const StatDefinition = preload("res://data/definitions/stat/stat_definition.gd")

# --- Player Character Stats ---
@export_group("Identity")
## The name of the actor.
@export var actor_name: String = "Unknown Actor"

@export_group("Visuals")
## The list of animations for this actor.
@export var animations: Array[AnimationData]
## The scale of the actor's sprite.
@export var sprite_scale: Vector2 = Vector2.ONE

@export_group("Base Physiological Indicators")
## The maximum health points of the actor's body.
@export var max_health: int = 100


## The collision radius for the actor's physics body.
@export var collision_radius: float = 100.0

## Affects the window size for "Just Frame" judgments.
@export var neural_response_speed: float = 1.0
## Affects vehicle control precision and combo success rate.
@export var muscle_coordination: float = 1.0
## The base movement speed of the actor/vehicle.
@export var base_speed: float = 250.0

@export_group("Weapons")
## The weapons this actor has equipped by default when spawned.
@export var equipped_weapons: Array[ItemData] = []
@export var weapon_number_limit: int = 1

@export_group("AI Behaviors")
## The list of behaviors that this actor will execute.
@export var behaviors: Array[AIBehaviorData]

@export_group("Combat Attributes")
## Base attack power (affects all damage output)
@export var base_attack: float = 10.0
## Base defense value (reduces incoming damage)
@export var base_defense: float = 5.0
## Maximum toughness/poise (resistance to being staggered)
@export var max_toughness: float = 100.0
## Toughness recovery rate per second
@export var toughness_recovery_rate: float = 10.0

@export_group("Bio-Energy Attributes")
@export var max_atp: int = 100

@export var max_glucose: int = 100
@export var base_metabolic_rate: float = 0.1 # Glucose per second
@export var atp_consume_rate: float = 1.0
@export var glucose_consume_rate: float = 0.1
@export var atp_production_rate: float = 5.0
@export var atp_conversion_rate: float = 5.0


@export_group("Inventory")
## Configuration for the actor's inventory containers.
## Key: Container Name (String), Value: InventoryData Resource Path (String)
@export var inventory_config: Dictionary[String, InventoryData] = {}

## Generate stat definitions from this actor data for the new StatSystem.
## This bridges the old Resource-driven approach to the new ECS-lite stat system.
func create_stat_sheet() -> Array:
	var stats: Array = []
	
	# --- Resource Pools (stats with current/max pairs) ---
	var health := StatDefinition.new()
	health.stat_id = "health"
	health.base_value = max_health
	health.min_value = 0.0
	health.max_value = max_health
	health.is_resource_pool = true
	health.description = "Current health points"
	stats.append(health)
	
	var max_hp := StatDefinition.new()
	max_hp.stat_id = "max_health"
	max_hp.base_value = max_health
	max_hp.min_value = 1.0
	stats.append(max_hp)
	
	var atp := StatDefinition.new()
	atp.stat_id = "atp"
	atp.base_value = max_atp
	atp.min_value = 0.0
	atp.max_value = max_atp
	atp.is_resource_pool = true
	stats.append(atp)
	
	var max_atp_def := StatDefinition.new()
	max_atp_def.stat_id = "max_atp"
	max_atp_def.base_value = max_atp
	max_atp_def.min_value = 1.0
	stats.append(max_atp_def)
	
	var glucose := StatDefinition.new()
	glucose.stat_id = "glucose"
	glucose.base_value = max_glucose
	glucose.min_value = 0.0
	glucose.max_value = max_glucose
	glucose.is_resource_pool = true
	stats.append(glucose)
	
	var max_glucose_def := StatDefinition.new()
	max_glucose_def.stat_id = "max_glucose"
	max_glucose_def.base_value = max_glucose
	max_glucose_def.min_value = 1.0
	stats.append(max_glucose_def)
	
	var toughness := StatDefinition.new()
	toughness.stat_id = "toughness"
	toughness.base_value = max_toughness
	toughness.min_value = 0.0
	toughness.max_value = max_toughness
	toughness.is_resource_pool = true
	stats.append(toughness)
	
	var max_toughness_def := StatDefinition.new()
	max_toughness_def.stat_id = "max_toughness"
	max_toughness_def.base_value = max_toughness
	max_toughness_def.min_value = 1.0
	stats.append(max_toughness_def)
	
	# --- Non-pool stats ---
	var speed := StatDefinition.new()
	speed.stat_id = "speed"
	speed.base_value = base_speed
	speed.min_value = 0.0
	stats.append(speed)
	
	var attack := StatDefinition.new()
	attack.stat_id = "base_attack"
	attack.base_value = base_attack
	stats.append(attack)
	
	var defense := StatDefinition.new()
	defense.stat_id = "base_defense"
	defense.base_value = base_defense
	stats.append(defense)
	
	var neural := StatDefinition.new()
	neural.stat_id = "neural_response_speed"
	neural.base_value = neural_response_speed
	stats.append(neural)
	
	var muscle := StatDefinition.new()
	muscle.stat_id = "muscle_coordination"
	muscle.base_value = muscle_coordination
	stats.append(muscle)
	
	var collision := StatDefinition.new()
	collision.stat_id = "collision_radius"
	collision.base_value = collision_radius
	stats.append(collision)
	
	# --- Metabolic configuration stats (not pools, but config values) ---
	var atp_consume := StatDefinition.new()
	atp_consume.stat_id = "atp_consume_rate"
	atp_consume.base_value = atp_consume_rate
	stats.append(atp_consume)
	
	var glucose_consume := StatDefinition.new()
	glucose_consume.stat_id = "glucose_consume_rate"
	glucose_consume.base_value = glucose_consume_rate
	stats.append(glucose_consume)
	
	var atp_produce := StatDefinition.new()
	atp_produce.stat_id = "atp_production_rate"
	atp_produce.base_value = atp_production_rate
	stats.append(atp_produce)
	
	var atp_conv := StatDefinition.new()
	atp_conv.stat_id = "atp_conversion_rate"
	atp_conv.base_value = atp_conversion_rate
	stats.append(atp_conv)
	
	return stats

# Template serialization (runtime fields are managed by ActorRuntimeState)
func to_dict() -> Dictionary:
	var animations_paths: Array[String] = []
	for anim in animations:
		if anim and anim.resource_path != "":
			animations_paths.append(anim.resource_path)
	
	var equipped_weapons_paths: Array[String] = []
	for weapon in equipped_weapons:
		if weapon and weapon.resource_path != "":
			equipped_weapons_paths.append(weapon.resource_path)
	
	var behaviors_paths: Array[String] = []
	for behavior in behaviors:
		if behavior and behavior.resource_path != "":
			behaviors_paths.append(behavior.resource_path)
	
	var inventory_config_paths: Dictionary[String, String] = {}
	for key in inventory_config.keys():
		var inv_data = inventory_config[key]
		if inv_data and inv_data.resource_path != "":
			inventory_config_paths[key] = inv_data.resource_path
	
	return {
		"actor_name": actor_name,
		"sprite_scale": {"x": sprite_scale.x, "y": sprite_scale.y},
		"max_health": max_health,
		"collision_radius": collision_radius,
		"base_metabolic_rate": base_metabolic_rate,
		"base_speed": base_speed,
		"animations_paths": animations_paths,
		"equipped_weapons_paths": equipped_weapons_paths,
		"behaviors_paths": behaviors_paths,
		"inventory_config_paths": inventory_config_paths,
		"max_atp": max_atp,
		"max_glucose": max_glucose,
		"atp_consume_rate": atp_consume_rate,
		"glucose_consume_rate": glucose_consume_rate,
		"atp_production_rate": atp_production_rate,
		"atp_conversion_rate": atp_conversion_rate,
		"neural_response_speed": neural_response_speed,
		"muscle_coordination": muscle_coordination,
		"weapon_number_limit": weapon_number_limit,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"max_toughness": max_toughness,
		"toughness_recovery_rate": toughness_recovery_rate,
	}

func from_dict(data: Dictionary) -> void:
	actor_name = data.get("actor_name", actor_name)
	
	if data.has("sprite_scale"):
		var scale_data = data["sprite_scale"]
		if typeof(scale_data) == TYPE_DICTIONARY:
			sprite_scale = Vector2(scale_data.get("x", 1.0), scale_data.get("y", 1.0))
		else:
			sprite_scale = scale_data
	
	max_health = data.get("max_health", max_health)
	collision_radius = data.get("collision_radius", collision_radius)
	base_metabolic_rate = data.get("base_metabolic_rate", base_metabolic_rate)
	base_speed = data.get("base_speed", base_speed)
	
	# Deserialize animations
	if data.has("animations_paths"):
		animations.clear()
		for path in data["animations_paths"]:
			var anim = load(path)
			if anim:
				animations.append(anim)
	
	# Deserialize equipped weapons
	if data.has("equipped_weapons_paths"):
		equipped_weapons.clear()
		for path in data["equipped_weapons_paths"]:
			var weapon = load(path)
			if weapon:
				equipped_weapons.append(weapon)
	# Legacy alias support (if old save still has weapons_paths)
	elif data.has("weapons_paths"):
		equipped_weapons.clear()
		for path in data["weapons_paths"]:
			var weapon = load(path)
			if weapon:
				equipped_weapons.append(weapon)
	
	# Deserialize behaviors
	if data.has("behaviors_paths"):
		behaviors.clear()
		for path in data["behaviors_paths"]:
			var behavior = load(path)
			if behavior:
				behaviors.append(behavior)
	
	# Deserialize inventory_config
	if data.has("inventory_config_paths"):
		inventory_config.clear()
		for key in data["inventory_config_paths"].keys():
			var path = data["inventory_config_paths"][key]
			var inv_data = load(path)
			if inv_data:
				inventory_config[key] = inv_data
	
	max_atp = data.get("max_atp", max_atp)
	max_glucose = data.get("max_glucose", max_glucose)
	atp_consume_rate = data.get("atp_consume_rate", atp_consume_rate)
	glucose_consume_rate = data.get("glucose_consume_rate", glucose_consume_rate)
	atp_production_rate = data.get("atp_production_rate", atp_production_rate)
	atp_conversion_rate = data.get("atp_conversion_rate", atp_conversion_rate)
	neural_response_speed = data.get("neural_response_speed", neural_response_speed)
	muscle_coordination = data.get("muscle_coordination", muscle_coordination)
	weapon_number_limit = data.get("weapon_number_limit", weapon_number_limit)
	base_attack = data.get("base_attack", base_attack)
	base_defense = data.get("base_defense", base_defense)
	max_toughness = data.get("max_toughness", max_toughness)
	toughness_recovery_rate = data.get("toughness_recovery_rate", toughness_recovery_rate)
