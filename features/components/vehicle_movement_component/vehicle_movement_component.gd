# vehicle_movement_component.gd
# Handles tank-style physics movement for a Vehicle.
# Extracted from Vehicle._physics_process to decouple movement logic.
extends Node
class_name VehicleMovementComponent

@export var stats_component: VehicleStatsComponent
@export var animated_sprite: AnimatedSprite2D

func process_movement(vehicle: RigidBody2D, move_input: int, turn_input: int, _delta: float) -> void:
	if not stats_component:
		return

	# Reset angular velocity each frame
	vehicle.angular_velocity = 0

	# Forward/Backward Movement
	if move_input != 0:
		var forward = Vector2.UP.rotated(vehicle.rotation)
		var force = forward * stats_component.final_acceleration * move_input
		vehicle.apply_central_force(force)
		if animated_sprite:
			animated_sprite.play("moving")
		# Speed Limiter
		if vehicle.linear_velocity.length() > stats_component.final_max_speed:
			vehicle.linear_velocity = vehicle.linear_velocity.normalized() * stats_component.final_max_speed

	# Turning (Only allow turning while moving forward or backward)
	if turn_input != 0 and move_input != 0:
		var effective_turn_speed = stats_component.final_max_speed / 150.0
		if move_input < 0:
			vehicle.angular_velocity = effective_turn_speed * -turn_input
		else:
			vehicle.angular_velocity = effective_turn_speed * turn_input

	# Auto-dampening
	if move_input == 0:
		if animated_sprite:
			animated_sprite.stop()
		vehicle.linear_damp = 8
	else:
		vehicle.linear_damp = 2

func apply_idle_damping(vehicle: RigidBody2D) -> void:
	vehicle.linear_damp = 8
	vehicle.angular_damp = 8

func consume_fuel(vehicle_data: VehicleData, stats_component_ref: VehicleStatsComponent, current_speed: float, _delta: float) -> void:
	if not vehicle_data or not stats_component_ref:
		return
	var total_glucose_efficiency = 0.0
	var engine_count = 0
	for engine_res in vehicle_data.engine_slots:
		if engine_res is EngineData:
			total_glucose_efficiency += engine_res.glucose_efficiency
			engine_count += 1
	if engine_count > 0:
		var avg_efficiency = total_glucose_efficiency / engine_count
		var _consumption_rate = 1.0 / avg_efficiency
		var speed_ratio = current_speed / stats_component_ref.final_max_speed if stats_component_ref.final_max_speed > 0 else 0
		_consumption_rate += speed_ratio * 2.0
		# TODO: Link to global player glucose store
