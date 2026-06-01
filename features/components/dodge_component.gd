# dodge_component.gd
# Component that handles player dodge mechanics
extends Node
class_name DodgeComponent

signal dodge_started()
signal dodge_ended()
signal dodge_failed(reason: String)
signal invincibility_ended()

# Dodge parameters
@export var dodge_distance: float = 150.0  # Distance to move during dodge
@export var dodge_duration: float = 0.3  # Duration of dodge animation
@export var dodge_atp_cost: float = 30.0  # ATP cost for dodging
@export var invincibility_duration: float = 0.4  # Duration of invincibility
@export var cooldown_duration: float = 0.5  # Cooldown between dodges

# Internal state
var is_dodging: bool = false
var can_dodge: bool = true
var dodge_timer: float = 0.0
var invincibility_timer: float = 0.0
var cooldown_timer: float = 0.0
var current_dodge_tween: Tween = null

# Reference to parent actor
var actor: CharacterBody2D = null

# Afterimage effect
var afterimage_modulate: Color = Color(1.0, 1.0, 1.0, 0.3)  # Light color with transparency

func _ready():
	# Get parent actor reference
	actor = get_parent() as CharacterBody2D
	if not actor:
		push_error("DodgeComponent must be child of CharacterBody2D")
		return
	
	# Metabolism component discovery is now deferred to _get_current_atp() for
	# compatibility with the new StatSystem (ECS-lite architecture).

func _physics_process(delta: float):
	# Update dodge timer
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			_end_dodge()
	
	# Update invincibility timer
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if invincibility_timer <= 0.0:
			_end_invincibility()
	
	# Update cooldown timer
	if not can_dodge:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_dodge = true

func attempt_dodge(direction: Vector2) -> bool:
	"""
	Attempts to perform a dodge in the given direction.
	Returns true if dodge was successful, false otherwise.
	"""
	# Check if dodge is possible
	if not can_dodge:
		dodge_failed.emit("Dodge on cooldown")
		return false
	
	if is_dodging:
		dodge_failed.emit("Already dodging")
		return false
	
	# Check ATP availability via actor's compatible energy API
	var current_atp := _get_current_atp()
	if current_atp < 0:
		push_error("DodgeComponent: unable to access ATP system")
		dodge_failed.emit("No ATP system")
		return false
	
	if current_atp < dodge_atp_cost:
		dodge_failed.emit("Not enough ATP")
		return false
	
	# Consume ATP
	_consume_atp(dodge_atp_cost)
	
	# Start dodge
	_start_dodge(direction)
	return true

func _start_dodge(direction: Vector2):
	"""Internal method to start the dodge"""
	is_dodging = true
	can_dodge = false
	dodge_timer = dodge_duration
	invincibility_timer = invincibility_duration
	cooldown_timer = cooldown_duration
	
	# Kill any existing dodge tween
	if current_dodge_tween and current_dodge_tween.is_valid():
		current_dodge_tween.kill()
	
	# Create afterimage at current position
	_create_afterimage()
	
	# Apply dodge movement
	_apply_dodge_movement(direction)
	
	dodge_started.emit()

func _end_dodge():
	"""Internal method to end the dodge"""
	is_dodging = false
	dodge_ended.emit()

func _end_invincibility():
	"""Internal method to end invincibility"""
	# Emit signal for parent actor to handle
	invincibility_ended.emit()

func _apply_dodge_movement(direction: Vector2):
	"""Apply the dodge movement to the actor"""
	if not actor:
		return
	
	# Normalize direction if not zero
	var dodge_direction = direction
	if dodge_direction.length() > 0:
		dodge_direction = dodge_direction.normalized()
	else:
		# If no direction input, use last facing direction or default to right
		if actor.has_method("get_last_direction"):
			dodge_direction = actor.get_last_direction()
		else:
			dodge_direction = Vector2.RIGHT
	
	# Calculate target position
	var target_position = actor.global_position + dodge_direction * dodge_distance
	
	# Create a tween for smooth movement and store reference
	current_dodge_tween = create_tween()
	current_dodge_tween.set_ease(Tween.EASE_OUT)
	current_dodge_tween.set_trans(Tween.TRANS_QUAD)
	current_dodge_tween.tween_property(actor, "global_position", target_position, dodge_duration)

func _create_afterimage():
	"""Create an afterimage at the current position"""
	if not actor:
		return
	
	# Find the visual sprite
	var sprite: AnimatedSprite2D = null
	if actor.has_node("%AnimatedSprite2D"):
		sprite = actor.get_node("%AnimatedSprite2D")
	elif actor.get("visuals"):
		sprite = actor.visuals
	
	if not sprite:
		return
	
	# Validate sprite data before accessing
	if not sprite.sprite_frames:
		push_warning("Cannot create afterimage: sprite has no sprite_frames")
		return
	
	if not sprite.animation or sprite.animation == "":
		push_warning("Cannot create afterimage: sprite has no valid animation")
		return
	
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 0:
		push_warning("Cannot create afterimage: animation has no frames")
		return
	
	# Get parent for afterimage
	var parent = actor.get_parent()
	if not parent:
		push_warning("Cannot create afterimage: actor has no parent")
		return
	
	# Create afterimage sprite
	var afterimage = Sprite2D.new()
	afterimage.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	afterimage.global_position = sprite.global_position
	afterimage.scale = sprite.scale
	afterimage.rotation = sprite.rotation
	afterimage.flip_h = sprite.flip_h
	afterimage.flip_v = sprite.flip_v
	afterimage.modulate = afterimage_modulate
	
	# Add to scene tree (not as child of actor, so it stays in place)
	parent.add_child(afterimage)
	
	# Fade out and remove afterimage
	# Use afterimage's own tween to ensure it completes even if component is freed
	var tween = afterimage.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, 0.5)
	tween.tween_callback(afterimage.queue_free)

func get_last_direction() -> Vector2:
	# Delegates to the actor's method; falls back to Vector2.RIGHT if unavailable
	if actor and actor.has_method("get_last_direction"):
		return actor.get_last_direction()
	return Vector2.RIGHT

func is_in_dodge() -> bool:
	"""Returns true if currently dodging"""
	return is_dodging

func is_currently_invincible() -> bool:
	"""Returns true if currently invincible"""
	return invincibility_timer > 0.0

func can_perform_dodge() -> bool:
	"""Returns true if dodge can be performed"""
	return can_dodge and not is_dodging and _get_current_atp() >= dodge_atp_cost

# --- NEW: Energy System Compatibility Helpers ---

## Get current ATP using new StatSystem (preferred) or old metabolisme_component (fallback).
func _get_current_atp() -> float:
	# Try new ECS-lite system via actor's entity_id
	if actor and actor.get("entity_id"):
		var eid: int = actor.entity_id
		if eid >= 0:
			var stat_system = ServiceRegistry.get_service("StatSystem")
			if stat_system:
				return stat_system.get_stat_value(eid, "atp", 0.0)
	# Fallback: old component chain
	if actor and actor.get("attribute_component") and actor.attribute_component and actor.attribute_component.metabolism_component:
		return actor.attribute_component.metabolism_component.get_current_atp()
	return -1.0

## Consume ATP using BOTH new ResourcePoolSystem AND old metabolism component.
## Dual-writing ensures old signals fire while new system becomes authoritative.
func _consume_atp(amount: float) -> void:
	if actor and actor.get("entity_id"):
		var eid: int = actor.entity_id
		if eid >= 0:
			var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
			if pool_system:
				pool_system.consume(eid, "atp", amount)
	if actor and actor.get("attribute_component") and actor.attribute_component and actor.attribute_component.metabolism_component:
		actor.attribute_component.metabolism_component.consume_atp(amount)
