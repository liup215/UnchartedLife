# combo_system.gd
# Manages combo state, stage progression, and timing for light attacks
extends Node
class_name ComboSystem

var combo_counter: int = 0
var combo_stage: int = 0
var last_combo_time: float = 0.0
var combo_reset_time: float = 0.5

signal combo_updated(combo_count: int, combo_stage: int)
signal combo_stage_changed(stage: int, combo_data: ComboAttackData)
signal simple_attack_performed(weapon_count: int)
signal attack_cost_calculated(atp_cost: float)


func setup(reset_time: float = 0.5) -> void:
	combo_reset_time = reset_time


func can_continue_combo() -> bool:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	return (current_time - last_combo_time) <= combo_reset_time


func get_next_stage(weapon_data: WeaponData) -> int:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_combo_time > combo_reset_time:
		combo_counter = 0
		combo_stage = 0

	var stage: int = combo_counter % weapon_data.combo_attacks.size()
	return stage


func advance_combo(weapon_data: WeaponData) -> ComboAttackData:
	var stage: int = get_next_stage(weapon_data)
	combo_stage = stage
	var combo_data: ComboAttackData = weapon_data.combo_attacks[stage]
	combo_counter += 1
	last_combo_time = Time.get_ticks_msec() / 1000.0
	combo_updated.emit(combo_counter, combo_stage)
	combo_stage_changed.emit(combo_stage, combo_data)
	return combo_data


func plan_reset_timer(
	weapon_data: WeaponData,
	combo_data: ComboAttackData,
	tree: SceneTree,
	reset_callable: Callable
) -> void:
	if combo_counter >= weapon_data.combo_attacks.size():
		var final_stage_window: float = combo_data.combo_window if combo_data else combo_reset_time
		if tree:
			var timer: SceneTreeTimer = tree.create_timer(final_stage_window)
			timer.timeout.connect(reset_callable, ConnectFlags.CONNECT_ONE_SHOT)


func reset_combo() -> void:
	combo_counter = 0
	combo_stage = 0
	combo_updated.emit(combo_counter, combo_stage)
