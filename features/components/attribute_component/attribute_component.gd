# attribute_component.gd
extends Node2D
class_name AttributeComponent

@onready var health_component: HealthComponent = $HealthComponent
@onready var metabolism_component: MetabolismComponent = $MetabolismComponent
@onready var speed_component: SpeedComponent = $SpeedComponent
@onready var toughness_component: ToughnessComponent = $ToughnessComponent if has_node("ToughnessComponent") else null

func set_runtime_state(rs: ActorRuntimeState):
	health_component.set_runtime_state(rs)
	metabolism_component.set_runtime_state(rs)
	speed_component.set_runtime_state(rs)
	if toughness_component:
		toughness_component.set_runtime_state(rs)

# ATP delegation (used by combat, dodge, and item systems)
func get_current_atp() -> float:
	if metabolism_component:
		return metabolism_component.get_current_atp()
	return 0.0

func consume_atp(amount: float) -> bool:
	if metabolism_component:
		return metabolism_component.consume_atp(amount)
	return false

# 批量存档
func to_dict() -> Dictionary:
	var result = {
		"health": health_component.to_dict() if health_component else {},
		"metabolism": metabolism_component.to_dict() if metabolism_component else {},
		"speed": speed_component.to_dict() if speed_component else {}
	}
	if toughness_component:
		result["toughness"] = toughness_component.to_dict()
	return result

# 批量恢复
func from_dict(data: Dictionary):
	if health_component and data.has("health"):
		health_component.from_dict(data["health"])
	if metabolism_component and data.has("metabolism"):
		metabolism_component.from_dict(data["metabolism"])
	if speed_component and data.has("speed"):
		speed_component.from_dict(data["speed"])
	if toughness_component and data.has("toughness"):
		toughness_component.from_dict(data["toughness"])
