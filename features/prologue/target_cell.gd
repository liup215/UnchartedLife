## target_cell.gd
## The large cell that needs to be healed in the prologue
## Continuously loses HP and needs to be healed by player attacks
class_name TargetCell extends CharacterBody2D

signal health_changed(current: int, max_hp: int, percentage: float)
signal cell_healed()
signal cell_died()

# Constants
const BASE_SPRITE_SIZE: float = 32.0  # Base size of the sprite in pixels

@export var max_health: int = 1000
@export var health_drain_rate: float = 1.0  # HP per second to drain
@export var victory_health: int = 500  # HP needed to win
@export var cell_size: float = 200.0  # Visual size

var current_health: int = 100  # Start with low health
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var label: Label = $Label

func _ready():
	_setup_visuals()
	_update_health_display()
	
	# Add to group for easy identification
	add_to_group("target_cell")
	add_to_group("ally")  # So it's recognized as friendly

func _setup_visuals():
	# Set up a large circular sprite for the cell
	sprite.modulate = Color(0.8, 0.3, 0.3, 0.7)  # Reddish, semi-transparent
	sprite.scale = Vector2(cell_size / BASE_SPRITE_SIZE, cell_size / BASE_SPRITE_SIZE)
	
	# Set label
	if label:
		label.text = "Dying Cell"
		label.add_theme_font_size_override("font_size", 24)

func _physics_process(delta: float):
	if is_dead:
		return
	
	# Continuously drain health
	_drain_health(health_drain_rate * delta)
	
	# Pulse animation to show it's alive/dying
	_animate_pulse(delta)

func _drain_health(amount: float):
	current_health -= int(amount)
	current_health = max(0, current_health)
	_update_health_display()
	
	if current_health <= 0 and not is_dead:
		_die()

func heal(amount: int):
	if is_dead:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	_update_health_display()
	
	# Visual feedback for healing
	_flash_heal()
	
	# Check victory condition
	if current_health >= victory_health:
		_victory()

# This method is called by bullets that hit the cell
func take_damage(amount: int):
	# In this game, "damage" heals the cell instead!
	heal(amount)
	print("Cell hit! Healing for %d HP" % amount)

func _update_health_display():
	var health_percentage = float(current_health) / float(max_health)
	
	if health_bar:
		health_bar.value = health_percentage * 100
		health_bar.modulate = _get_health_color(health_percentage)
	
	# Emit signal
	health_changed.emit(current_health, max_health, health_percentage)

func _get_health_color(percentage: float) -> Color:
	# Red when low health, green when high health
	if percentage < 0.3:
		return Color.RED
	elif percentage < 0.5:
		return Color(1.0, 0.5, 0.0)  # Orange
	elif percentage < 0.7:
		return Color.YELLOW
	else:
		return Color.GREEN

func _animate_pulse(delta: float):
	# Pulse effect based on health
	var health_percentage = float(current_health) / float(max_health)
	var pulse_speed = 2.0 + (1.0 - health_percentage) * 3.0  # Faster when low health
	var pulse_amount = 0.05 + (1.0 - health_percentage) * 0.1
	
	var time = Time.get_ticks_msec() / 1000.0
	var pulse = sin(time * pulse_speed) * pulse_amount
	sprite.scale = Vector2.ONE * (cell_size / BASE_SPRITE_SIZE) * (1.0 + pulse)

func _flash_heal():
	# Flash green when healed
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.1)
	tween.tween_property(sprite, "modulate", Color(0.8, 0.3, 0.3, 0.7), 0.2)

func _die():
	is_dead = true
	cell_died.emit()
	print("Cell has died! Game Over.")
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _victory():
	print("Cell healed to victory health! You win!")
	cell_healed.emit()
	
	# Victory animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.5)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.5)
