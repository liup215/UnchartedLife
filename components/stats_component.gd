# stats_component.gd
# A reusable component for managing statistical data for an actor.
# It reads its base values from an ActorData resource.
class_name StatsComponent
extends Node

@export var data: ActorData

# You can add logic here to handle stat modifications from items, buffs, etc.
# For now, it's a simple container that exposes the data.

func get_move_speed() -> float:
    if data:
        return data.move_speed
    return 0.0

func get_max_health() -> int:
    if data:
        return data.max_health
    return 0
