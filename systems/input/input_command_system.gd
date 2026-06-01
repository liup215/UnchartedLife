# systems/input/input_command_system.gd
# SINGLE AUTHORITY for all raw input.
# Reads Input actions and converts them into CommandBus commands.
# This means Player.gd no longer directly checks Input.is_action_just_pressed() for gameplay actions.
# Player.gd will ONLY read movement axis (because that's kinematic and needs to be in _physics_process).
# All discrete actions (attack, dodge, interact, skill, etc.) produce Commands here.
extends Node
class_name InputCommandSystem

## Configuration
@export var _continuous_fire_rate: float = 0.15  # seconds between held-trigger fires

## Tracking state for continuous action fire
var _last_fire_time: float = 0.0
var _is_fire_held: bool = false

## Cached commands to avoid re-allocating every frame
# (Optional optimization; not strictly necessary in GDScript)

func _process(delta: float) -> void:
	_poll_attack_input()
	_poll_dodge_input()
	_poll_interact_input()
	_poll_ability_input()
	_poll_reload_input()
	_poll_system_menu_input()
	_poll_charge_input()

## --- Private polling methods ---

func _poll_attack_input() -> void:
	if not InputMap.has_action("fire_weapon"):
		return
	var just_pressed = Input.is_action_just_pressed("fire_weapon")
	var released = Input.is_action_just_released("fire_weapon")

	if just_pressed:
		CommandBus.issue_type(CommandBus.CommandType.ATTACK_REQUEST, {})
		_is_fire_held = true
		_last_fire_time = Time.get_time_dict_from_system()["second"]

	if released:
		CommandBus.issue_type(CommandBus.CommandType.ATTACK_RELEASED, {})
		_is_fire_held = false

func _poll_charge_input() -> void:
	if not InputMap.has_action("charge_weapon"):
		return
	var just_pressed = Input.is_action_just_pressed("charge_weapon")
	var released = Input.is_action_just_released("charge_weapon")

	if just_pressed:
		CommandBus.issue_type(CommandBus.CommandType.HEAVY_CHARGE_START, {})
	if released:
		CommandBus.issue_type(CommandBus.CommandType.HEAVY_CHARGE_RELEASE, {})

func _poll_dodge_input() -> void:
	if not InputMap.has_action("dodge"):
		return
	if Input.is_action_just_pressed("dodge"):
		CommandBus.issue_type(CommandBus.CommandType.DODGE_REQUEST, {})

func _poll_interact_input() -> void:
	if not InputMap.has_action("interact"):
		return
	if Input.is_action_just_pressed("interact"):
		CommandBus.issue_type(CommandBus.CommandType.INTERACT_REQUEST, {})

func _poll_ability_input() -> void:
	if InputMap.has_action("ability1") and Input.is_action_just_pressed("ability1"):
		CommandBus.issue_type(CommandBus.CommandType.ABILITY_REQUEST, {"ability_index": 0})
	if InputMap.has_action("ability2") and Input.is_action_just_pressed("ability2"):
		CommandBus.issue_type(CommandBus.CommandType.ABILITY_REQUEST, {"ability_index": 1})
	if InputMap.has_action("ability3") and Input.is_action_just_pressed("ability3"):
		CommandBus.issue_type(CommandBus.CommandType.ABILITY_REQUEST, {"ability_index": 2})
	if InputMap.has_action("ability4") and Input.is_action_just_pressed("ability4"):
		CommandBus.issue_type(CommandBus.CommandType.ABILITY_REQUEST, {"ability_index": 3})

func _poll_reload_input() -> void:
	if not InputMap.has_action("reload"):
		return
	if Input.is_action_just_pressed("reload"):
		CommandBus.issue_type(CommandBus.CommandType.RELOAD_REQUEST, {})

func _poll_system_menu_input() -> void:
	if not InputMap.has_action("system_menu"):
		return
	if Input.is_action_just_pressed("system_menu"):
		CommandBus.issue_type(CommandBus.CommandType.SYSTEM_MENU_TOGGLE, {})
