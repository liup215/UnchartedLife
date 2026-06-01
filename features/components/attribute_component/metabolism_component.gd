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
var max_atp: float = 100.0
var max_glucose: float = 100.0
var atp_consume_rate: float = 1.0
var glucose_consume_rate: float = 0.1
var atp_production_rate: float = 5.0
var atp_conversion_rate: float = 5.0

func _ready():
	pass

func set_runtime_state(rs: ActorRuntimeState):
	current_atp = rs.current_atp
	current_glucose = rs.current_glucose
	max_atp = rs.max_atp
	max_glucose = rs.max_glucose
	atp_consume_rate = rs.atp_consume_rate
	glucose_consume_rate = rs.glucose_consume_rate
	atp_production_rate = rs.atp_production_rate
	atp_conversion_rate = rs.atp_conversion_rate
	
	# Emit initial signals to update UI
	atp_changed.emit(current_atp, max_atp)
	glucose_changed.emit(current_glucose, max_glucose)

func consume_atp(amount: float) -> bool:
	if current_atp >= amount:
		current_atp -= amount
		_sync_new_system_stat("atp", current_atp)
		atp_changed.emit(current_atp, max_atp)
		if current_atp <= 0.0:
			atp_depleted.emit()
		return true
	else:
		current_atp = 0.0
		_sync_new_system_stat("atp", 0.0)
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
	current_atp = clamp(current_atp + amount, 0.0, max_atp)
	_sync_new_system_stat("atp", current_atp)
	atp_changed.emit(current_atp, max_atp)

func consume_glucose(amount: float) -> bool:
	if current_glucose >= amount:
		current_glucose -= amount
		_sync_new_system_stat("glucose", current_glucose)
		glucose_changed.emit(current_glucose, max_glucose)
		if current_glucose <= 0.0:
			glucose_depleted.emit()
		return true
	else:
		current_glucose = 0.0
		_sync_new_system_stat("glucose", 0.0)
		glucose_changed.emit(current_glucose, max_glucose)
		glucose_depleted.emit()
		return false

func recover_glucose(amount: float):
	current_glucose = clamp(current_glucose + amount, 0.0, max_glucose)
	_sync_new_system_stat("glucose", current_glucose)
	glucose_changed.emit(current_glucose, max_glucose)

## Called per frame/tick to process metabolic updates.
func update_metabolism(delta: float) -> void:
	# Base ATP consumption
	consume_atp(atp_consume_rate * delta)
	# ATP generation from glucose
	produce_atp_from_glucose(delta)

## Converts available glucose into ATP.
func produce_atp_from_glucose(delta: float) -> void:
	var atp_needed: float = max_atp - current_atp
	if atp_needed <= 0.0:
		return
	var glucose_available: float = current_glucose
	var atp_can_produce: float = min(atp_production_rate * delta, atp_needed)
	var glucose_required: float = atp_can_produce / atp_conversion_rate
	if glucose_available >= glucose_required:
		consume_glucose(glucose_required)
		recover_atp(atp_can_produce)
	else:
		# Use remaining glucose to regenerate as much ATP as possible
		var atp_from_glucose: float = glucose_available * atp_conversion_rate
		consume_glucose(glucose_available)
		recover_atp(atp_from_glucose)

## Get actor entity_id from parent (AttributeComponent -> Actor)
## Sync current value to the new StatSystem.
func _sync_new_system_stat(stat_id: String, value: float) -> void:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			stat_system.set_stat_value(eid, stat_id, value)

func _get_actor_entity_id() -> int:
	var attribute_comp: Node = get_parent()
	if attribute_comp and attribute_comp.get_parent():
		var actor = attribute_comp.get_parent()
		if actor and actor.get("entity_id"):
			return int(actor.entity_id)
	return -1

func get_current_atp() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp", current_atp)
	return current_atp

func get_max_atp() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "max_atp", max_atp)
	return max_atp

func get_current_glucose() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "glucose", current_glucose)
	return current_glucose

func get_max_glucose() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "max_glucose", max_glucose)
	return max_glucose

func get_atp_conversion_rate() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp_conversion_rate", atp_conversion_rate)
	return atp_conversion_rate

func get_glucose_consume_rate() -> float:
	var eid: int = _get_actor_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "glucose_consume_rate", glucose_consume_rate)
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
	
	# Validate loaded values
	current_atp = clamp(current_atp, 0.0, max_atp)
	current_glucose = clamp(current_glucose, 0.0, max_glucose)
	max_atp = max(max_atp, 1.0)
	max_glucose = max(max_glucose, 1.0)
	atp_consume_rate = max(atp_consume_rate, 0.0)
	glucose_consume_rate = max(glucose_consume_rate, 0.0)
	atp_production_rate = max(atp_production_rate, 0.0)
	atp_conversion_rate = max(atp_conversion_rate, 0.1)  # Prevent division by zero
	
	# Emit signals to update UI after loading
	atp_changed.emit(current_atp, max_atp)
	glucose_changed.emit(current_glucose, max_glucose)
