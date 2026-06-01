# systems/combat/target_resolver_system.gd
# SINGLE AUTHORITY for all targeting / world-space ray queries.
# This is the ONLY system in the codebase that ever calls get_global_mouse_position().
# All combat code gets aim targets through here, removing the visual layer dependency
# from Business Logic (WeaponComponent, CombatComponent, etc.).
#
# Usage:
#   var resolver: TargetResolverSystem = ServiceRegistry.get_service("TargetResolverSystem")
#   var world_pos: Vector2 = resolver.get_player_aim_target()
#
extends Node
class_name TargetResolverSystem

## Configuration
## If true, aim is locked to nearest enemy. If false, free aim with mouse.
var auto_lock_enabled: bool = false
var auto_lock_range: float = 300.0

## Cached reference to player actor (set by PlayerStateMachine or Bootstrap)
var player_actor: Actor = null

## The single place get_global_mouse_position() is allowed.
func get_player_aim_target() -> Vector2:
	# If auto-lock is enabled and we have a player reference, try to lock onto nearest enemy
	if auto_lock_enabled and player_actor:
		var nearest = _find_nearest_enemy_in_range()
		if nearest:
			return nearest.global_position
	# Otherwise fall back to mouse position
	return get_viewport().get_mouse_position()

## Return the aim target from the *current camera view*, accounting for offset.
func get_player_aim_target_world() -> Vector2:
	# This method can be extended later for camera offset, aim-assist, etc.
	var viewport = get_viewport()
	if not viewport:
		return Vector2.ZERO
	var camera = viewport.get_camera_2d()
	if camera:
		# Mouse position in world space
		return camera.get_global_mouse_position()
	return get_player_aim_target()

func set_player_actor(actor: Actor) -> void:
	player_actor = actor

func _find_nearest_enemy_in_range() -> Node2D:
	if not player_actor:
		return null
	var tree = get_tree()
	if not tree:
		return null
	var enemies = tree.get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = auto_lock_range
	var player_pos = player_actor.global_position
	for e in enemies:
		if not e is Node2D:
			continue
		var dist = player_pos.distance_to(e.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = e as Node2D
	return nearest
