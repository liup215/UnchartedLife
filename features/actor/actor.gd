# actor.gd
# The base script for all actors in the game (Player, Enemies, etc.).
# It provides common functionality and component references.
extends CharacterBody2D

class_name Actor

# Signals
signal actor_health_changed(current_health: int, max_health: int)
signal actor_died()
signal inventory_item_added(item_data: ItemData) # Example for future use

# Components
@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var atp_component: ATPComponent = $ATPComponent
@onready var visuals: AnimatedSprite2D = %AnimatedSprite2D

# This property will be set by the spawner.
@export var actor_data: ActorData

var last_direction: Vector2 = Vector2.DOWN

func _ready():
	# This function is meant to be called by child classes AFTER they have
	# assigned their specific ActorData to the stats_component.
	if actor_data:
		stats_component.data = actor_data
		# Initialize components with data from the resource
		health_component.set_max_health(stats_component.get_max_health())
		atp_component.set_max_atp(stats_component.get_max_atp())
		_setup_animations()
		
		# Connect signals from components to the actor's own signals
		health_component.health_changed.connect(
			func(current, max): actor_health_changed.emit(current, max)
		)
		health_component.died.connect(_on_death)
	else:
		printerr("Actor _ready() called, but no ActorData was assigned.")

func _physics_process(delta: float):
	# Reset velocity before executing behaviors for AI-controlled actors
	if actor_data and not actor_data.behaviors.is_empty():
		velocity = Vector2.ZERO
		for behavior in actor_data.behaviors:
			if behavior:
				behavior.execute(self, delta)
	
	# Player-controlled actors will have their velocity set in their own script.
	# This ensures move_and_slide and animation updates run for ALL actors.
	_update_animation()
	move_and_slide()

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
	
	if visuals.sprite_frames.has_animation(final_anim_name) and visuals.animation != final_anim_name:
		visuals.play(final_anim_name)
	elif visuals.sprite_frames.has_animation(anim_name) and visuals.animation != anim_name: # Fallback to non-directional
		visuals.play(anim_name)

# --- Public API ---

func take_damage(amount: int):
	health_component.take_damage(amount)
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

# --- Save/Load Interface ---

func save_data() -> Dictionary:
	return {
		"position_x": position.x,
		"position_y": position.y,
		"current_health": health_component.current_health
	}

func load_data(data: Dictionary):
	position.x = data.get("position_x", position.x)
	position.y = data.get("position_y", position.y)
	
	var loaded_health = data.get("current_health", health_component.max_health)
	health_component.current_health = loaded_health

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
