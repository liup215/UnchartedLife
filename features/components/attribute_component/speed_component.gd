# speed_component.gd
extends Node
class_name SpeedComponent

signal speed_changed(current_speed: float, base_speed: float)

# @export var data_source: ActorData # 外部数据源（如 actor_data 或 player_data_global）
var current_speed: float = 100.0
var base_speed: float = 100.0

func _ready() -> void:
	pass

func set_runtime_state(rs: ActorRuntimeState) -> void:
	current_speed = rs.current_speed
	base_speed = rs.base_speed
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

## Get actor entity_id from parent chain (SpeedComponent -> AttributeComponent -> Actor)
func _get_actor_entity_id() -> int:
	var attribute_comp: Node = get_parent()
	if attribute_comp and attribute_comp.get_parent():
		var actor = attribute_comp.get_parent()
		if actor and actor.get("entity_id"):
			return int(actor.entity_id)
	return -1

func get_current_speed() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "speed", current_speed)
	return current_speed

func get_base_speed() -> float:
	return base_speed

func reset_speed():
	# set_current_speed(data_source.base_speed)
	set_current_speed(base_speed)
