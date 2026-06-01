# wander_behavior_data.gd
# An AI behavior that makes an actor wander around randomly.
extends AIBehaviorData
class_name WanderBehaviorData

@export var wander_speed_multiplier: float = 0.5
@export var wander_interval: float = 3.0

# We need to store state per actor instance, so we use a dictionary.
var wander_states: Dictionary = {}

func execute(actor: Node, _delta: float):
	if not wander_states.has(actor):
		# Initialize state for this actor instance
		wander_states[actor] = {
			"timer": wander_interval,
			"direction": Vector2.ZERO
		}
		_update_wander_direction(actor)

	var state = wander_states[actor]
	state.timer -= _delta
	if state.timer <= 0:
		_update_wander_direction(actor)
		state.timer = wander_interval

	# NEW: Prefer StatSystem for speed read (Wave 2 migration)
	var speed: float = 0.0
	if actor is Actor and actor.entity_id >= 0:
		var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			speed = stat_system.get_stat_value(actor.entity_id, "speed", 250.0)
	else:
		if actor.attribute_component and actor.attribute_component.speed_component:
			speed = actor.attribute_component.speed_component.get_current_speed()
	actor.velocity = state.direction * (speed * wander_speed_multiplier)

func _update_wander_direction(actor: Node):
	var state = wander_states[actor]
	state.direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
