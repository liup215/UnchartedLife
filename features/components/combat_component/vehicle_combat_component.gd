# components/combat_component.gd
# Main combat system component
extends Node2D
class_name VehicleCombatComponent

@export var data_source: VehicleData = null

# Resolved at runtime in _ready() — do NOT initialize from get_parent() here
# (GDScript runs member initializers before _ready(), when tree may be unstable)
var vehicle: Vehicle = null

# Cached reference to the driver actor's attribute component
var actor_attribute_component: AttributeComponent = null

# Weapon arrays
var main_weapons: Array[WeaponComponent] = []
var secondary_weapons: Array[WeaponComponent] = []
var actor_weapons: Array[WeaponComponent] = []

# Combat state
var is_main_charging: bool = false
var combo_counter: int = 0
var last_combo_time: float = 0.0
var combo_reset_time: float = 0.5  # Time window to continue combo

# Weapon effect handler
@onready var weapon_effect: BaseWeaponEffect = $BaseWeaponEffect

# Signals
signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)

func _ready():
	vehicle = get_parent() as Vehicle
	_update_actor_attribute_component()

func set_actor_data(data: VehicleData):
	data_source = data
	# Load weapons from data
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
		_disconnect_weapon_signals(weapon_component)
		main_weapons.remove_at(result)
		return true
	return false

func remove_secondary_weapon(weapon_component) -> bool:
	var result = secondary_weapons.find(weapon_component)
	if result != -1:
		_disconnect_weapon_signals(weapon_component)
		secondary_weapons.remove_at(result)
		return true
	return false

func remove_actor_weapon(weapon_component) -> bool:
	var result = actor_weapons.find(weapon_component)
	if result != -1:
		_disconnect_weapon_signals(weapon_component)
		actor_weapons.remove_at(result)
		return true
	return false

func _connect_weapon_signals(weapon_component) -> void:
	if weapon_component and weapon_component.has_signal("weapon_fired"):
		weapon_component.weapon_fired.connect(_on_weapon_fired)
	if weapon_component and weapon_component.has_signal("charge_updated"):
		weapon_component.charge_updated.connect(_on_weapon_charge_updated)
	if weapon_component and weapon_component.has_signal("ammo_updated"):
		weapon_component.ammo_updated.connect(_on_weapon_ammo_updated)

func _disconnect_weapon_signals(weapon_component) -> void:
	if not weapon_component:
		return
	if weapon_component.has_signal("weapon_fired") and weapon_component.weapon_fired.is_connected(_on_weapon_fired):
		weapon_component.weapon_fired.disconnect(_on_weapon_fired)
	if weapon_component.has_signal("charge_updated") and weapon_component.charge_updated.is_connected(_on_weapon_charge_updated):
		weapon_component.charge_updated.disconnect(_on_weapon_charge_updated)
	if weapon_component.has_signal("ammo_updated") and weapon_component.ammo_updated.is_connected(_on_weapon_ammo_updated):
		weapon_component.ammo_updated.disconnect(_on_weapon_ammo_updated)

func _on_weapon_fired(_weapon_data: WeaponData, _charge_level: int):
	# Handle weapon firing logic
	# You can also emit a signal or update HUD here
	GameLogger.debug("combat", "Weapon fired: %s Charge Level: %d" % [(_weapon_data.weapon_name if _weapon_data else "Unknown Weapon"), _charge_level])

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

	# Check if we have enough ATP via AttributeComponent (abstracts old/new system)
	if actor_attribute_component and actor_attribute_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy

	# Consume ATP via AttributeComponent (abstracts old/new system)
	if actor_attribute_component:
		actor_attribute_component.consume_atp(total_atp_cost)
	# Delegate target position to TargetResolverSystem (Wave 3)
	var target_resolver: TargetResolverSystem = ServiceRegistry.get_service("TargetResolverSystem")
	var target_pos := Vector2.ZERO
	if target_resolver:
		target_pos = target_resolver.get_player_aim_target_world()
	
	# Fire all weapons (not just those matching max charge)
	var fired_count = 0
	for weapon in main_weapons:
		if weapon:
			weapon.fire(weapon_effect, target_pos)
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
	emit_signal("weapons_fired", "actor", actor_weapons.size(), 1)
	emit_signal("combat_action_performed", "actor_attack", 10)

# Light attack state machine (avoids await in physics callbacks)
var _light_attack_active: bool = false
var _light_attack_weapons_to_fire: int = 0
var _light_attack_index: int = 0
var _light_attack_timer: float = 0.0
const LIGHT_ATTACK_INTERVAL: float = 0.2

func _process(delta: float) -> void:
	_process_light_attack(delta)

func _update_actor_attribute_component() -> void:
	if not vehicle:
		return
	if not vehicle.driver:
		return
	var driver = vehicle.driver as Actor
	if driver and driver.attribute_component:
		actor_attribute_component = driver.attribute_component

func _process_light_attack(delta: float) -> void:
	if not _light_attack_active:
		return

	_light_attack_timer -= delta
	if _light_attack_timer > 0.0:
		return

	while _light_attack_index < _light_attack_weapons_to_fire and _light_attack_timer <= 0.0:
		if _light_attack_index < secondary_weapons.size() and secondary_weapons[_light_attack_index]:
			GameLogger.debug("combat", "Firing secondary weapon: %s" % weapon_effect)
			secondary_weapons[_light_attack_index].fire(weapon_effect)

		_light_attack_index += 1

		if _light_attack_index >= _light_attack_weapons_to_fire:
			_light_attack_active = false
			# Reset combo if max reached
			if combo_counter >= secondary_weapons.size():
				reset_combo()
			# Emit signal after all shots fired
			emit_signal("weapons_fired", "secondary", _light_attack_weapons_to_fire, 1)
			emit_signal("combat_action_performed", "light_attack", _light_attack_weapons_to_fire * secondary_weapons[0].get_atp_cost() if secondary_weapons.size() > 0 else 0.0)
			return

		_light_attack_timer = LIGHT_ATTACK_INTERVAL

func perform_light_attack():
	# Update combo counter
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_combo_time > combo_reset_time:
		combo_counter = 0

	combo_counter += 1
	last_combo_time = current_time
	emit_signal("combo_updated", combo_counter)

	# Determine how many secondary weapons to fire based on combo
	var weapons_to_fire: int = min(combo_counter, secondary_weapons.size())

	# Calculate ATP cost
	var total_atp_cost: float = 0.0
	for i in range(weapons_to_fire):
		if i < secondary_weapons.size() and secondary_weapons[i]:
			total_atp_cost += secondary_weapons[i].get_atp_cost()

	# Check if we have enough ATP via AttributeComponent (abstracts old/new system)
	if actor_attribute_component and actor_attribute_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy

	# Consume ATP via AttributeComponent (abstracts old/new system)
	if actor_attribute_component:
		actor_attribute_component.consume_atp(total_atp_cost)

	# Start async light attack sequence in _process
	_light_attack_active = true
	_light_attack_weapons_to_fire = weapons_to_fire
	_light_attack_index = 0
	_light_attack_timer = 0.0

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
