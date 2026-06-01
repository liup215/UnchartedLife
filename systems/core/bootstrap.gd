# systems/core/bootstrap.gd
# Central bootstrap for the new ECS-lite + Command Bus architecture.
# Creates all core systems, registers them with ServiceRegistry, and wires up the tick pipeline.
# ServiceRegistry itself is an autoload, so it is already available when this script runs.
extends Node

# Preload all classes that are used with .new() to ensure they are resolved
# at parse time even when bootstrap is loaded as an Autoload.
const _EntityManager = preload("res://systems/ecs/entity_manager.gd")
const _TickSystem = preload("res://systems/core/tick_system.gd")
const _StatSystem = preload("res://systems/stat_system/stat_system.gd")
const _ResourcePoolSystem = preload("res://systems/stat_system/resource_pool_system.gd")
const _TargetResolverSystem = preload("res://systems/combat/target_resolver_system.gd")
const _WeaponSystem = preload("res://systems/combat/weapon_system.gd")
const _ChargeSystem = preload("res://systems/combat/charge_system.gd")
const _DamagePipeline = preload("res://systems/combat/damage_pipeline.gd")
const _InputCommandSystem = preload("res://systems/input/input_command_system.gd")
const _PlayerStateMachine = preload("res://systems/input/player_state_machine.gd")
const _MetabolismSystem = preload("res://systems/metabolism/metabolism_system.gd")
const _CombatCommandHandler = preload("res://systems/combat/combat_command_handler.gd")
const _AnimationSystem = preload("res://systems/visual/animation_system.gd")
const _VehicleCommandHandler = preload("res://systems/vehicle/vehicle_command_handler.gd")
const _DodgeCommandHandler = preload("res://systems/input/dodge_command_handler.gd")

func _ready() -> void:
	_print_header()
	
	## --- Phase 1: Create primitive systems (no dependencies) ---
	var entity_manager := _EntityManager.new()
	entity_manager.name = "EntityManager"
	add_child(entity_manager)
	ServiceRegistry.register("EntityManager", entity_manager)
	GameLogger.debug("bootstrap", "EntityManager registered")
	
	# CommandBus is already an Autoload singleton - register the existing instance
	ServiceRegistry.register("CommandBus", CommandBus)
	GameLogger.debug("bootstrap", "CommandBus registered")
	
	var tick_system := _TickSystem.new()
	tick_system.name = "TickSystem"
	add_child(tick_system)
	ServiceRegistry.register("TickSystem", tick_system)
	GameLogger.debug("bootstrap", "TickSystem registered")
	
	## --- Phase 2: Create stat systems ---
	var stat_system := _StatSystem.new()
	stat_system.name = "StatSystem"
	add_child(stat_system)
	ServiceRegistry.register("StatSystem", stat_system)
	GameLogger.debug("bootstrap", "StatSystem registered")
	
	var resource_pool_system := _ResourcePoolSystem.new()
	resource_pool_system.name = "ResourcePoolSystem"
	add_child(resource_pool_system)
	ServiceRegistry.register("ResourcePoolSystem", resource_pool_system)
	GameLogger.debug("bootstrap", "ResourcePoolSystem registered")
	
	## --- Phase 3: Wire tick system ---
	## StatSystem processes timed modifiers each frame.
	tick_system.register_system(stat_system, &"on_tick", 100)
	
	## --- Phase 3.1: Create Wave 3 combat systems ---
	var target_resolver := _TargetResolverSystem.new()
	target_resolver.name = "TargetResolverSystem"
	add_child(target_resolver)
	ServiceRegistry.register("TargetResolverSystem", target_resolver)
	GameLogger.debug("bootstrap", "TargetResolverSystem registered")
	
	var weapon_system := _WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	add_child(weapon_system)
	ServiceRegistry.register("WeaponSystem", weapon_system)
	GameLogger.debug("bootstrap", "WeaponSystem registered")
	
	var charge_system := _ChargeSystem.new()
	charge_system.name = "ChargeSystem"
	add_child(charge_system)
	ServiceRegistry.register("ChargeSystem", charge_system)
	GameLogger.debug("bootstrap", "ChargeSystem registered")
	## ChargeSystem updates charge progress every frame.
	tick_system.register_system(charge_system, &"on_tick", 180)
	
	var damage_pipeline := _DamagePipeline.new()
	damage_pipeline.name = "DamagePipeline"
	add_child(damage_pipeline)
	ServiceRegistry.register("DamagePipeline", damage_pipeline)
	GameLogger.debug("bootstrap", "DamagePipeline registered")
	
	## --- Phase 4: Create Wave 4 input & state systems ---
	var input_cmd_system := _InputCommandSystem.new()
	input_cmd_system.name = "InputCommandSystem"
	add_child(input_cmd_system)
	ServiceRegistry.register("InputCommandSystem", input_cmd_system)
	GameLogger.debug("bootstrap", "InputCommandSystem registered")
	
	var player_state_machine := _PlayerStateMachine.new()
	player_state_machine.name = "PlayerStateMachine"
	add_child(player_state_machine)
	ServiceRegistry.register("PlayerStateMachine", player_state_machine)
	GameLogger.debug("bootstrap", "PlayerStateMachine registered")
	
	## --- Phase 5: Register MetabolismSystem ---
	var metabolism_system := _MetabolismSystem.new()
	metabolism_system.name = "MetabolismSystem"
	add_child(metabolism_system)
	ServiceRegistry.register("MetabolismSystem", metabolism_system)
	GameLogger.debug("bootstrap", "MetabolismSystem registered")
	## MetabolismSystem processes all entity energy calculations each frame.
	tick_system.register_system(metabolism_system, &"on_tick", 150)
	
	## --- Phase 5.1: Register CombatCommandHandler ---
	var combat_handler := _CombatCommandHandler.new()
	combat_handler.name = "CombatCommandHandler"
	add_child(combat_handler)
	ServiceRegistry.register("CombatCommandHandler", combat_handler)
	GameLogger.debug("bootstrap", "CombatCommandHandler registered")
	
	## AnimationSystem (Wave 6)
	var animation_system := _AnimationSystem.new()
	animation_system.name = "AnimationSystem"
	add_child(animation_system)
	ServiceRegistry.register("AnimationSystem", animation_system)
	GameLogger.debug("bootstrap", "AnimationSystem registered")
	
	## VehicleCommandHandler (Wave 5 bridge)
	var vehicle_handler := _VehicleCommandHandler.new()
	vehicle_handler.name = "VehicleCommandHandler"
	add_child(vehicle_handler)
	ServiceRegistry.register("VehicleCommandHandler", vehicle_handler)
	GameLogger.debug("bootstrap", "VehicleCommandHandler registered")
	
	## DodgeCommandHandler (Wave 5 bridge)
	var dodge_handler := _DodgeCommandHandler.new()
	dodge_handler.name = "DodgeCommandHandler"
	add_child(dodge_handler)
	ServiceRegistry.register("DodgeCommandHandler", dodge_handler)
	GameLogger.debug("bootstrap", "DodgeCommandHandler registered")
	
	GameLogger.debug("bootstrap", "Bootstrap complete. %d systems registered." % ServiceRegistry.list_services().size())

func _print_header() -> void:
	GameLogger.debug("bootstrap", "========================================")
	GameLogger.debug("bootstrap", "  Bootstrap: New Architecture Starting")
	GameLogger.debug("bootstrap", "  Active waves: StatSystem + ResourcePool")
	GameLogger.debug("bootstrap", "========================================")