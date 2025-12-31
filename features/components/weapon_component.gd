# components/weapon_component.gd
# Weapon component for handling weapon logic
extends Node2D
class_name WeaponComponent

@export var item_data: ItemData

# Weapon state
var current_charge: int = 0
var is_charging: bool = false
var charge_start_time: float = 0.0
@export_group("Debug")
@export var current_ammo: int = 0

# Signals
signal weapon_fired(item_data: ItemData, charge_level: int)
signal charge_updated(charge_level: int)
signal ammo_updated(current_ammo: int)

func _ready():
	EventBus.quiz_completed.connect(_on_quiz_completed)
	setup_weapon()

func setup_weapon():
	if item_data:
		print("Setting up weapon: %s" % item_data.item_name)
		print("Weapon ammo capacity: %d" % item_data.weapon_data.ammo_capacity)
		current_ammo = item_data.weapon_data.ammo_capacity
		if has_node("Sprite2D"):
			var sprite = get_node("Sprite2D")
			if item_data.icon:
				sprite.texture = item_data.icon
				sprite.offset = item_data.weapon_data.weapon_offset

func start_charging():
	if not item_data or is_charging:
		return
	
	is_charging = true
	charge_start_time = Time.get_ticks_msec()
	current_charge = 0
	_update_charge()

func stop_charging():
	is_charging = false

func fire(effect_node: Node = null, p_target_pos: Vector2 = Vector2.ZERO):
	if not item_data:
		return
	
	var target_pos = p_target_pos

	if target_pos == Vector2.ZERO:
		target_pos = get_global_mouse_position()
	var origin_pos = global_position
	
	# Get shooter reference (parent actor)
	var shooter = get_parent().get_parent() if get_parent() and get_parent().get_parent() else null
	
	if item_data.weapon_data.weapon_type == WeaponData.WeaponType.MAIN_CANNON:
		# Allow firing at any charge level (including 0)
		# Damage will scale with charge level
		if current_ammo <= 0:
			print("Out of ammo! Cannot fire.")
			return
		# Consume ammo
		current_ammo -= 1
		print("Firing main cannon at charge %d, ammo left: %d" % [current_charge, current_ammo])
		emit_signal("ammo_updated", current_ammo)
		# Emit fire signal
		emit_signal("weapon_fired", item_data, current_charge)
		# Reset charge after firing
		current_charge = 0
		emit_signal("charge_updated", current_charge)
	elif item_data.weapon_data.weapon_type == WeaponData.WeaponType.ACTOR_WEAPON:
		if current_ammo <= 0:
			print("Out of ammo! Cannot fire.")
			return
		# Consume ammo
		print("Firing actor weapon, ammo left: %d" % current_ammo)
		current_ammo -= 1
		emit_signal("ammo_updated", current_ammo)
		# Emit fire signal
		emit_signal("weapon_fired", item_data, 1)
	else: # SUB_WEAPON
		# 副炮发射子弹
		emit_signal("weapon_fired", item_data, 1)
	
	# Call the weapon_data's fire method, passing shooter reference
	if effect_node:
		item_data.weapon_data.fire(origin_pos, target_pos, effect_node, shooter)
	else:
		# Fallback if no effect node is provided (though it should be)
		# This might happen for non-vehicle actors, so we create a temporary effect node
		var temp_effect_node = Node2D.new()
		get_tree().current_scene.add_child(temp_effect_node)
		item_data.weapon_data.fire(origin_pos, target_pos, temp_effect_node, shooter)
		temp_effect_node.queue_free() # Clean up after use

func _process(_delta):
	if is_charging and item_data:
		_update_charge()

func _update_charge():
	if not item_data:
		return
	
	var elapsed_time = (Time.get_ticks_msec() - charge_start_time) / 1000.0
	var charge_progress = elapsed_time / item_data.weapon_data.charge_time
	
	# Calculate charge level (1-5)
	var new_charge = int(charge_progress * 5) + 1
	new_charge = clamp(new_charge, 1, item_data.weapon_data.max_charge_level)
	
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
	if not item_data:
		return 0.0
	return item_data.weapon_data.atp_cost_per_level * current_charge

func reload():
	if not item_data:
		return
	
	if item_data.weapon_data.requires_quiz_reload:
		EventBus.request_quiz_reload.emit(item_data)
	else:
		current_ammo = item_data.weapon_data.ammo_capacity
		emit_signal("ammo_updated", current_ammo)

func _on_quiz_completed(success: bool):
	if success and item_data and item_data.weapon_data.requires_quiz_reload:
		current_ammo = item_data.weapon_data.ammo_capacity
