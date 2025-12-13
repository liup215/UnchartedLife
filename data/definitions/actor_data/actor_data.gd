# actor_data.gd
# A resource that holds all the defining data for an actor.
# This allows for easy creation of new actor types by creating new .tres files.
extends Resource

class_name ActorData

# const AnimationData = preload("res://data/components/animation_data.gd")

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

## The current health pint of the actor's body.
@export var current_health: int = 100

## The collision radius for the actor's physics body.
@export var collision_radius: float = 100.0

## Affects the window size for "Just Frame" judgments.
@export var neural_response_speed: float = 1.0
## Affects vehicle control precision and combo success rate.
@export var muscle_coordination: float = 1.0
## The base movement speed of the actor/vehicle.
@export var base_speed: float = 250.0
@export var current_speed: float = base_speed

@export_group("Weapons")
## The list of weapons this actor can equip.
@export var weapons: Array[ItemData] = []
@export var equipped_weapons: Array[ItemData] = []
@export var weapon_number_limit: int = 1

@export_group("AI Behaviors")
## The list of behaviors that this actor will execute.
@export var behaviors: Array[AIBehaviorData]

@export_group("Bio-Energy Attributes")
@export var max_atp: int = 100
@export var current_atp: float = max_atp

@export var max_glucose: int = 100
@export var current_glucose: float = max_glucose
@export var base_metabolic_rate: float = 0.1 # Glucose per second
@export var atp_consume_rate: float = 1.0
@export var glucose_consume_rate: float = 0.1
@export var atp_production_rate: float = 5.0
@export var atp_conversion_rate: float = 5.0


@export_group("Inventory")
## Configuration for the actor's inventory containers.
## Key: Container Name (String), Value: InventoryData Resource Path (String)
@export var inventory_config: Dictionary[String, InventoryData] = {}

func to_dict() -> Dictionary:
	return {
		"actor_name": actor_name,
		"sprite_scale": sprite_scale,
		"max_hp": max_health,
		"current_health": current_health,
		"collision_radius": collision_radius,
		"base_metabolic_rate": base_metabolic_rate,
		"base_speed": base_speed,
		"current_speed": current_speed,
		"weapons": weapons,
		"max_atp": max_atp,
		"current_atp": current_atp,
		"max_glucose": max_glucose,
		"current_glucose": current_glucose,
		"atp_consume_rate": atp_consume_rate,
		"glucose_consume_rate": glucose_consume_rate,
		"atp_production_rate": atp_production_rate,
		"atp_conversion_rate": atp_conversion_rate
	}

func from_dict(data: Dictionary) -> void:
	actor_name = data.get("actor_name", actor_name)
	sprite_scale = data.get("sprite_scale", sprite_scale)
	max_health = data.get("max_health", max_health)
	current_health = data.get("current_health", current_health)
	collision_radius = data.get("collision_radius", collision_radius)
	base_metabolic_rate = data.get("base_metabolic_rate", base_metabolic_rate)
	base_speed = data.get("base_speed", base_speed)
	weapons = data.get("weapons", weapons)
	max_atp = data.get("max_atp", max_atp)
	current_atp = data.get("current_atp", current_atp)
	max_glucose = data.get("max_glucose", max_glucose)
	current_glucose = data.get("current_glucose", current_glucose)
	atp_consume_rate = data.get("atp_consume_rate", atp_consume_rate)
	glucose_consume_rate = data.get("glucose_consume_rate", glucose_consume_rate)
	atp_production_rate = data.get("atp_production_rate", atp_production_rate)
	atp_conversion_rate = data.get("atp_conversion_rate", atp_conversion_rate)
