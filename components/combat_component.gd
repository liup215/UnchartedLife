# components/combat_component.gd
# Main combat system component
extends Node
class_name CombatComponent

@export var owner_node: Node  # Reference to the owning actor/vehicle
@export var max_main_weapons: int = 5
@export var max_secondary_weapons: int = 5

# Weapon arrays
var main_weapons: Array = []
var secondary_weapons: Array = []

# Combat state
var is_main_charging: bool = false
var combo_counter: int = 0
var last_combo_time: float = 0.0
var combo_reset_time: float = 5.0  # Time window to continue combo

# ATP component reference
var atp_component: Node = null

# Signals
signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)

func _ready():
	# Find ATP component in owner
	if owner_node:
		atp_component = owner_node.get_node("ATPComponent") if owner_node.has_node("ATPComponent") else null

func add_main_weapon(weapon_component) -> bool:
	if main_weapons.size() >= max_main_weapons:
		return false
	main_weapons.append(weapon_component)
	_connect_weapon_signals(weapon_component)
	return true

func add_secondary_weapon(weapon_component) -> bool:
	if secondary_weapons.size() >= max_secondary_weapons:
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
	
	if max_charge <= 0:
		return
	
	# Calculate total ATP cost
	var total_atp_cost = 0.0
	for weapon in main_weapons:
		if weapon:
			total_atp_cost += weapon.get_atp_cost()
	
	# Check if we have enough ATP
	if atp_component and atp_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy
	
	# Consume ATP
	if atp_component:
		atp_component.consume_atp(total_atp_cost)
	
	# Fire weapons that match the max charge level
	var fired_count = 0
	for weapon in main_weapons:
		if weapon and weapon.current_charge == max_charge:
			weapon.fire()
			fired_count += 1
	
	# Emit signal
	emit_signal("weapons_fired", "main", fired_count, max_charge)
	emit_signal("combat_action_performed", "main_fire", total_atp_cost)

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
	if atp_component and atp_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy
	
	# Consume ATP
	if atp_component:
		atp_component.consume_atp(total_atp_cost)
	
	# Fire the weapons

	for i in range(weapons_to_fire):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			secondary_weapons[i].fire()
	
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
			total_damage += weapon.weapon_data.damage * weapon.get_damage_multiplier()
	return total_damage

func get_total_secondary_weapon_damage() -> float:
	var total_damage = 0.0
	var weapons_to_count = min(combo_counter, secondary_weapons.size())
	weapons_to_count = max(weapons_to_count, 3)
	
	for i in range(weapons_to_count):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			total_damage += secondary_weapons[i].weapon_data.damage
	return total_damage

func reload_all_weapons():
	for weapon in main_weapons:
		if weapon:
			weapon.reload()
	for weapon in secondary_weapons:
		if weapon:
			weapon.reload()
