# metabolism_component.gd
extends Node
class_name MetabolismComponent

signal atp_changed(current_atp: float, max_atp: float)
signal glucose_changed(current_glucose: float, max_glucose: float)
signal atp_depleted()
signal glucose_depleted()

# 外部数据源（如 actor_data 或 player_data_global）
# @export var data_source: ActorData

# # 运行时状态
var current_atp: float = 0.0
var current_glucose: float = 0.0

# # 配置参数（初始化时从 data_source 读取）
var max_atp: int = 100
var max_glucose: int = 100
var atp_consume_rate: float = 1.0
var glucose_consume_rate: float = 0.1
var atp_production_rate: float = 5.0
var atp_conversion_rate: float = 5.0

func _ready():
	pass

func set_actor_data(data: Resource):
	current_atp = data.current_atp
	current_glucose = data.current_glucose
	max_atp = data.max_atp
	max_glucose = data.max_glucose
	atp_consume_rate = data.atp_consume_rate
	glucose_consume_rate = data.glucose_consume_rate
	atp_production_rate = data.atp_production_rate
	atp_conversion_rate = data.atp_conversion_rate
	
	# Emit initial signals to update UI
	atp_changed.emit(current_atp, max_atp)
	glucose_changed.emit(current_glucose, max_glucose)

func consume_atp(amount: float) -> bool:
	if current_atp >= amount:
		current_atp -= amount
		atp_changed.emit(current_atp, max_atp)
		if current_atp <= 0.0:
			atp_depleted.emit()
		return true
	else:
		current_atp = 0.0
		atp_changed.emit(current_atp, max_atp)
		atp_depleted.emit()
		return false
	# if data_source.current_atp >= amount:
	# 	data_source.current_atp -= amount
	# 	atp_changed.emit(data_source.current_atp, data_source.max_atp)
	# 	if data_source.current_atp <= 0.0:
	# 		atp_depleted.emit()
	# 	return true
	# else:
	# 	data_source.current_atp = 0.0
	# 	atp_changed.emit(data_source.current_atp, data_source.max_atp)
	# 	atp_depleted.emit()
	# 	return false

func recover_atp(amount: float):
	# data_source.current_atp = clamp(data_source.current_atp + amount, 0.0, data_source.max_atp)
	# atp_changed.emit(data_source.current_atp, data_source.max_atp)
	current_atp = clamp(current_atp + amount, 0.0, max_atp)
	atp_changed.emit(current_atp, max_atp)

func consume_glucose(amount: float) -> bool:
	# if data_source.current_glucose >= amount:
	# 	data_source.current_glucose -= amount
	# 	glucose_changed.emit(data_source.current_glucose, data_source.max_glucose)
	# 	if data_source.current_glucose <= 0.0:
	# 		glucose_depleted.emit()
	# 	return true
	# else:
	# 	data_source.current_glucose = 0.0
	# 	glucose_changed.emit(data_source.current_glucose, data_source.max_glucose)
	# 	glucose_depleted.emit()
	# 	return false
	if current_glucose >= amount:
		current_glucose -= amount
		glucose_changed.emit(current_glucose, max_glucose)
		if current_glucose <= 0.0:
			glucose_depleted.emit()
		return true
	else:
		current_glucose = 0.0
		glucose_changed.emit(current_glucose, max_glucose)
		glucose_depleted.emit()
		return false

func recover_glucose(amount: float):
	# data_source.current_glucose = clamp(data_source.current_glucose + amount, 0.0, data_source.max_glucose)
	# glucose_changed.emit(data_source.current_glucose, data_source.max_glucose)
	current_glucose = clamp(current_glucose + amount, 0.0, max_glucose)
	glucose_changed.emit(current_glucose, max_glucose)

# 每帧/每tick调用，统一处理代谢
func update_metabolism(delta: float):
	# 基础消耗
	# consume_glucose(data_source.glucose_consume_rate * delta)
	# ATP消耗（如有持续消耗需求，可在此处理）
	consume_atp(atp_consume_rate * delta)
	# ATP生成
	produce_atp_from_glucose(delta)

func produce_atp_from_glucose(delta: float):
	# 按比例消耗glucose生成atp
	# var atp_needed = data_source.max_atp - data_source.current_atp
	# if atp_needed <= 0.0:
	# 	return
	# var glucose_available = data_source.current_glucose
	# var atp_can_produce = min(data_source.atp_production_rate * delta, atp_needed)
	# var glucose_required = atp_can_produce / data_source.atp_conversion_rate
	# if glucose_available >= glucose_required:
	# 	consume_glucose(glucose_required)
	# 	recover_atp(atp_can_produce)
	# else:
	# 	# 只用剩余glucose生成atp
	# 	var atp_from_glucose = glucose_available * data_source.atp_conversion_rate
	# 	consume_glucose(glucose_available)
	# 	recover_atp(atp_from_glucose)
	var atp_needed = max_atp - current_atp
	if atp_needed <= 0.0:
		return
	var glucose_available = current_glucose
	var atp_can_produce = min(atp_production_rate * delta, atp_needed)
	var glucose_required = atp_can_produce / atp_conversion_rate
	if glucose_available >= glucose_required:
		consume_glucose(glucose_required)
		recover_atp(atp_can_produce)
	else:
		# 只用剩余glucose生成atp
		var atp_from_glucose = glucose_available * atp_conversion_rate
		consume_glucose(glucose_available)
		recover_atp(atp_from_glucose)

func get_current_atp() -> float:
	# return data_source.current_atp
	return current_atp

func get_max_atp() -> int:
	# return data_source.max_atp
	return max_atp

func get_current_glucose() -> float:
	# return data_source.current_glucose
	return current_glucose

func get_max_glucose() -> int:
	# return data_source.max_glucose
	return max_glucose

func get_atp_conversion_rate() -> float:
	# return data_source.atp_conversion_rate
	return atp_conversion_rate

func get_glucose_consume_rate() -> float:
	# return data_source.glucose_consume_rate
	return glucose_consume_rate

# Serialization methods for save/load
func to_dict() -> Dictionary:
	return {
		"current_atp": current_atp,
		"current_glucose": current_glucose,
		"max_atp": max_atp,
		"max_glucose": max_glucose,
		"atp_consume_rate": atp_consume_rate,
		"glucose_consume_rate": glucose_consume_rate,
		"atp_production_rate": atp_production_rate,
		"atp_conversion_rate": atp_conversion_rate
	}

func from_dict(data: Dictionary) -> void:
	current_atp = data.get("current_atp", current_atp)
	current_glucose = data.get("current_glucose", current_glucose)
	max_atp = data.get("max_atp", max_atp)
	max_glucose = data.get("max_glucose", max_glucose)
	atp_consume_rate = data.get("atp_consume_rate", atp_consume_rate)
	glucose_consume_rate = data.get("glucose_consume_rate", glucose_consume_rate)
	atp_production_rate = data.get("atp_production_rate", atp_production_rate)
	atp_conversion_rate = data.get("atp_conversion_rate", atp_conversion_rate)
	
	# Emit signals to update UI after loading
	atp_changed.emit(current_atp, max_atp)
	glucose_changed.emit(current_glucose, max_glucose)
