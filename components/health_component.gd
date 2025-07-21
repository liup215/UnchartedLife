# health_component.gd
# A reusable component for managing the health of any actor.
class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 100

var current_health: int:
    set(value):
        current_health = clamp(value, 0, max_health)
        emit_signal("health_changed", current_health, max_health)
        if current_health == 0:
            emit_signal("died")

func _ready():
    self.current_health = max_health

func take_damage(damage_amount: int):
    self.current_health -= damage_amount

func heal(heal_amount: int):
    self.current_health += heal_amount

func set_max_health(new_max: int, heal_to_full: bool = true):
    max_health = new_max
    if heal_to_full:
        self.current_health = max_health
    else:
        # Ensure current health doesn't exceed the new max
        self.current_health = min(current_health, max_health)

func get_current_health() -> int:
    return current_health

func get_max_health() -> int:
    return max_health
