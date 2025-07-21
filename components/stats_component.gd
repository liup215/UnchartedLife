# stats_component.gd
# A component that holds a reference to an ActorData resource
# and provides getter methods for its stats.
extends Node

class_name StatsComponent

@export var data: ActorData

func get_max_health() -> int:
    if data:
        return data.get_max_health()
    return 0

func get_max_atp() -> int:
    if data:
        return data.get_max_atp()
    return 0

func get_move_speed() -> float:
    if data:
        return data.get_move_speed()
    return 0.0
