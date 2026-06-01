# actor.gd
# The base script for all actors in the game (Player, Enemies, etc.).
# It provides common functionality and component references.
extends CharacterBody2D

class_name Actor

# Signals
signal actor_health_changed(current_health: int, max_health: int)
signal actor_died()
signal inventory_item_added(item_data: ItemData) # Example for future use

# @onready var atp_component: ATPComponent = $ATPComponent
@onready var attribute_component: AttributeComponent = $AttributeComponent
@onready var visuals: AnimatedSprite2D = %AnimatedSprite2D
@onready var actor_combat_component: ActorCombatComponent = $ActorCombatComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var ai_controller: AIControllerComponent = $AIControllerComponent if has_node("AIControllerComponent") else null

# This property will be set by the spawner.
@export var actor_data: ActorData

## A stable unique identifier used for save/load. Unlike NodePath, this ID
## persists across scene tree renames and allows entity-identity to be stable.
## If left empty, the node path will be used as a fallback during saving.
@export var save_id: String = ""

## Mutable runtime state for this actor instance. Not a Resource; never saved to .tres.
var runtime_state: ActorRuntimeState = ActorRuntimeState.new()

## NEW: Entity ID for the new ECS-lite architecture.
## All systems reference this actor by entity_id instead of node references.
var entity_id: int = -1

var last_direction: Vector2 = Vector2.DOWN
# 不再直接持有weapon_components，由combat组件管理

func _ready():
	# This function is meant to be called by child classes AFTER they have
	# assigned their specific ActorData to the stats_component.
	if actor_data:
		# Initialize runtime state from template data.
		# This separates "what the actor can be" (ActorData) from
		# "what the actor currently is" (runtime_state).
		runtime_state.initialize_from_template(actor_data)
		
		# Copy default equipped weapons from template into runtime state
		runtime_state.equipped_weapons = actor_data.equipped_weapons.duplicate()
		
		# Assign the metabolism component's data source
		_setup_animations()
		# Apply sprite scale
		if visuals and actor_data.sprite_scale != Vector2.ZERO:
			visuals.scale = actor_data.sprite_scale

		# Dynamically set collision radius
		var collision_shape: CollisionShape2D = $CollisionShape2D
		if collision_shape and actor_data.has_method("get_collision_radius"):
			var shape: Shape2D = collision_shape.shape
			if shape and shape.has_method("set_radius"):
				shape.set_radius(actor_data.get_collision_radius())
		
		# Dynamically load combat component and weapons
		actor_combat_component.set_actor_data(actor_data, runtime_state.equipped_weapons)

		# Initialize inventory component
		inventory_component.set_data(actor_data)
		
		# Initialize AI controller if present using unique_name
		if ai_controller:
			ai_controller.set_behaviors(actor_data.behaviors)
		
		# Sync components to runtime state (separates template from mutable state)
		attribute_component.set_runtime_state(runtime_state)
		attribute_component.health_component.health_changed.connect(
			func(current, max_hp): actor_health_changed.emit(current, max_hp)
		)
		attribute_component.health_component.died.connect(_on_death)
		
		# Connect toughness/stagger signals
		if attribute_component.toughness_component:
			attribute_component.toughness_component.stagger_started.connect(_on_stagger_started)
			attribute_component.toughness_component.stagger_ended.connect(_on_stagger_ended)
		# --- NEW: Register actor in the ECS-lite architecture ---
		_register_in_ecs()
	else:
		printerr("Actor _ready() called, but no ActorData was assigned.")

func _physics_process(delta: float):
	# Check if staggered - if so, disable all movement and AI
	if attribute_component and attribute_component.toughness_component:
		if attribute_component.toughness_component.is_in_stagger():
			# Staggered! No movement allowed
			velocity = Vector2.ZERO
			move_and_slide()
			return
	
	# Delegate AI control to the controller component if available
	if ai_controller and ai_controller.is_ai_active():
		var executed = ai_controller.execute(delta, self)
		if executed:
			# AI behaviors may have set velocity; move and animate
			_update_animation()
			move_and_slide()
			return

	# Player-controlled actors will have their velocity set in their own script.
	# This ensures move_and_slide and animation updates run for ALL actors.
	_update_animation()
	move_and_slide()

func reset_actor():
	pass

func _setup_animations():
	if not actor_data or not actor_data.animations:
		return

	var sprite_frames = SpriteFrames.new()

	for anim_data in actor_data.animations:
		if not anim_data or not anim_data.spritesheet:
			continue

		sprite_frames.add_animation(anim_data.animation_name)
		sprite_frames.set_animation_speed(anim_data.animation_name, anim_data.speed)

		var texture = anim_data.spritesheet
		var frame_width = texture.get_width() / anim_data.h_frames
		var frame_height = texture.get_height() / anim_data.v_frames

		var frame_indices = anim_data.frame_indices
		# If no specific indices, create a default sequence
		if frame_indices.is_empty():
			for i in range(anim_data.h_frames * anim_data.v_frames):
				frame_indices.append(i)

		for frame_index in frame_indices:
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
			var x = (frame_index % anim_data.h_frames) * frame_width
			var y = (frame_index / anim_data.h_frames) * frame_height
			atlas_texture.region = Rect2(x, y, frame_width, frame_height)
			sprite_frames.add_frame(anim_data.animation_name, atlas_texture)

	visuals.sprite_frames = sprite_frames
	# Start with a default animation if available
	if visuals.sprite_frames.has_animation("idle_down"):
		visuals.play("idle_down")

func _update_animation():
	var direction = Vector2.ZERO
	if velocity.length_squared() > 0:
		direction = velocity.normalized()
		last_direction = direction

	var anim_name = "idle"
	if direction != Vector2.ZERO:
		anim_name = "walk"

	# Determine direction suffix
	var dir_suffix = "down"
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			dir_suffix = "right"
		else:
			dir_suffix = "left"
	else:
		if last_direction.y > 0:
			dir_suffix = "down"
		else:
			dir_suffix = "up"

	var final_anim_name = anim_name + "_" + dir_suffix

	if visuals.sprite_frames and visuals.sprite_frames.has_animation(final_anim_name):
		if visuals.animation != final_anim_name or not visuals.is_playing():
			visuals.play(final_anim_name)
	elif visuals.sprite_frames and visuals.sprite_frames.has_animation(anim_name):
		if visuals.animation != anim_name or not visuals.is_playing():
			visuals.play(anim_name)

func play_combat_animation(anim_name: String):
	"""Play a combat animation (combo or heavy attack)"""
	if not visuals or not visuals.sprite_frames:
		return
	
	if visuals.sprite_frames.has_animation(anim_name):
		visuals.play(anim_name)
		GameLogger.debug("actor", "Playing combat animation: %s" % anim_name)
	else:
		GameLogger.debug("actor", "Combat animation not found: %s" % anim_name)

# --- Public API ---

func take_damage(amount: int):
	attribute_component.health_component.take_damage(amount)
	_show_damage_number(amount)

func _show_damage_number(amount: int):
	var label = Label.new()
	label.text = str(amount)
	
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	
	label.global_position = global_position + Vector2(randf_range(-20, 20), -50)
	get_tree().get_root().add_child(label)
	
	var tween = get_tree().create_tween().set_parallel()
	
	tween.tween_property(label, "global_position:y", label.global_position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(label.queue_free)

func _on_death():
	actor_died.emit()
	
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	queue_free()

## Called when actor enters stagger state
func _on_stagger_started():
	GameLogger.debug("actor", "[ACTOR] %s entered stagger state!" % (actor_data.actor_name if actor_data else "Actor"))
	
	# Play stagger animation if available
	if visuals and visuals.sprite_frames:
		if visuals.sprite_frames.has_animation("stagger"):
			visuals.play("stagger")
		else:
			# No stagger animation, flash the sprite
			_play_stagger_flash_effect()
	
	# Visual indicator - tint red
	if visuals:
		visuals.modulate = Color(1.0, 0.5, 0.5)  # Reddish tint

## Called when actor exits stagger state
func _on_stagger_ended():
	GameLogger.debug("actor", "[ACTOR] %s recovered from stagger!" % (actor_data.actor_name if actor_data else "Actor"))
	
	# Restore normal color
	if visuals:
		visuals.modulate = Color.WHITE
	
	# Resume normal animation
	_update_animation()

## Flash effect during stagger
func _play_stagger_flash_effect():
	if not visuals:
		return
	
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(visuals, "modulate:a", 0.3, 0.2)
	tween.tween_property(visuals, "modulate:a", 1.0, 0.2)

# --- NEW: ECS-lite Registration ---

func _register_in_ecs() -> void:
	"""Register this actor in the new EntityManager and StatSystem."""
	var entity_manager: EntityManager = ServiceRegistry.get_service("EntityManager")
	if entity_manager == null:
		# ServiceRegistry not ready yet (Bootstrap hasn't run)
		# Retry next frame via _process
		return
	
	if entity_id >= 0:
		return  # Already registered
	
	entity_id = entity_manager.register_entity(self, actor_data)
	
	# Register in StatSystem using the actor's data
	var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
	if stat_system and actor_data:
		var stat_defs = actor_data.create_stat_sheet()
		for stat_def in stat_defs:
			if stat_def is StatDefinition:
				stat_system.add_stat(entity_id, stat_def)
	
	# Register in ResourcePoolSystem
	var pool_system: ResourcePoolSystem = ServiceRegistry.get_service("ResourcePoolSystem")
	if pool_system:
		pool_system.register_entity(entity_id)
	
	# Sync old HealthComponent current value to new StatSystem
	if health_component:
		_reconcile_to_new_stat_system()

func _reconcile_to_new_stat_system() -> void:
	"""One-way sync: old component values -> new StatSystem. New system is authoritative during transition."""
	if entity_id < 0:
		return
	
	var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
	if stat_system:
		stat_system.set_stat_value(entity_id, "health", float(health_component.current_health))
		stat_system.set_stat_value(entity_id, "toughness", float(attribute_component.toughness_component.current_toughness))
		stat_system.set_stat_value(entity_id, "atp", float(attribute_component.metabolism_component.current_atp))
		stat_system.set_stat_value(entity_id, "glucose", float(attribute_component.metabolism_component.current_glucose))

func _process(delta: float) -> void:
	# Retry ECS registration if Bootstrap was not ready during _ready
	if entity_id < 0:
		_register_in_ecs()
