# atp_component.gd
# Manages an actor's ATP (Adenosine Triphosphate), which is used for basic actions.
extends Node

class_name ATPComponent

signal atp_changed(current_atp: int, max_atp: int)
signal atp_depleted()

var current_atp: float = 0.0:
    set(value):
        current_atp = clamp(value, 0.0, max_atp)
        atp_changed.emit(int(current_atp), max_atp)
        if current_atp <= 0.0:
            atp_depleted.emit()

var max_atp: int = 100

func set_max_atp(value: int):
    max_atp = value
    self.current_atp = float(max_atp) # Fully restore ATP when max is set/changed

func consume_atp(amount: float) -> bool:
    if current_atp >= amount:
        self.current_atp -= amount
        return true
    else:
        # Consume whatever ATP is available
        self.current_atp = 0.0
        return false

func recover_atp(amount: float):
    self.current_atp += amount

func get_current_atp() -> int:
    return int(current_atp)

func get_max_atp() -> int:
    return max_atp
