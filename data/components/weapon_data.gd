# data/components/weapon_data.gd
# Defines the properties of a vehicle weapon.
extends Resource
class_name WeaponData

enum WeaponType { MAIN_CANNON, SUB_WEAPON }

@export_group("Core Properties")
## The name of the weapon.
@export var weapon_name: String = "50mm Cannon"
## The type of weapon.
@export var weapon_type: WeaponType = WeaponType.MAIN_CANNON
## The weight of the weapon.
@export var weight: float = 150.0
## The energy points required to equip this weapon.
@export var energy_cost: int = 5

@export_group("Combat Stats")
## The base damage of the weapon.
@export var damage: float = 25.0
## The type of damage (e.g., "physical", "fire").
@export var damage_type: String = "physical"
## The rate of fire in rounds per second.
@export var rate_of_fire: float = 1.0
## The maximum ammo capacity.
@export var ammo_capacity: int = 20
