# components/combat_component.gd
# Main combat system component
extends Node2D
class_name ActorCombatComponent

# Heavy attack scaling constants
const DAMAGE_CHARGE_SCALING_FACTOR: float = 0.4
const ATP_CHARGE_SCALING_FACTOR: float = 0.5

@export var data_source: ActorData = null

var actor_weapons: Array[WeaponComponent] = []

# Sub-components
var combo_system: ComboSystem = null
var heavy_attack_system: HeavyAttackSystem = null
var hit_damage_calculator: HitDamageCalculator = null

@onready var weapon_effect: BaseWeaponEffect = $BaseWeaponEffect
@export var attribute_component: AttributeComponent = null
@export var charge_component: ChargeComponent = null

# Backward-compatible state proxies (external code may read these)
var combo_counter: int:
	get:
		return combo_system.combo_counter if combo_system else 0
	set(value):
		if combo_system:
			combo_system.combo_counter = value

var combo_stage: int:
	get:
		return combo_system.combo_stage if combo_system else 0
	set(value):
		if combo_system:
			combo_system.combo_stage = value

var is_charging_heavy: bool:
	get:
		return heavy_attack_system.is_charging_heavy if heavy_attack_system else false
	set(value):
		if heavy_attack_system:
			heavy_attack_system.is_charging_heavy = value

var last_heavy_charge: float:
	get:
		return heavy_attack_system.last_heavy_charge if heavy_attack_system else 0.0
	set(value):
		if heavy_attack_system:
			heavy_attack_system.last_heavy_charge = value

var last_combo_time: float:
	get:
		return combo_system.last_combo_time if combo_system else 0.0
	set(value):
		if combo_system:
			combo_system.last_combo_time = value

var combo_reset_time: float:
	get:
		return combo_system.combo_reset_time if combo_system else 0.5
	set(value):
		if combo_system:
			combo_system.combo_reset_time = value

# Preserved for full backward compatibility (was declared in original but unused)
var heavy_charge_level: int = 0

signal combat_action_performed(action_type: String, energy_cost: float)
signal combo_updated(combo_count: int, combo_stage: int)
signal combo_stage_changed(stage: int, combo_data: ComboAttackData)
signal heavy_attack_performed(charge_level: int, heavy_data: HeavyAttackData)
signal weapons_fired(weapon_type: String, count: int, charge_level: int)
signal enemy_hit(target: Node, damage: float, armor_break: float, stagger: float)

func _ready():
	combo_system = ComboSystem.new()
	combo_system.name = "ComboSystem"
	add_child(combo_system)
	combo_system.combo_updated.connect(func(count: int, stage: int): combo_updated.emit(count, stage))
	combo_system.combo_stage_changed.connect(func(stage: int, data: ComboAttackData): combo_stage_changed.emit(stage, data))

	heavy_attack_system = HeavyAttackSystem.new()
	heavy_attack_system.name = "HeavyAttackSystem"
	add_child(heavy_attack_system)
	heavy_attack_system.heavy_attack_performed.connect(func(level: int, data: HeavyAttackData): heavy_attack_performed.emit(level, data))

	hit_damage_calculator = HitDamageCalculator.new()
	hit_damage_calculator.name = "HitDamageCalculator"
	add_child(hit_damage_calculator)
	hit_damage_calculator.enemy_hit.connect(func(target: Node, damage: float, ab: float, sp: float): enemy_hit.emit(target, damage, ab, sp))

	# Fallback for @export fields if not assigned in inspector
	if not attribute_component:
		attribute_component = _ensure_attribute_component_exists()
	
	charge_component = _ensure_charge_component_exists()
	if charge_component:
		charge_component.charge_changed.connect(_on_charge_changed)
		charge_component.charge_level_up.connect(_on_charge_level_up)

	hit_damage_calculator.configure(actor_weapons, charge_component, heavy_attack_system, combo_system)

func set_actor_data(data: ActorData, initial_weapons: Array[ItemData] = []):
	data_source = data
	var weapons_to_equip := initial_weapons if not initial_weapons.is_empty() else data.equipped_weapons
	for weapon_item in weapons_to_equip:
		if actor_weapons.size() >= data.weapon_number_limit:
			break
		var weapon_instance := WeaponComponent.new()
		weapon_instance.item_data = weapon_item
		weapon_instance.setup_weapon()
		add_child.call_deferred(weapon_instance)
		add_actor_weapon.call_deferred(weapon_instance)

func _ensure_charge_component_exists() -> ChargeComponent:
	# Respect @export assignment first
	if charge_component:
		return charge_component
	# Fallback: find charge component in parent's tree
	if get_parent() and get_parent().has_node("ChargeComponent"):
		return get_parent().get_node("ChargeComponent") as ChargeComponent
	# Last resort: create new charge component
	if get_parent():
		var new_charge := ChargeComponent.new()
		new_charge.name = "ChargeComponent"
		get_parent().add_child.call_deferred(new_charge)
		return new_charge
	return null

func _ensure_attribute_component_exists() -> AttributeComponent:
	if attribute_component:
		return attribute_component
	if get_parent() and get_parent().has_node("AttributeComponent"):
		return get_parent().get_node("AttributeComponent") as AttributeComponent
	return null

func add_actor_weapon(weapon_component) -> bool:
	actor_weapons.append(weapon_component)
	_connect_weapon_signals(weapon_component)
	if actor_weapons.size() == 1 and charge_component and weapon_component.item_data:
		var weapon_data = weapon_component.item_data.weapon_data as WeaponData
		if weapon_data:
			charge_component.set_charge_rate(weapon_data.charge_rate_per_second)
			charge_component.progress_per_level = weapon_data.progress_per_level
			charge_component.light_attacks_build_charge = weapon_data.light_attacks_build_charge
			GameLogger.debug("combat", "Configured charge component: rate=%s progress/level=%s" % [weapon_data.charge_rate_per_second, weapon_data.progress_per_level])
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
	GameLogger.debug("combat", "Weapon fired: %s Charge Level: %d" % [(_weapon_data.item_name if _weapon_data else "Unknown Weapon"), _charge_level])

func _on_weapon_charge_updated(_charge_level: int):
	pass

func _on_weapon_ammo_updated(_current_ammo: int):
	pass

func fire_actor_weapons(target_pos: Vector2 = Vector2.ZERO):
	if actor_weapons.is_empty():
		return
	GameLogger.debug("combat", "Firing all actor weapons, total: %d" % actor_weapons.size())
	for weapon in actor_weapons:
		GameLogger.debug("combat", "Firing actor weapon: %s" % (weapon.item_data.item_name if weapon.item_data else "Unknown Weapon"))
		weapon.fire(weapon_effect, target_pos)
		await get_tree().create_timer(0.2).timeout
	emit_signal("weapons_fired", "actor", actor_weapons.size(), 1)
	emit_signal("combat_action_performed", "actor_attack", 10)

func perform_light_attack():
	if actor_weapons.is_empty():
		return
	var weapon = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return
	var weapon_data = weapon.item_data.weapon_data as WeaponData
	if not weapon_data or weapon_data.combo_attacks.is_empty():
		_perform_simple_light_attack()
		return
	var combo_data: ComboAttackData = combo_system.advance_combo(weapon_data)
	GameLogger.debug("combat", "Light attack - Combo stage: %d Count: %d" % [combo_system.combo_stage, combo_system.combo_counter])
	var base_atp_cost = weapon.get_atp_cost()
	var total_atp_cost = base_atp_cost
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		GameLogger.warn("combat", "Not enough ATP for light attack")
		EventBus.combat_action_failed.emit("light_attack", "Not enough ATP")
		return
	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)
	var target_pos = get_global_mouse_position()
	weapon.fire(weapon_effect, target_pos)
	if get_parent() and get_parent().has_method("play_combat_animation"):
		get_parent().play_combat_animation(combo_data.animation_name)
	combo_system.plan_reset_timer(weapon_data, combo_data, get_tree(), reset_combo)
	emit_signal("weapons_fired", "light_attack", 1, combo_system.combo_stage + 1)
	emit_signal("combat_action_performed", "light_attack", total_atp_cost)

func _perform_simple_light_attack():
	combo_system.combo_counter += 1
	combo_system.last_combo_time = Time.get_ticks_msec() / 1000.0
	combo_system.combo_updated.emit(combo_system.combo_counter, 0)
	var weapons_to_fire = min(combo_system.combo_counter, actor_weapons.size())
	var total_atp_cost = 0.0
	for i in range(weapons_to_fire):
		if i < actor_weapons.size() and actor_weapons[i]:
			total_atp_cost += actor_weapons[i].get_atp_cost()
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		return
	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)
	for i in range(weapons_to_fire):
		if i < actor_weapons.size() and actor_weapons[i]:
			GameLogger.debug("combat", "Firing secondary weapon: %s" % weapon_effect)
			actor_weapons[i].fire(weapon_effect)
		await get_tree().create_timer(0.2).timeout
	if combo_system.combo_counter >= actor_weapons.size():
		combo_system.reset_combo()
	emit_signal("weapons_fired", "secondary", weapons_to_fire, 1)
	emit_signal("combat_action_performed", "light_attack", total_atp_cost)

func reset_combo():
	combo_system.reset_combo()

func start_heavy_attack_charge():
	if not charge_component:
		GameLogger.error("combat", "No charge component found!")
		return
	heavy_attack_system.start_charge(charge_component)
	GameLogger.debug("combat", "Started charging heavy attack, charge_component != null: %s" % (charge_component != null))

func release_heavy_attack():
	if not charge_component or not heavy_attack_system.is_charging_heavy:
		GameLogger.warn("combat", "Cannot release - not charging or no charge component")
		return
	var effective_charge: float = heavy_attack_system.release_charge(charge_component)
	if actor_weapons.is_empty():
		return
	var weapon = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return
	var weapon_data = weapon.item_data.weapon_data as WeaponData
	if not weapon_data or weapon_data.heavy_attacks.is_empty():
		GameLogger.debug("combat", "No heavy attack data configured")
		return
	var heavy_data = heavy_attack_system.get_heavy_attack_data(weapon_data, effective_charge)
	if not heavy_data:
		GameLogger.debug("combat", "No heavy attack data found for charge level: %s" % effective_charge)
		return
	GameLogger.debug("combat", "Heavy attack - Effective charge: %.2f" % effective_charge)
	var base_atp_cost = weapon.get_atp_cost()
	var total_atp_cost = heavy_attack_system.calculate_atp_cost(base_atp_cost, effective_charge, heavy_data)
	if attribute_component and attribute_component.get_current_atp() < total_atp_cost:
		GameLogger.warn("combat", "Not enough ATP for heavy attack - charge preserved")
		EventBus.combat_action_failed.emit("heavy_attack", "Not enough ATP")
		heavy_attack_system.is_charging_heavy = false
		return
	if attribute_component:
		attribute_component.consume_atp(total_atp_cost)
	heavy_attack_system.last_heavy_charge = effective_charge
	var target_pos = get_global_mouse_position()
	weapon.fire(weapon_effect, target_pos)
	if get_parent() and get_parent().has_method("play_combat_animation"):
		get_parent().play_combat_animation(heavy_data.animation_name)
	var charge_for_signals = int(ceil(effective_charge))
	emit_signal("heavy_attack_performed", charge_for_signals, heavy_data)
	emit_signal("weapons_fired", "heavy_attack", 1, charge_for_signals)
	emit_signal("combat_action_performed", "heavy_attack", total_atp_cost)
	charge_component.reset_charge()
	await get_tree().create_timer(heavy_data.recovery_time).timeout

func on_enemy_hit(target: Node, base_weapon_damage: float):
	if hit_damage_calculator:
		hit_damage_calculator.on_enemy_hit(get_parent(), target, base_weapon_damage)

func _on_charge_changed(level: int, progress: float, max_level: int):
	GameLogger.debug("combat", "Charge changed: Lv %d (%.1f%%) / Max Lv %d" % [level, progress, max_level])

func _on_charge_level_up(level: int):
	GameLogger.debug("combat", "Charge level up: %d" % level)

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
