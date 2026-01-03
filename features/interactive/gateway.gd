extends Area2D
class_name Gateway

# Target scene ID (must match a GameSceneData.scene_id)
@export var target_scene_id: String = ""
# Target spawn point ID in the destination scene
@export var target_spawn_id: String = "default"
# Optional: Conditions required to use this gateway
@export var required_conditions: Array[Resource] = [] 

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _check_conditions():
			print("Gateway: Requesting transition to '%s' at '%s'" % [target_scene_id, target_spawn_id])
			EventBus.request_scene_transition.emit(target_scene_id, target_spawn_id)
		else:
			print("Gateway: Conditions not met")
			# TODO: Show UI feedback

func _check_conditions() -> bool:
	# Implement condition checking logic here
	# For now, just return true
	return true
