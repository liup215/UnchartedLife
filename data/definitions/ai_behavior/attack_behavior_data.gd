# AttackBehaviorData.gd
# An AI behavior that makes an actor attack the player when in range.
extends AIBehaviorData
class_name AttackBehaviorData

@export var attack_radius: float = 2000.0
@export var attack_cooldown: float = 1.2
@export var attack_damage: int = 10

var attack_states: Dictionary = {}

func _ready():
	name = "Attack Behavior"

func should_execute(actor: Node) -> bool:
	# 攻击：玩家距离小于攻击距离时执行
	var player = actor.get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var distance = actor.global_position.distance_to(player.global_position)
		return distance <= attack_radius
	return false

func execute(actor: Node, _delta: float):
	if not attack_states.has(actor):
		attack_states[actor] = {
			"player": null,
			"cooldown": 0.0
		}

	var state = attack_states[actor]
	state.cooldown -= _delta

	# Find player if not cached
	if not is_instance_valid(state.player):
		state.player = actor.get_tree().get_first_node_in_group("player")

	if is_instance_valid(state.player):
		var distance_to_player = actor.global_position.distance_to(state.player.global_position)
		if distance_to_player <= attack_radius and state.cooldown <= 0.0:
			# 发射武器（子弹）攻击玩家
			var combat = actor.get_node_or_null("CombatComponent")
			if combat:
				combat.fire_actor_weapons(state.player.global_position)
			else:
				print("No CombatComponent found on actor: ", actor.name)
			# var weapon = actor.get_node_or_null("WeaponComponent")
			# if combat and weapon:
			#     weapon.fire()
			# Optionally: trigger attack animation, sound, etc.
			state.cooldown = attack_cooldown
			# Move到攻击距离
			var direction = actor.global_position.direction_to(state.player.global_position)
			actor.velocity = direction * actor.stats_component.get_move_speed()
		elif distance_to_player > attack_radius:
			# Move closer to player
			var direction = actor.global_position.direction_to(state.player.global_position)
			actor.velocity = direction * actor.stats_component.get_move_speed()
		else:
			# In cooldown, stop or idle
			actor.velocity = Vector2.ZERO
	else:
		# Player not found, do nothing
		pass
