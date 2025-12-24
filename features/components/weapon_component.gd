# components/weapon_component.gd
# Weapon component for handling weapon logic
extends Node2D
class_name WeaponComponent

@export var weapon_data: ItemData

# Weapon state
var current_charge: int = 0
var is_charging: bool = false
var charge_start_time: float = 0.0
@export_group("Debug")
@export var current_ammo: int = 0
var is_waiting_for_quiz: bool = false  # Track if this weapon is waiting for quiz completion

# Signals
signal weapon_fired(weapon_data: ItemData, charge_level: int)
signal charge_updated(charge_level: int)
signal ammo_updated(current_ammo: int)

func _ready():
	EventBus.quiz_completed.connect(_on_quiz_completed)
	setup_weapon()

func setup_weapon():
	if weapon_data:
		current_ammo = weapon_data.weapon_data.ammo_capacity
		if has_node("Sprite2D"):
			var sprite = get_node("Sprite2D")
			if weapon_data.icon:
				sprite.texture = weapon_data.icon
				sprite.offset = weapon_data.weapon_data.weapon_offset

func start_charging():
	if not weapon_data or is_charging:
		return
	
	is_charging = true
	charge_start_time = Time.get_ticks_msec()
	current_charge = 0
	_update_charge()

func stop_charging():
	is_charging = false

func fire(effect_node: Node = null, p_target_pos: Vector2 = Vector2.ZERO):
	if not weapon_data:
		return
	
	var target_pos = p_target_pos

	if target_pos == Vector2.ZERO:
		target_pos = get_global_mouse_position()
	var origin_pos = global_position
	
	if weapon_data.weapon_data.weapon_type == WeaponData.WeaponType.MAIN_CANNON:
		if current_charge <= 0:
			return
		if current_ammo <= 0:
			reload()
			return
		# Consume ammo
		current_ammo -= 1
		print("Firing main cannon, ammo left: %d" % current_ammo)
		emit_signal("ammo_updated", current_ammo)
		# Emit fire signal
		emit_signal("weapon_fired", weapon_data, current_charge)
		# Reset charge
		current_charge = 0
		emit_signal("charge_updated", current_charge)
	elif weapon_data.weapon_data.weapon_type == WeaponData.WeaponType.ACTOR_WEAPON:
		if current_ammo <= 0:
			reload()
			return
		# Consume ammo
		print("Firing actor weapon, ammo left: %d" % current_ammo)
		current_ammo -= 1
		emit_signal("ammo_updated", current_ammo)
		# Emit fire signal
		emit_signal("weapon_fired", weapon_data, 1)
	else: # SUB_WEAPON
		# 副炮发射子弹
		emit_signal("weapon_fired", weapon_data, 1)
	
	# Call the weapon_data's fire method, which now just needs the effect_node
	if effect_node:
		weapon_data.weapon_data.fire(origin_pos, target_pos, effect_node)
	else:
		# Fallback if no effect node is provided (though it should be)
		# This might happen for non-vehicle actors, so we create a temporary effect node
		var temp_effect_node = Node2D.new()
		get_tree().current_scene.add_child(temp_effect_node)
		weapon_data.weapon_data.fire(origin_pos, target_pos, temp_effect_node)
		temp_effect_node.queue_free() # Clean up after use

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
	
	if weapon_data.weapon_data.requires_quiz_reload:
		is_waiting_for_quiz = true  # Mark this weapon as waiting
		EventBus.request_quiz_reload.emit(weapon_data)
	else:
		current_ammo = weapon_data.weapon_data.ammo_capacity
		emit_signal("ammo_updated", current_ammo)

func _on_quiz_completed(success: bool):
	# Only reload if this weapon was waiting for the quiz AND the weapon requires quiz reload
	if success and is_waiting_for_quiz and weapon_data and weapon_data.weapon_data.requires_quiz_reload:
		current_ammo = weapon_data.weapon_data.ammo_capacity
		emit_signal("ammo_updated", current_ammo)
		is_waiting_for_quiz = false  # Reset the flag
	elif not success and is_waiting_for_quiz:
		is_waiting_for_quiz = false  # Reset the flag even on failure
