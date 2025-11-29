# chase_player_behavior_data.gd
# An AI behavior that makes an actor chase the player.
extends AIBehaviorData
class_name ChasePlayerBehaviorData

@export var detection_radius: float = 400.0

func get_detection_radius() -> float:
    return detection_radius

# We need to store state per actor instance.
var chase_states: Dictionary = {}

func execute(actor: Node, _delta: float):
    if not chase_states.has(actor):
        chase_states[actor] = { "player": null }

    var state = chase_states[actor]

    # Try to find the player if we haven't already
    if not is_instance_valid(state.player):
        state.player = actor.get_tree().get_first_node_in_group("player")

    # If player is found, run AI logic.
    if is_instance_valid(state.player):
        var distance_to_player = actor.global_position.distance_to(state.player.global_position)

        if distance_to_player < detection_radius:
            var direction_to_player = actor.global_position.direction_to(state.player.global_position)
            actor.velocity = direction_to_player * actor.attribute_component.speed_component.get_current_speed()
        else:
            # If player is out of range, this behavior does nothing,
            # allowing other behaviors (like wandering) to take over.
            pass
    else:
        # Player not found, do nothing.
        pass
