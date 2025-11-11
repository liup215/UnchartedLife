# vehicle_data.gd
# Defines the core chassis of a vehicle. It acts as a container for various components
# and holds the vehicle's base stats, level, and upgrade potential.
extends Resource
class_name VehicleData

# --- Core Identity & Base Stats ---
@export_group("Core Properties")
## The unique name of this vehicle chassis.
@export var vehicle_name: String = "Default Chassis"
## A description of the chassis.
@export_multiline var description: String = "A standard-issue vehicle chassis."
## The base weight of the empty chassis.
@export var base_weight: float = 1000.0
## The base defense value of the chassis.
@export var base_defense: int = 10
## Base resistances of the chassis.
@export var base_resistances: Dictionary = {"fire": 0.0, "electric": 0.0, "acid": 0.0}

# --- Upgrade & Progression ---
@export_group("Upgrades & Progression")
## The current level of the vehicle.
@export var level: int = 1
## The current experience points.
@export var experience: int = 0
## Energy points used to equip powerful components or unlock skills.
@export var energy_points: int = 10

@export_group("Weapons")
## The list of weapons this actor can equip.
@export var weapons: Array[WeaponData] = []

# --- Component Slots ---
# These arrays will hold the actual Resource files for each component.
@export_group("Component Slots")
## Array for EngineData resources. Can be expanded via upgrades.
@export var engine_slots: Array[Resource] = []
## Array for main cannon WeaponData resources.
@export var main_cannon_slots: Array[Resource] = []
## Array for sub-weapon WeaponData resources.
@export var sub_weapon_slots: Array[Resource] = []
## Array for SpecialEquipmentData (SE) resources.
@export var se_slots: Array[Resource] = []

# --- Skills ---
@export_group("Skills")
## Array for unlocked VehicleSkillData resources.
@export var skills: Array[Resource] = []

# --- Visuals ---
@export_group("Visuals")
## The scene file (.tscn) for this vehicle's visual representation.
@export var scene: PackedScene
