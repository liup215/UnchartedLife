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

# Combat state - Combo System
var combo_counter: int = 0
var combo_stage: int = 0  # Current stage in combo sequence
var last_combo_time: float = 0.0
var combo_reset_time: float = 0.5  # Time window to continue combo

# Combat state - Heavy Attack
var is_charging_heavy: bool = false
var heavy_charge_level: int = 0

# # ATP component reference
# var atp_component: Node = null

# Weapon effect handler
@onready var weapon_effect: BaseWeaponEffect = $BaseWeaponEffect
var attribute_component: AttributeComponent = get_parent().get_node("AttributeComponent") if get_parent() && get_parent().has_node("AttributeComponent") else null

# Charge component reference
var charge_component: ChargeComponent = null

# Signals
signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int, combo_stage: int)
signal combo_stage_changed(stage: int, combo_data: ComboAttackData)
signal heavy_attack_performed(charge_level: int, heavy_data: HeavyAttackData)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)
signal enemy_hit(target: Node, damage: float, armor_break: float, stagger: float)

func _ready():
	# Find ATP component in owner
	# if owner_node:
	# 	atp_component = owner_node.get_node("ATPComponent") if owner_node.has_node("ATPComponent") else null
	
	# Find or create charge component
	if get_parent() and get_parent().has_node("ChargeComponent"):
		charge_component = get_parent().get_node("ChargeComponent")
		charge_component.charge_changed.connect(_on_charge_changed)
		charge_component.charge_level_up.connect(_on_charge_level_up)
	else:
		# Create charge component if it doesn't exist
		var charge_comp = load("res://features/components/charge_component.tscn")
		if charge_comp and get_parent():
			charge_component = charge_comp.instantiate()
			get_parent().add_child.call_deferred(charge_component)
			# Connect signals after adding to tree (deferred to ensure component is in tree)
			charge_component.charge_changed.connect(_on_charge_changed)
			charge_component.charge_level_up.connect(_on_charge_level_up)

func set_actor_data(data: ActorData):
	data_source = data
	# 加载武器
	for weapon_item in data.equipped_weapons:
		if actor_weapons.size() >= data.weapon_number_limit:
			break
		var weapon_scene = preload("res://features/components/weapon_component.tscn")
		if weapon_scene:
			var weapon_instance = weapon_scene.instantiate()
			weapon_instance.item_data = weapon_item
			weapon_instance.setup_weapon()
			add_child.call_deferred(weapon_instance)
			# Add weapon to array after it's been added to tree (deferred)
			add_actor_weapon.call_deferred(weapon_instance)

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
		print("[COMBAT] Firing actor weapon:", weapon.item_data.item_name if weapon.item_data else "Unknown Weapon")
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
	# Check combo timing
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_combo_time > combo_reset_time:
		combo_counter = 0
		combo_stage = 0
	
	# Get first weapon to determine combo configuration
	if actor_weapons.is_empty():
		return
	
	var weapon = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return
	
	var weapon_data = weapon.item_data.weapon_data as WeaponData
	if not weapon_data or weapon_data.combo_attacks.is_empty():
		# Fallback to simple attack if no combo data
		_perform_simple_light_attack()
		return
	
	# Calculate combo stage BEFORE incrementing counter
	combo_stage = combo_counter % weapon_data.combo_attacks.size()
	var combo_data: ComboAttackData = weapon_data.combo_attacks[combo_stage]
	
	# Now increment counter
	combo_counter += 1
	last_combo_time = current_time
	
	# Emit combo signals
	emit_signal("combo_updated", combo_counter, combo_stage)
	emit_signal("combo_stage_changed", combo_stage, combo_data)
	
	print("[COMBAT] Light attack - Combo stage: ", combo_stage, " Count: ", combo_counter)
	
	# Calculate ATP cost for this combo stage
	var base_atp_cost = weapon.get_atp_cost()
	var total_atp_cost = base_atp_cost
	
	# Check if we have enough ATP
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		print("[COMBAT] Not enough ATP for light attack")
		return
	
	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)
	
	# Fire weapon with combo multiplier
	var target_pos = get_global_mouse_position()
	weapon.fire(weapon_effect, target_pos)
	
	# Play combo animation if actor has animation support
	if get_parent() and get_parent().has_method("play_combat_animation"):
		get_parent().play_combat_animation(combo_data.animation_name)
	
	# Accumulate charge from light attack hit (when it hits an enemy)
	# This will be triggered by projectile hit detection
	
	# Reset combo if reached max
	if combo_counter >= weapon_data.combo_attacks.size():
		# Use the final stage's combo window for reset
		var final_stage_window = combo_data.combo_window if combo_data else combo_reset_time
		# Cancel any existing reset timer
		if has_meta("combo_reset_timer"):
			var old_timer = get_meta("combo_reset_timer") as SceneTreeTimer
			if old_timer and old_timer.timeout.is_connected(reset_combo):
				old_timer.timeout.disconnect(reset_combo)
		# Create new timer and store reference
		var timer = get_tree().create_timer(final_stage_window)
		set_meta("combo_reset_timer", timer)
		timer.timeout.connect(reset_combo)
	
	# Emit signal
	emit_signal("weapons_fired", "light_attack", 1, combo_stage + 1)
	emit_signal("combat_action_performed", "light_attack", total_atp_cost)

func _perform_simple_light_attack():
	"""Fallback for weapons without combo data"""
	combo_counter += 1
	last_combo_time = Time.get_ticks_msec() / 1000.0
	emit_signal("combo_updated", combo_counter, 0)
	
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
	combo_stage = 0
	emit_signal("combo_updated", combo_counter, combo_stage)

## Start charging heavy attack
func start_heavy_attack_charge():
	if not charge_component:
		print("[COMBAT] ERROR: No charge component found!")
		return
	
	is_charging_heavy = true
	charge_component.start_heavy_charge()
	print("[COMBAT] Started charging heavy attack, charge component exists:", charge_component != null)

## Release heavy attack with accumulated charge
func release_heavy_attack():
	if not charge_component or not is_charging_heavy:
		print("[COMBAT] Cannot release - not charging or no charge component")
		return
	
	is_charging_heavy = false
	var charge_level = charge_component.stop_heavy_charge()
	
	if charge_level < 1:
		print("[COMBAT] No charge to release (charge level: ", charge_level, ")")
		return
	
	# Get first weapon to determine heavy attack configuration
	if actor_weapons.is_empty():
		return
	
	var weapon = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return
	
	var weapon_data = weapon.item_data.weapon_data as WeaponData
	if not weapon_data or weapon_data.heavy_attacks.is_empty():
		print("[COMBAT] No heavy attack data configured")
		return
	
	# Find appropriate heavy attack data for charge level
	var heavy_data: HeavyAttackData = null
	for ha in weapon_data.heavy_attacks:
		if ha.charge_level <= charge_level:
			heavy_data = ha
		else:
			break
	
	if not heavy_data:
		print("[COMBAT] No heavy attack data found for charge level: ", charge_level)
		return
	
	print("[COMBAT] Heavy attack - Charge level: ", charge_level)
	
	# Calculate ATP cost
	var base_atp_cost = weapon.get_atp_cost()
	var total_atp_cost = base_atp_cost * charge_level * heavy_data.atp_cost_multiplier
	
	# Check if we have enough ATP
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		print("[COMBAT] Not enough ATP for heavy attack - charge preserved")
		# Reset charging state but preserve charge
		is_charging_heavy = false
		return
	
	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)
	
	# Fire weapon with heavy attack multiplier
	var target_pos = get_global_mouse_position()
	weapon.fire(weapon_effect, target_pos)
	
	# Play heavy attack animation if actor has animation support
	if get_parent() and get_parent().has_method("play_combat_animation"):
		get_parent().play_combat_animation(heavy_data.animation_name)
	
	# Emit signals
	emit_signal("heavy_attack_performed", charge_level, heavy_data)
	emit_signal("weapons_fired", "heavy_attack", 1, charge_level)
	emit_signal("combat_action_performed", "heavy_attack", total_atp_cost)
	
	# Reset charge after release
	charge_component.reset_charge()
	
	# Apply recovery time
	await get_tree().create_timer(heavy_data.recovery_time).timeout

## Called when projectile hits an enemy to accumulate charge
## NOTE: This should be called from the projectile's hit detection logic
## For example, in the bullet/projectile script's _on_body_entered or similar:
##   if body.is_in_group("enemy") and shooter.has_node("ActorCombatComponent"):
##       shooter.get_node("ActorCombatComponent").on_enemy_hit(body, base_weapon_damage)
func on_enemy_hit(target: Node, base_weapon_damage: float):
	if not charge_component:
		return
	
	# Get combo data to determine charge gain and combat stats
	if actor_weapons.is_empty():
		return
	
	var weapon = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return
	
	var weapon_data = weapon.item_data.weapon_data as WeaponData
	if not weapon_data:
		return
	
	# Get combo/heavy attack data for multipliers
	var damage_multiplier = 1.0
	var armor_break = 0.0
	var stagger_power = 0.0
	var charge_gain = 1
	
	# Check if this was a combo attack
	if not weapon_data.combo_attacks.is_empty() and combo_stage < weapon_data.combo_attacks.size():
		var combo_data = weapon_data.combo_attacks[combo_stage]
		damage_multiplier = combo_data.damage_multiplier
		armor_break = combo_data.armor_break_power
		stagger_power = combo_data.stagger_power
		charge_gain = combo_data.charge_gain
	
	# Calculate comprehensive damage using DamageCalculator
	var attacker = get_parent()  # The actor who owns this combat component
	var damage_result = DamageCalculator.calculate_damage(
		attacker,
		target,
		base_weapon_damage,
		weapon_data.damage_type,
		damage_multiplier,
		armor_break
	)
	
	var final_damage = damage_result["final_damage"]
	var toughness_damage = damage_result["toughness_damage"]
	
	print("[COMBAT] Hit ", target.name, " - Damage: ", final_damage, " Toughness: ", toughness_damage)
	print("[COMBAT] Damage breakdown: ", damage_result["damage_breakdown"])
	
	# Apply damage to target
	if target.has_method("take_damage"):
		target.take_damage(int(final_damage))
	
	# Apply toughness damage to target
	if target.has_node("AttributeComponent"):
		var target_attr = target.get_node("AttributeComponent")
		if target_attr.toughness_component:
			target_attr.toughness_component.apply_toughness_damage(toughness_damage, stagger_power)
	
	# Add charge based on combo stage
	if weapon_data.light_attacks_build_charge:
		charge_component.add_light_attack_charge(charge_gain)
	
	# Emit hit signal with combat stats
	emit_signal("enemy_hit", target, final_damage, armor_break, stagger_power)

## Charge component callbacks
func _on_charge_changed(current: int, max: int):
	print("[COMBAT] Charge changed: ", current, "/", max)

func _on_charge_level_up(level: int):
	print("[COMBAT] Charge level up: ", level)

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
