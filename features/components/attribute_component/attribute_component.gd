# attribute_component.gd
extends Node2D
class_name AttributeComponent

@onready var health_component: HealthComponent = $HealthComponent
@onready var metabolism_component: MetabolismComponent = $MetabolismComponent
@onready var speed_component: SpeedComponent = $SpeedComponent_gd
@onready var toughness_component: ToughnessComponent = $ToughnessComponent if has_node("ToughnessComponent") else null

func set_actor_data(data: ActorData):
	health_component.set_actor_data(data)
	metabolism_component.set_actor_data(data)
	speed_component.set_actor_data(data)
	if toughness_component:
		toughness_component.set_actor_data(data)

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
