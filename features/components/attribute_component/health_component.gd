# health_component.gd
extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal died

# @export var data_source: ActorData # 与 metabolism_component、speed_component 一致

var max_health: int = 100
var current_health: int = 100
var is_invincible: bool = false  # Invincibility flag for dodge and other effects

func _ready():
	pass

func set_actor_data(ds: ActorData):
	# data_source = ds
	max_health = ds.max_health
	current_health = ds.current_health
	# emit_signal("health_changed", data_source.current_health, data_source.max_health)
	emit_signal("health_changed", current_health, max_health)

func set_current_health(value: int):
	# var old = data_source.current_health
	# data_source.current_health = clamp(value, 0, data_source.max_health)
	# if data_source.current_health != old:
	# 	emit_signal("health_changed", data_source.current_health, data_source.max_health)
	# if data_source.current_health == 0:
	# 	emit_signal("died")
	var old = current_health
	current_health = clamp(value, 0, max_health)
	if current_health != old:
		emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		emit_signal("died")

func take_damage(amount: int):
	# Check invincibility flag
	if is_invincible:
		return  # No damage taken when invincible
	
	# set_current_health(data_source.current_health - amount)
	set_current_health(current_health - amount)

func heal(amount: int):
	# set_current_health(data_source.current_health + amount)
	set_current_health(current_health + amount)

func set_max_health(new_max: int, heal_to_full: bool = true):
	# data_source.max_health = new_max
	# if heal_to_full:
	# 	data_source.current_health = data_source.max_health
	# else:
	# 	data_source.current_health = min(data_source.current_health, data_source.max_health)
	# emit_signal("health_changed", data_source.current_health, data_source.max_health)
	max_health = new_max
	if heal_to_full:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

func get_current_health() -> int:
	# return data_source.current_health
	return current_health

func get_max_health() -> int:
	# return data_source.max_health
	return max_health

func set_invincible(invincible: bool):
	"""Set invincibility state"""
	is_invincible = invincible

func get_is_invincible() -> bool:
	"""Get invincibility state"""
	return is_invincible
