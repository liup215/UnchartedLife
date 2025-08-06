# PatrolBehaviorData.gd
# An AI behavior that makes an actor patrol within a given radius.
extends AIBehaviorData
class_name PatrolBehaviorData

@export var patrol_radius: float = 200.0
@export var patrol_speed: float = 80.0

var patrol_states: Dictionary = {}

func _ready():
	name = "Patrol Behavior"

func should_execute(actor: Node) -> bool:
	# 巡逻：玩家距离大于检测距离时执行
	var player = actor.get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var chase_behavior = null
		# 查找chase行为以获取检测距离
		if actor.actor_data:
			for behavior in actor.actor_data.behaviors:
				if behavior and behavior.has_method("get_detection_radius"):
					chase_behavior = behavior
					break
		var detection_radius = 400.0
		if chase_behavior:
			detection_radius = chase_behavior.get_detection_radius()
		var distance = actor.global_position.distance_to(player.global_position)
		return distance > detection_radius
	return true

func execute(actor: Node, _delta: float):
	if not patrol_states.has(actor):
		var origin = actor.global_position
		patrol_states[actor] = {
			"origin": origin,
			"target": origin,
			"timer": 0.0
		}

	var state = patrol_states[actor]
	state.timer -= _delta

	# If timer expired or reached target, pick a new target within patrol_radius
	if state.timer <= 0.0 or actor.global_position.distance_to(state.target) < 10.0:
		var angle = randf() * TAU
		var offset = Vector2(cos(angle), sin(angle)) * patrol_radius
		state.target = state.origin + offset
		state.timer = randf_range(1.0, 3.0)

	# Move towards target
	var direction = actor.global_position.direction_to(state.target)
	actor.velocity = direction * patrol_speed
