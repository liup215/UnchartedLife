# components/weapon_component.gd
# Weapon component for handling weapon logic
extends Node2D
class_name WeaponComponent

@export var weapon_data: WeaponData

# Weapon state
var current_charge: int = 0
var is_charging: bool = false
var charge_start_time: float = 0.0
var current_ammo: int = 0

# Signals
signal weapon_fired(weapon_data: WeaponData, charge_level: int)
signal charge_updated(charge_level: int)
signal ammo_updated(current_ammo: int)

func _ready():
	if weapon_data:
		current_ammo = weapon_data.ammo_capacity

func start_charging():
	if not weapon_data or is_charging:
		return

	is_charging = true
	charge_start_time = Time.get_ticks_msec()
	current_charge = 0
	_update_charge()

func stop_charging():
	is_charging = false

func fire(effect_node: Node = null):
	if not weapon_data:
		return

	var target_pos = get_global_mouse_position()
	var origin_pos = global_position

	if weapon_data.weapon_type == WeaponData.WeaponType.MAIN_CANNON:
		if current_charge <= 0 or current_ammo <= 0:
			return
		# Consume ammo
		current_ammo -= 1
		emit_signal("ammo_updated", current_ammo)
		# Emit fire signal
		emit_signal("weapon_fired", weapon_data, current_charge)
		# Reset charge
		current_charge = 0
		emit_signal("charge_updated", current_charge)
	else: # SUB_WEAPON
	# 副炮发射子弹
		emit_signal("weapon_fired", weapon_data, 1)

	# 统一调用 weapon_data.fire
	if effect_node:
		weapon_data.fire(origin_pos, target_pos, effect_node)
	else:
	# Fallback if no effect node is provided (though it should be)
		weapon_data.fire(origin_pos, target_pos, get_tree().current_scene)

func _process(_delta):
	if is_charging and weapon_data:
		_update_charge()

func _update_charge():
	if not weapon_data:
		return
		
	var elapsed_time = (Time.get_ticks_msec() - charge_start_time) / 1000.0
	var charge_progress = elapsed_time / weapon_data.charge_time
	
	# Calculate charge level (1-5)
	var new_charge = int(charge_progress * 5) + 1
	new_charge = clamp(new_charge, 1, weapon_data.max_charge_level)
	
	if new_charge != current_charge:
		current_charge = new_charge
		emit_signal("charge_updated", current_charge)

func get_damage_multiplier() -> float:
	# Damage multiplier based on charge level
	match current_charge:
		1: return 1.0
		2: return 1.5
		3: return 2.0
		4: return 2.5
		5: return 3.0
		_: return 1.0

func get_atp_cost() -> float:
	if not weapon_data:
		return 0.0
	return weapon_data.atp_cost_per_level * current_charge

func reload():
	if not weapon_data:
		return
	current_ammo = weapon_data.ammo_capacity
	emit_signal("ammo_updated", current_ammo)
