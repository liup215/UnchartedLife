# speed_component.gd
extends Node
class_name SpeedComponent

signal speed_changed(current_speed: float, base_speed: float)

@export var data_source: ActorData # 外部数据源（如 actor_data 或 player_data_global）

func _ready() -> void:
	pass

func set_actor_data(data: ActorData) -> void:
	data_source = data
	emit_signal("speed_changed", data_source.current_speed, data_source.base_speed)

func set_current_speed(value: float):
	var old = data_source.current_speed
	data_source.current_speed = max(0.0, value)
	if data_source.current_speed != old:
		emit_signal("speed_changed", data_source.current_speed, old)

func get_current_speed() -> float:
	return data_source.current_speed

func get_base_speed() -> float:
	return data_source.base_speed

func reset_speed():
	set_current_speed(data_source.base_speed)
