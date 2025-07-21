# actor_data.gd
# A resource that holds all the defining data for an actor.
# This allows for easy creation of new actor types by creating new .tres files.
extends Resource

class_name ActorData

# --- Player Character Stats ---
@export_group("Base Physiological Indicators")
## The maximum health points of the actor's body.
@export var max_hp: int = 100
## Affects passive glucose consumption and natural ATP recovery.
@export var base_metabolic_rate: float = 0.1 # Glucose per second
## Affects the window size for "Just Frame" judgments.
@export var neural_response_speed: float = 1.0
## Affects vehicle control precision and combo success rate.
@export var muscle_coordination: float = 1.0
## The base movement speed of the actor/vehicle.
@export var move_speed: float = 250.0

@export_group("Bio-Energy Attributes")
## The maximum amount of ATP the actor can store for basic actions.
@export var max_atp: int = 100
## The efficiency of converting Glucose to ATP. (e.g., 1 glucose = 5 ATP)
@export var atp_conversion_rate: float = 5.0
## The maximum charge capacity for the main cannon system.
@export var hemo_energy_capacity: int = 100
## The difficulty threshold for triggering advanced skills.
@export var entropy_energy_threshold: int = 100

# --- Helper Functions ---
func get_max_health() -> int:
    return max_hp

func get_max_atp() -> int:
    return max_atp

# We will keep a move_speed function for now for compatibility with existing code,
# but it will be derived from vehicle stats later.
func get_move_speed() -> float:
    return move_speed
