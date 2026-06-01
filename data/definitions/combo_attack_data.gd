# combo_attack_data.gd
# Defines properties for a single combo stage/phase
extends Resource
class_name ComboAttackData

## The stage number in the combo sequence (1, 2, 3, etc.)
@export var combo_stage: int = 1

## Damage multiplier for this combo stage
@export var damage_multiplier: float = 1.0

## Armor break power (ability to penetrate enemy defense)
@export_range(0.0, 100.0) var armor_break_power: float = 0.0

## Stagger power (ability to interrupt enemy attacks)
@export_range(0.0, 100.0) var stagger_power: float = 0.0

## Charge accumulation per hit for this combo stage
@export var charge_gain: int = 1

## Animation name for this combo stage (e.g., "attack_light_1", "attack_light_2")
@export var animation_name: String = ""

## Duration of this combo stage in seconds
@export var duration: float = 0.5

## Window to input next combo (seconds after this stage)
@export var combo_window: float = 0.3
