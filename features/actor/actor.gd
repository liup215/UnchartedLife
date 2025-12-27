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

# This property will be set by the spawner.
@export var actor_data: ActorData

var last_direction: Vector2 = Vector2.DOWN
# 不再直接持有weapon_components，由combat组件管理

func _ready():
	# This function is meant to be called by child classes AFTER they have
	# assigned their specific ActorData to the stats_component.
	if actor_data:
		# Assign the metabolism component's data source
		_setup_animations()
		# Apply sprite scale
		if visuals and actor_data.sprite_scale != Vector2.ZERO:
			visuals.scale = actor_data.sprite_scale

		# 动态设置碰撞半径
		if has_node("CollisionShape2D") and actor_data.has_method("get_collision_radius"):
			var shape = get_node("CollisionShape2D").shape
			if shape and shape.has_method("set_radius"):
				shape.set_radius(actor_data.get_collision_radius())
		
		# 动态加载战斗组件和武器
		actor_combat_component.set_actor_data(actor_data)

		# Initialize inventory component
		inventory_component.set_data(actor_data)

		# Connect signals from components to the actor's own signals
		attribute_component.set_actor_data(actor_data)
		attribute_component.health_component.health_changed.connect(
			func(current, max_hp): actor_health_changed.emit(current, max_hp)
		)
		attribute_component.health_component.died.connect(_on_death)
		
		# Connect toughness/stagger signals
		if attribute_component.toughness_component:
			attribute_component.toughness_component.stagger_started.connect(_on_stagger_started)
			attribute_component.toughness_component.stagger_ended.connect(_on_stagger_ended)
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
	
	# Reset velocity before executing behaviors for AI-controlled actors
	if actor_data and not actor_data.behaviors.is_empty():
		velocity = Vector2.ZERO
		# 优先级调度：只执行第一个满足条件的行为
		for behavior in actor_data.behaviors:
			if behavior:
				# Check if the behavior should execute
				# If it has a should_execute method, use it
				# Otherwise, just execute it directly
				if behavior.has_method("should_execute"):
					if behavior.should_execute(self):
						behavior.execute(self, delta)
						break
				elif not behavior.has_method("should_execute"):
					behavior.execute(self, delta)
					break

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
		print("[ACTOR] Playing combat animation: ", anim_name)
	else:
		print("[ACTOR] Combat animation not found: ", anim_name)

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
	
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	queue_free()

## Called when actor enters stagger state
func _on_stagger_started():
	print("[ACTOR] ", actor_data.actor_name if actor_data else "Actor", " entered stagger state!")
	
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
	print("[ACTOR] ", actor_data.actor_name if actor_data else "Actor", " recovered from stagger!")
	
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
