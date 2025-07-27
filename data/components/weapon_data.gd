# data/components/weapon_data.gd
# Defines the properties of a vehicle weapon.
extends Resource
class_name WeaponData

enum WeaponType { MAIN_CANNON, SUB_WEAPON }
enum DamageType { PHYSICAL, FIRE, ICE, ELECTRIC, EXPLOSIVE }

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
## The type of damage.
@export var damage_type: DamageType = DamageType.PHYSICAL
## The rate of fire in rounds per second.
@export var rate_of_fire: float = 1.0
## The maximum ammo capacity.
@export var ammo_capacity: int = 20

@export_group("Charge Properties")
## Maximum charge level for this weapon (1-5)
@export_range(1, 5) var max_charge_level: int = 1
## Time to reach full charge (in seconds)
@export var charge_time: float = 2.0
## ATP cost per charge level
@export var atp_cost_per_level: float = 10.0

@export_group("Visual Effects")
## Visual effect resource for this weapon
@export var visual_effect: PackedScene
## Audio effect for firing
@export var fire_sound: AudioStream
