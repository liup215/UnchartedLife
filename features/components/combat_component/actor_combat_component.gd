# components/combat_component.gd
# Main combat system component
extends Node2D
class_name ActorCombatComponent

# var owner_node = null  # Reference to the owning actor/vehicle, dynamic assignment only
# @export var max_main_weapons: int = 5
# @export var max_secondary_weapons: int = 5
@export var data_source: ActorData = null

# Weapon arrays
var actor_weapons: Array[WeaponComponent] = []

# Combat state
var is_main_charging: bool = false
var combo_counter: int = 0
var last_combo_time: float = 0.0
var combo_reset_time: float = 0.5  # Time window to continue combo

# # ATP component reference
# var atp_component: Node = null

# Weapon effect handler
@onready var weapon_effect: BaseWeaponEffect = $BaseWeaponEffect
var attribute_component: AttributeComponent = get_parent().get_node("AttributeComponent") if get_parent() && get_parent().has_node("AttributeComponent") else null

# Signals
signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)

func _ready():
	# Find ATP component in owner
	# if owner_node:
	# 	atp_component = owner_node.get_node("ATPComponent") if owner_node.has_node("ATPComponent") else null
	pass

func set_actor_data(data: ActorData):
	data_source = data
	# 加载武器
	for weapon_data in data.equipped_weapons:
		if actor_weapons.size() >= data.weapon_number_limit:
			break
		var weapon_scene = preload("res://features/components/weapon_component.tscn")
		if weapon_scene:
			var weapon_instance = weapon_scene.instantiate()
			weapon_instance.weapon_data = weapon_data
			weapon_instance.setup_weapon()
			add_child(weapon_instance)
			add_actor_weapon(weapon_instance)

func add_actor_weapon(weapon_component) -> bool:
	actor_weapons.append(weapon_component)
	_connect_weapon_signals(weapon_component)
	return true
func remove_actor_weapon(index: int) -> bool:
	if index >= 0 and index < actor_weapons.size():
		actor_weapons.remove_at(index)
		return true
	return false

func _connect_weapon_signals(weapon_component):
	if weapon_component and weapon_component.has_signal("weapon_fired"):
		weapon_component.weapon_fired.connect(_on_weapon_fired)
	if weapon_component and weapon_component.has_signal("charge_updated"):
		weapon_component.charge_updated.connect(_on_weapon_charge_updated)
	if weapon_component and weapon_component.has_signal("ammo_updated"):
		weapon_component.ammo_updated.connect(_on_weapon_ammo_updated)

func _on_weapon_fired(_weapon_data: ItemData, _charge_level: int):
	# Handle weapon firing logic
	# You can also emit a signal or update HUD here
	print("[COMBAT] Weapon fired:", _weapon_data.item_name if _weapon_data else "Unknown Weapon", "Charge Level:", _charge_level)

func _on_weapon_charge_updated(_charge_level: int):
	# Handle charge level updates
	pass

func _on_weapon_ammo_updated(_current_ammo: int):
	# Handle ammo updates
	pass

func fire_actor_weapons(target_pos: Vector2 = Vector2.ZERO):
	if actor_weapons.is_empty():
		return

	print("Firing all actor weapons, total:", actor_weapons.size())

	for weapon in actor_weapons:
		print("[COMBAT] Firing actor weapon:", weapon.weapon_data.item_name if weapon.weapon_data else "Unknown Weapon")
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
	var weapons_to_fire = min(combo_counter, actor_weapons.size())

	# Calculate ATP cost
	var total_atp_cost = 0.0

	for i in range(weapons_to_fire):
		if i < actor_weapons.size() and actor_weapons[i]:
			total_atp_cost += actor_weapons[i].get_atp_cost()

	# Check if we have enough ATP
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		return  # Not enough energy

	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)

	# Fire the weapons
	for i in range(weapons_to_fire):
		if i < actor_weapons.size() and actor_weapons[i]:
			print("[COMBAT] Firing secondary weapon:", weapon_effect)
			actor_weapons[i].fire(weapon_effect)
		# Add a short delay between shots
		await get_tree().create_timer(0.2).timeout
	# 如果连击数达到最大值，则重置
	if combo_counter >= actor_weapons.size():
		reset_combo()

	# Emit signal
	emit_signal("weapons_fired", "secondary", weapons_to_fire, 1)
	emit_signal("combat_action_performed", "light_attack", total_atp_cost)

func reset_combo():
	combo_counter = 0
	emit_signal("combo_updated", combo_counter)

func get_total_actor_weapon_damage() -> float:
	var total_damage = 0.0
	for weapon in actor_weapons:
		if weapon:
			total_damage += weapon.weapon_data.damage
	return total_damage

func reload_all_weapons():
	for weapon in actor_weapons:
		if weapon:
			weapon.reload()
