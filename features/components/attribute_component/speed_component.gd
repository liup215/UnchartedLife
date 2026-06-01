# speed_component.gd
extends Node
class_name SpeedComponent

signal speed_changed(current_speed: float, base_speed: float)

# @export var data_source: ActorData # 外部数据源（如 actor_data 或 player_data_global）
var current_speed: float = 100.0
var base_speed: float = 100.0

func _ready() -> void:
	pass

func set_actor_data(data: ActorData) -> void:
	# data_source = data
	# emit_signal("speed_changed", data_source.current_speed, data_source.base_speed)
	current_speed = data.current_speed
	base_speed = data.base_speed
	emit_signal("speed_changed", current_speed, base_speed)

func set_current_speed(value: float):
	# var old = data_source.current_speed
	# data_source.current_speed = max(0.0, value)
	# if data_source.current_speed != old:
	# 	emit_signal("speed_changed", data_source.current_speed, old)
	var old = current_speed
	current_speed = max(0.0, value)
	if current_speed != old:
		emit_signal("speed_changed", current_speed, base_speed)

func get_current_speed() -> float:
	# return data_source.current_speed
	return current_speed

func get_base_speed() -> float:
	# return data_source.base_speed
	return base_speed

func reset_speed():
	# set_current_speed(data_source.base_speed)
	set_current_speed(base_speed)
