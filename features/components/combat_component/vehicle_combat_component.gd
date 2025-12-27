# components/combat_component.gd
# Main combat system component
extends Node2D
class_name VehicleCombatComponent

# var owner_node = null  # Reference to the owning actor/vehicle, dynamic assignment only
# @export var max_main_weapons: int = 5
# @export var max_secondary_weapons: int = 5
@export var data_source: VehicleData = null

var vehicle: Vehicle = get_parent() if get_parent() and get_parent() is Vehicle else null

var actor_attribute_component = vehicle.driver.get_node("AttributeComponent") if vehicle and vehicle.driver and vehicle.driver.has_node("AttributeComponent") else null

# Weapon arrays
var main_weapons: Array[WeaponComponent] = []
var secondary_weapons: Array[WeaponComponent] = []
var actor_weapons: Array = [] # 新增：用于actor的所有武器

# Combat state
var is_main_charging: bool = false
var combo_counter: int = 0
var last_combo_time: float = 0.0
var combo_reset_time: float = 0.5  # Time window to continue combo

# # ATP component reference
# var atp_component: Node = null

# Weapon effect handler
@onready var weapon_effect: BaseWeaponEffect = $BaseWeaponEffect

# Signals
signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)

func _ready():
	# Find ATP component in owner
	# if owner_node:
	# 	atp_component = owner_node.get_node("ATPComponent") if owner_node.has_node("ATPComponent") else null
	pass

func set_actor_data(data: VehicleData):
	data_source = data
	# 加载武器
	for weapon_name in data.equipped_main_weapons:
		if main_weapons.size() >= data.max_main_weapon:
			break
		var weapon_scene = load(weapon_name)
		if weapon_scene:
			var weapon_instance = weapon_scene.instantiate()
			add_main_weapon(weapon_instance)
	for weapon_name in data.equipped_secondary_weapons:
		if secondary_weapons.size() >= data.max_secondary_weapon:
			break
		var weapon_scene = load(weapon_name)
		if weapon_scene:
			var weapon_instance = weapon_scene.instantiate()
			add_secondary_weapon(weapon_instance)


func add_main_weapon(weapon_component) -> bool:
	if main_weapons.size() >= data_source.max_main_weapon:
		return false
	main_weapons.append(weapon_component)
	_connect_weapon_signals(weapon_component)
	return true

func add_secondary_weapon(weapon_component) -> bool:
	if secondary_weapons.size() >= data_source.max_secondary_weapons:
		return false
	secondary_weapons.append(weapon_component)
	_connect_weapon_signals(weapon_component)
	return true

func remove_main_weapon(weapon_component) -> bool:
	var result = main_weapons.find(weapon_component)
	if result != -1:
		main_weapons.remove_at(result)
		return true
	return false

func remove_secondary_weapon(weapon_component) -> bool:
	var result = secondary_weapons.find(weapon_component)
	if result != -1:
		secondary_weapons.remove_at(result)
		return true
	return false

func remove_actor_weapon(weapon_component) -> bool:
	var result = actor_weapons.find(weapon_component)
	if result != -1:
		actor_weapons.remove_at(result)
		return true
	return false

func _connect_weapon_signals(weapon_component):
	if weapon_component and weapon_component.has_signal("weapon_fired"):
		weapon_component.weapon_fired.connect(_on_weapon_fired)
	if weapon_component and weapon_component.has_signal("charge_updated"):
		weapon_component.charge_updated.connect(_on_weapon_charge_updated)
	if weapon_component and weapon_component.has_signal("ammo_updated"):
		weapon_component.ammo_updated.connect(_on_weapon_ammo_updated)

func _on_weapon_fired(_weapon_data: WeaponData, _charge_level: int):
	# Handle weapon firing logic
	# You can also emit a signal or update HUD here
	print("[COMBAT] Weapon fired:", _weapon_data.weapon_name if _weapon_data else "Unknown Weapon", "Charge Level:", _charge_level)

func _on_weapon_charge_updated(_charge_level: int):
	# Handle charge level updates
	pass

func _on_weapon_ammo_updated(_current_ammo: int):
	# Handle ammo updates
	pass

func start_main_charge():
	if is_main_charging or main_weapons.is_empty():
		return

	is_main_charging = true

	# Start charging all main weapons
	for weapon in main_weapons:
		if weapon:
			weapon.start_charging()

func stop_main_charge():
	if not is_main_charging:
		return

	is_main_charging = false

	# Stop charging all main weapons
	for weapon in main_weapons:
		if weapon:
			weapon.stop_charging()

func fire_main_weapons():
	if main_weapons.is_empty():
		return

	# Get the highest charge level among all weapons
	var max_charge = 0
	for weapon in main_weapons:
		if weapon and weapon.current_charge > max_charge:
			max_charge = weapon.current_charge

	# Allow firing at any charge level (including 0)
	# Damage will scale with charge level

	# Calculate total ATP cost
	var total_atp_cost = 0.0
	for weapon in main_weapons:
		if weapon:
			total_atp_cost += weapon.get_atp_cost()

	# Check if we have enough ATP
	if actor_attribute_component and actor_attribute_component.metabolism_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy

	# Consume ATP
	if actor_attribute_component:
		actor_attribute_component.metabolism_component.consume_atp(total_atp_cost)
	# Fire all weapons (not just those matching max charge)
	var fired_count = 0
	for weapon in main_weapons:
		if weapon:
			weapon.fire(weapon_effect)
			fired_count += 1

	# Emit signal
	emit_signal("weapons_fired", "main", fired_count, max_charge)
	emit_signal("combat_action_performed", "main_fire", total_atp_cost)

func fire_actor_weapons(target_pos: Vector2 = Vector2.ZERO):
	if actor_weapons.is_empty():
		return
	# Fire the weapons
	for weapon in actor_weapons:
		weapon.fire(weapon_effect, target_pos)
		await get_tree().create_timer(0.2).timeout
	# Emit signal
	emit_signal("weapons_fired", "actor", actor_weapons.size(), 1)
	emit_signal("combat_action_performed", "actor_attack", 10)

# func fire_weapon(index: int):
# 	# 发射指定编号actor武器
# 	if index >= 0 and index < actor_weapons.size():
# 		actor_weapons[index].fire()

func perform_light_attack():
	# Update combo counter
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_combo_time > combo_reset_time:
		combo_counter = 0

	combo_counter += 1
	last_combo_time = current_time
	emit_signal("combo_updated", combo_counter)

	# Determine how many secondary weapons to fire based on combo
	var weapons_to_fire = min(combo_counter, secondary_weapons.size())

	# Calculate ATP cost
	var total_atp_cost = 0.0

	for i in range(weapons_to_fire):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			total_atp_cost += secondary_weapons[i].get_atp_cost()

	# Check if we have enough ATP
	if actor_attribute_component and actor_attribute_component.metabolism_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy

	# Consume ATP
	if actor_attribute_component:
		actor_attribute_component.metabolism_component.consume_atp(total_atp_cost)

	# Fire the weapons
	for i in range(weapons_to_fire):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			print("[COMBAT] Firing secondary weapon:", weapon_effect)
			secondary_weapons[i].fire(weapon_effect)
		# Add a short delay between shots
		await get_tree().create_timer(0.2).timeout
	# 如果连击数达到最大值，则重置
	if combo_counter >= secondary_weapons.size():
		reset_combo()

	# Emit signal
	emit_signal("weapons_fired", "secondary", weapons_to_fire, 1)
	emit_signal("combat_action_performed", "light_attack", total_atp_cost)

func reset_combo():
	combo_counter = 0
	emit_signal("combo_updated", combo_counter)

func get_total_main_weapon_damage(charge_level: int) -> float:
	var total_damage = 0.0
	for weapon in main_weapons:
		if weapon and weapon.current_charge == charge_level:
			total_damage += weapon.item_data.weapon_data.damage * weapon.get_damage_multiplier()
	return total_damage

func get_total_actor_weapon_damage() -> float:
	var total_damage = 0.0
	for weapon in actor_weapons:
		if weapon:
			total_damage += weapon.item_data.weapon_data.damage
	return total_damage

func get_total_secondary_weapon_damage() -> float:
	var total_damage = 0.0
	var weapons_to_count = min(combo_counter, secondary_weapons.size())
	weapons_to_count = max(weapons_to_count, 3)

	for i in range(weapons_to_count):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			total_damage += secondary_weapons[i].item_data.weapon_data.damage
	return total_damage

func reload_all_weapons():
	for weapon in main_weapons:
		if weapon:
			weapon.reload()
	for weapon in secondary_weapons:
		if weapon:
			weapon.reload()
	for weapon in actor_weapons:
		if weapon:
			weapon.reload()
