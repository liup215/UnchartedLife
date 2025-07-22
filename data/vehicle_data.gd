# vehicle_data.gd
# A resource that holds all the defining data for a vehicle.
# This allows for easy creation of new vehicle types by creating new .tres files.
extends Resource

class_name VehicleData

# --- Basic Vehicle Properties ---
@export_group("基础属性")
## The name of this vehicle type
@export var vehicle_name: String = "Basic Tank"
## The vehicle's armor value for damage resistance
@export var armor_value: int = 100
## Maximum movement speed of the vehicle
@export var max_speed: float = 150.0
## Base glucose consumption per second when running
@export var glucose_consumption_rate: float = 2.0
## Vehicle weight affects acceleration and fuel efficiency
@export var weight: float = 1000.0

@export_group("能效属性")
## Multiplier for glucose consumption based on speed (higher = more efficient)
@export var fuel_efficiency: float = 1.0
## Additional consumption when accelerating
@export var acceleration_cost_multiplier: float = 1.5

@export_group("操控属性")
## How quickly the vehicle can turn
@export var turn_speed: float = 2.0
## How quickly the vehicle accelerates to max speed
@export var acceleration: float = 300.0
## How quickly the vehicle decelerates
@export var deceleration: float = 400.0

# --- Helper Functions ---
func get_max_speed() -> float:
    return max_speed

func get_glucose_consumption_at_speed(current_speed: float, is_accelerating: bool = false) -> float:
    # Base consumption
    var consumption = glucose_consumption_rate
    
    # Speed-based consumption (more speed = more fuel)
    var speed_ratio = current_speed / max_speed
    consumption += glucose_consumption_rate * speed_ratio * (2.0 - fuel_efficiency)
    
    # Acceleration penalty
    if is_accelerating:
        consumption *= acceleration_cost_multiplier
    
    return consumption

func get_turn_speed() -> float:
    return turn_speed

func get_acceleration() -> float:
    return acceleration
    
func get_deceleration() -> float:
    return deceleration
