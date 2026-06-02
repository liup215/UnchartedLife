## molecule.gd
## Interactive molecule object for the prologue scene.
## Structure and visual identity are driven by MoleculeData.
## Interaction effects are configured per-scene via ItemEffectData array.
class_name Molecule extends Node2D

const MoleculeData = preload("res://data/definitions/molecule/molecule_data.gd")
const ItemEffectData = preload("res://data/definitions/item/item_effect_data.gd")

const PICKUP_ANIMATION_DURATION: float = 0.2

@export var molecule_data: Resource  # Runtime-casted to MoleculeData
@export var interaction_effects: Array[ItemEffectData] = []  # Scene-level pickup effects

@export var damage_amount: int = 10
@export var ammo_amount: int = 5

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D

var picked_up: bool = false

func _ready():
	_setup_visuals()
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.area_entered.connect(_on_area_entered)

func _setup_visuals():
	var color := Color.WHITE
	
	if molecule_data != null:
		color = molecule_data.base_color
	
	# --- Data-driven procedural visual ---
	var visual_node: Node2D = get_node_or_null("MoleculeVisual")
	if visual_node and visual_node.has_method("set_molecule_data"):
		visual_node.set_molecule_data(molecule_data)
		if sprite_2d:
			sprite_2d.visible = false
	else:
		# Legacy fallback: tint the sprite
		if sprite_2d:
			sprite_2d.modulate = color

func _on_body_entered(body: Node2D):
	GameLogger.debug("prologue", "Molecule: body_entered triggered - %s - is player: %s" % [body.name, body.is_in_group("player")])
	
	if picked_up:
		return
		
	if body.is_in_group("player"):
		GameLogger.debug("prologue", "Molecule: Player detected! Interacting...")
		_interact_with_player(body)

func _on_area_entered(area: Area2D):
	if picked_up:
		return
	
	if area.is_in_group("projectile"):
		pass  # Could implement shooting molecules to pick them up

func _interact_with_player(player: Node):
	picked_up = true
	
	# Apply all configured interaction effects
	var had_effects := false
	for effect in interaction_effects:
		if effect != null:
			_apply_effect(player, effect)
			had_effects = true
	
	# Legacy fallback: if no effects configured, apply built-in ammo/damage logic
	if not had_effects:
		_handle_legacy_interaction(player)
	
	# Emit event so prologue UI can update
	var is_correct := _is_correct_molecule()
	EventBus.molecule_collected.emit(molecule_data, is_correct)
	
	# Visual feedback
	if is_correct:
		_play_positive_feedback()
	else:
		_play_negative_feedback()
	
	_play_pickup_animation()
	await get_tree().create_timer(PICKUP_ANIMATION_DURATION).timeout
	queue_free()

func _is_correct_molecule() -> bool:
	if molecule_data == null:
		return false
	# Both α and β anomers count as correct "glucose"
	return molecule_data.molecule_name in ["alpha_glucose", "beta_glucose"]

func _apply_effect(player: Node2D, effect: ItemEffectData) -> void:
	"""Apply a single ItemEffectData to the player (or relevant systems)."""
	match effect.effect_type:
		ItemEffectData.EffectType.HEAL:
			if player is Actor:
				var amount: float = effect.params.get("amount", 0.0)
				player.take_damage(-int(amount))  # Negative damage = heal
				GameLogger.info("prologue", "Molecule healed player for %d HP" % int(amount))
		
		ItemEffectData.EffectType.RESTORE_RESOURCE:
			var resource_type: String = effect.params.get("resource_type", "")
			var amount: float = effect.params.get("amount", 0.0)
			_match_restore_resource(player, resource_type, amount)
		
		ItemEffectData.EffectType.CONSUME_RESOURCE:
			var resource_type: String = effect.params.get("resource_type", "")
			var amount: float = effect.params.get("amount", 0.0)
			# Negative restore = consumption, not typically used for molecules
			_match_restore_resource(player, resource_type, -amount)
		
		ItemEffectData.EffectType.APPLY_BUFF:
			var buff_id: String = effect.params.get("buff_id", "")
			var duration: float = effect.params.get("duration", 0.0)
			EventBus.buff_applied.emit(player, buff_id, duration)
			GameLogger.info("prologue", "Buff applied: %s for %.1fs" % [buff_id, duration])
		
		ItemEffectData.EffectType.FIRE_EVENT:
			var event_name: String = effect.params.get("event_name", "")
			EventBus.dialogue_event.emit(event_name, {})
		
		_:
			GameLogger.warn("prologue", "Molecule effect type %s not yet supported for molecules" % effect.get_effect_type_name())

func _match_restore_resource(player: Node2D, resource_type: String, amount: float) -> void:
	match resource_type.to_lower():
		"ammo":
			_give_ammo(player, int(amount))
		"atp":
			_give_atp(player, amount)
		"glucose":
			_give_glucose(player, amount)
		_:
			GameLogger.warn("prologue", "Unknown resource type for molecule effect: %s" % resource_type)

func _handle_legacy_interaction(player: Node) -> void:
	"""Fallback when no interaction_effects are configured. Preserves original gameplay."""
	if _is_correct_molecule():
		_give_ammo(player, ammo_amount)
	else:
		_damage_player(player, damage_amount)

func _give_ammo(player: Node2D, amount: int) -> void:
	if not player is Actor:
		GameLogger.warn("prologue", "Warning: Target is not an Actor")
		return
	
	var player_actor := player as Actor
	var combat_component := player_actor.actor_combat_component
	if not combat_component:
		GameLogger.warn("prologue", "Warning: Player has no combat component")
		return
	
	if combat_component.actor_weapons.is_empty():
		GameLogger.warn("prologue", "Warning: Player has no weapons equipped")
		return
	
	var weapon_comp: WeaponComponent = combat_component.actor_weapons[0]
	if not weapon_comp:
		GameLogger.warn("prologue", "Warning: Weapon component is null")
		return
		
	if not weapon_comp.item_data or not weapon_comp.item_data.weapon_data:
		GameLogger.warn("prologue", "Warning: Weapon has no data")
		return
	
	var max_ammo: int = weapon_comp.item_data.weapon_data.ammo_capacity
	weapon_comp.current_ammo = min(
		weapon_comp.current_ammo + amount,
		max_ammo
	)
	weapon_comp.ammo_updated.emit(weapon_comp.current_ammo)
	GameLogger.info("prologue", "Ammo restored +%d (now %d/%d)" % [amount, weapon_comp.current_ammo, max_ammo])


func _give_atp(player: Node2D, amount: float) -> void:
	if not player is Actor:
		return
	var attr: AttributeComponent = player.get_node_or_null("AttributeComponent")
	if attr:
		attr.current_atp = min(attr.current_atp + amount, attr.max_atp)
		GameLogger.info("prologue", "ATP restored +%.1f" % amount)


func _give_glucose(player: Node2D, amount: float) -> void:
	if not player is Actor:
		return
	var attr: AttributeComponent = player.get_node_or_null("AttributeComponent")
	if attr:
		attr.current_glucose = min(attr.current_glucose + amount, attr.max_glucose)
		GameLogger.info("prologue", "Glucose restored +%.1f" % amount)


func _damage_player(player: Node2D, amount: int) -> void:
	if not player is Actor:
		GameLogger.warn("prologue", "Warning: Target is not an Actor")
		return
	var player_actor := player as Actor
	player_actor.take_damage(amount)
	GameLogger.info("prologue", "Wrong molecule! -%d HP" % amount)

func _play_positive_feedback() -> void:
	var tween := create_tween()
	var vis := get_node_or_null("MoleculeVisual")
	if vis != null:
		tween.tween_property(vis, "scale", Vector2(1.4, 1.4), 0.1)
		tween.tween_property(vis, "modulate:a", 0.0, 0.1)
	elif sprite_2d:
		tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.1)

func _play_negative_feedback() -> void:
	var tween := create_tween()
	var vis := get_node_or_null("MoleculeVisual")
	if vis != null:
		tween.tween_property(vis, "modulate", Color.RED, 0.05)
		tween.tween_property(vis, "modulate:a", 0.0, 0.15)
	elif sprite_2d:
		tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.15)

func _play_pickup_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -30), PICKUP_ANIMATION_DURATION)
