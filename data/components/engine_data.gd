# data/components/engine_data.gd
# Defines the properties of a vehicle engine.
extends Resource
class_name EngineData

@export_group("Core Properties")
## The name of the engine.
@export var engine_name: String = "Standard Engine"
## The weight of the engine itself.
@export var weight: float = 200.0
## The maximum weight the engine can support (chassis + all components).
@export var max_load: float = 2000.0
## The engine's power output, used to calculate acceleration and top speed.
@export var power_output: float = 500.0

@export_group("Energy Consumption")
## How efficiently the engine converts glucose to power. Higher is better.
@export var glucose_efficiency: float = 1.0
