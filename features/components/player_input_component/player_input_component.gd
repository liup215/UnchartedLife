# player_input_component.gd
# Encapsulates input device reading into high-level intent signals.
# Player.gd reads desired state from this component instead of calling Input directly.
extends Node2D
class_name PlayerInputComponent

# High-level player intents (updated each frame)
var desired_direction: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var should_dodge: bool = false
var should_interact: bool = false
var should_light_attack: bool = false
var should_heavy_attack: bool = false
var heavy_attack_released: bool = false

# Vehicle-specific inputs (filled when player is in vehicle)
var vehicle_move_input: int = 0   # -1=back, 0=none, 1=forward
var vehicle_turn_input: int = 0   # -1=left, 0=none, 1=right
var should_main_attack: bool = false
var main_attack_released: bool = false

# Mouse position in world space (for weapon aiming)
var aim_target: Vector2 = Vector2.ZERO

func _process(_delta: float):
	# Movement
	desired_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Sprint
	is_sprinting = Input.is_action_pressed("shift")
	
	# Dodge (one-shot)
	should_dodge = Input.is_action_just_pressed("dodge")
	
	# Vehicle / interaction
	should_interact = Input.is_action_just_pressed("enter_vehicle")
	
	# Combat intents
	should_light_attack = Input.is_action_just_pressed("light_attack")
	should_heavy_attack = Input.is_action_just_pressed("heavy_attack")
	heavy_attack_released = Input.is_action_just_released("heavy_attack")
	should_main_attack = Input.is_action_just_pressed("main_attack")
	main_attack_released = Input.is_action_just_released("main_attack")
	
	# Vehicle inputs (tank-style)
	vehicle_move_input = 0
	if Input.is_action_pressed("move_forward"):
		vehicle_move_input = 1
	elif Input.is_action_pressed("move_backward"):
		vehicle_move_input = -1
	vehicle_turn_input = 0
	if Input.is_action_pressed("turn_right"):
		vehicle_turn_input = 1
	elif Input.is_action_pressed("turn_left"):
		vehicle_turn_input = -1
	
	# Aim target
	aim_target = get_global_mouse_position()

## Reset transient one-shot flags after they have been consumed.
func consume_transient_intents():
	should_dodge = false
	should_interact = false
	should_light_attack = false
	should_heavy_attack = false
	heavy_attack_released = false
	should_main_attack = false
	main_attack_released = false