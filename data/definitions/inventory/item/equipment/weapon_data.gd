# data/components/weapon_data.gd
# Defines the properties of a vehicle weapon.
extends Resource
class_name WeaponData

enum WeaponType { MAIN_CANNON, SUB_WEAPON, ACTOR_WEAPON }
enum DamageType { PHYSICAL, FIRE, ICE, ELECTRIC, EXPLOSIVE }

# @export_group("Core Properties")
# ## The texture for the weapon's sprite.
# @export var weapon_texture: Texture2D
 ## The positional offset for the weapon's sprite.
@export var weapon_offset: Vector2 = Vector2.ZERO
# ## The name of the weapon.
# @export var weapon_name: String = "50mm Cannon"
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
## Whether this weapon requires a quiz to reload.
@export var requires_quiz_reload: bool = false

@export_group("Charge Properties")
## Maximum charge level for this weapon (1-5)
@export_range(1, 5) var max_charge_level: int = 1
## Time to reach full charge (in seconds)
@export var charge_time: float = 2.0
## ATP cost per charge level
@export var atp_cost_per_level: float = 10.0

@export_group("Visual & Audio Effects")
## The sound played when the weapon is fired.
@export var fire_sound: AudioStream
## The muzzle flash effect scene to instantiate.
@export var muzzle_flash_effect: PackedScene

@export_group("Projectile Properties")
## The scene for the projectile. Should be base_bullet.tscn
@export var bullet_scene: PackedScene
## The speed of the projectile in pixels per second.
@export var bullet_speed: float = 800.0
## The lifetime of the projectile in seconds.
@export var bullet_lifetime: float = 2.0
## The texture for the projectile's sprite.
@export var bullet_texture: Texture2D
## The scale of the projectile's sprite.
@export var bullet_scale: Vector2 = Vector2.ONE

@export_group("Hit Effect Properties")
## The texture for the hit effect (e.g., an explosion spritesheet).
@export var hit_effect_texture: Texture2D
## The scale of the hit effect sprite.
@export var hit_effect_scale: Vector2 = Vector2.ONE
## Horizontal frames in the hit effect spritesheet.
@export var hit_effect_h_frames: int = 1
## Vertical frames in the hit effect spritesheet.
@export var hit_effect_v_frames: int = 1
## Total number of frames in the hit effect animation.
@export var hit_effect_frame_count: int = 1
## The duration of the hit effect animation in seconds.
@export var hit_effect_duration: float = 0.5

@export_group("Combo System")
## Array of combo stages for light attacks
@export var combo_attacks: Array[ComboAttackData] = []
## Maximum combo count (derived from combo_attacks size if not set)
@export var max_combo_count: int = 3

@export_group("Heavy Attack System")
## Array of heavy attack configurations for different charge levels
@export var heavy_attacks: Array[HeavyAttackData] = []
## Time to charge one level (seconds)
@export var charge_time_per_level: float = 0.5
## Whether light attack hits accumulate charge
@export var light_attacks_build_charge: bool = true

func fire(origin: Vector2, target: Vector2, effect_node: Node = null, shooter: Node = null):
	if not effect_node:
		return

	# Directly use the passed-in effect_node
	if effect_node and effect_node.has_method("fire"):
		# Pass all necessary parameters including shooter to the effect
		effect_node.fire(origin, target, self, shooter)
