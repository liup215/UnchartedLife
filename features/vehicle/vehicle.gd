# vehicle.gd
# The base vehicle class for RigidBody2D tank-style control.
extends RigidBody2D

class_name Vehicle

@export var vehicle_data: VehicleData
@onready var stats_component: VehicleStatsComponent = $VehicleStatsComponent
@onready var visuals: ColorRect = $Visuals
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_ui: Control = $InteractionUI
@onready var interaction_label: Label = $InteractionUI/InteractionLabel
@onready var vehicle_camera: Camera2D = $Camera2D

# Vehicle state
var occupied: bool = false
var driver: Node2D = null
var player_camera: Camera2D = null

func _ready():
	add_to_group("vehicle")
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	if visuals:
		visuals.color = Color.DARK_GRAY
		visuals.size = Vector2(48, 64)

 # Ensure the stats component has the data it needs
	if stats_component:
		stats_component.vehicle_data = vehicle_data
		stats_component.recalculate_stats()

func _physics_process(delta: float):
	if occupied and driver and stats_component.can_move:
		_handle_vehicle_movement(delta)
		_consume_fuel(delta)
	else:
		# Auto-dampening when idle or overloaded
		linear_damp = 8
		angular_damp = 8

func _handle_vehicle_movement(_delta: float):
	# Only allow forward/backward movement and turning
	var move_input = 0
	var turn_input = 0

	if Input.is_action_pressed("move_forward"):
		move_input += 1
	if Input.is_action_pressed("move_backward"):
		move_input -= 1
	if Input.is_action_pressed("turn_left"):
		turn_input -= 1
	if Input.is_action_pressed("turn_right"):
		turn_input += 1

	# Reset angular velocity each frame
	angular_velocity = 0

	# Forward/Backward Movement
	if move_input != 0:
		var forward = Vector2.UP.rotated(rotation)
		var force = forward * stats_component.final_acceleration * move_input
		apply_central_force(force)
		# Speed Limiter
		if linear_velocity.length() > stats_component.final_max_speed:
			linear_velocity = linear_velocity.normalized() * stats_component.final_max_speed

	# Turning (Only allow turning while moving)
	if turn_input != 0:
		# Invert turning direction when reversing for realistic steering
		var effective_turn_speed = stats_component.final_max_speed / 150.0 # Example formula
		if move_input < 0:
			angular_velocity = effective_turn_speed * -turn_input
		else:
			angular_velocity = effective_turn_speed * turn_input

	# Auto-dampening at low speed
	if move_input == 0:
		linear_damp = 8
	else:
		linear_damp = 2

func _consume_fuel(_delta: float):
	# More detailed fuel consumption based on engine efficiency
	var total_glucose_efficiency = 0.0
	var engine_count = 0
	for engine_res in vehicle_data.engine_slots:
		if engine_res is EngineData:
			var engine: EngineData = engine_res
			total_glucose_efficiency += engine.glucose_efficiency
			engine_count += 1

	if engine_count > 0:
		var avg_efficiency = total_glucose_efficiency / engine_count
		var _consumption_rate = 1.0 / avg_efficiency # Base consumption is inverse of efficiency

		# Consume more fuel at higher speeds
		var speed_ratio = linear_velocity.length() / stats_component.final_max_speed if stats_component.final_max_speed > 0 else 0
		_consumption_rate += speed_ratio * 2.0 # Additional consumption based on speed

		# TODO: Link this to the global player glucose store
		# current_fuel = max(0, current_fuel - _consumption_rate * _delta)
	pass

func _on_body_entered(body: Node2D):
	if body.has_method("show_vehicle_interaction") and not occupied:
		body.show_vehicle_interaction(self)
		_show_interaction_ui(true)

func _on_body_exited(body: Node2D):
	if body.has_method("hide_vehicle_interaction"):
		body.hide_vehicle_interaction()
		_show_interaction_ui(false)

func _show_interaction_ui(should_show: bool):
	if interaction_ui:
		interaction_ui.visible = should_show
	if should_show and interaction_label and vehicle_data:
		interaction_label.text = get_interaction_text()

func can_be_entered() -> bool:
	return not occupied

func enter_vehicle(player: Node2D) -> bool:
	if not can_be_entered():
		return false
	occupied = true
	driver = player
	# Switch camera
	if player.has_node("Camera2D"):
		player_camera = player.get_node("Camera2D")
		player_camera.enabled = false
	if vehicle_camera:
		vehicle_camera.enabled = true
	player.set_in_vehicle_state(true)
	return true

func exit_vehicle() -> bool:
	if not occupied:
		return false

	var ejected_player = driver
	occupied = false
	driver = null

	# Stop vehicle movement
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

	# Switch camera back
	if vehicle_camera:
		vehicle_camera.enabled = false
	if player_camera:
		player_camera.enabled = true
	player_camera = null

	# Place player at the vehicle's position and re-enable them
	if ejected_player:
		ejected_player.global_position = global_position
		if ejected_player.has_method("set_in_vehicle_state"):
			ejected_player.set_in_vehicle_state(false)

	return true

func get_interaction_text() -> String:
	if can_be_entered():
		return "Press E to enter " + (vehicle_data.vehicle_name if vehicle_data else "Vehicle")
	else:
		return "Vehicle occupied"
