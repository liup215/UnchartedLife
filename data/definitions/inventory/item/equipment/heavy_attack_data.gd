# heavy_attack_data.gd
# Defines properties for heavy attack at different charge levels
extends Resource
class_name HeavyAttackData

## Minimum charge level required for this heavy attack (1-5)
@export_range(1, 5) var charge_level: int = 1

## Damage multiplier for this charge level
@export var damage_multiplier: float = 2.0

## Armor break power at this charge level
@export_range(0.0, 100.0) var armor_break_power: float = 50.0

## Stagger power at this charge level
@export_range(0.0, 100.0) var stagger_power: float = 75.0

## Animation name for this heavy attack (e.g., "attack_heavy_1", "attack_heavy_max")
@export var animation_name: String = ""

## Visual effect scene to spawn (optional)
@export var effect_scene: PackedScene

## Sound effect for this heavy attack
@export var sound_effect: AudioStream

## ATP cost multiplier for this charge level
@export var atp_cost_multiplier: float = 1.0

## Recovery time after this heavy attack (seconds)
@export var recovery_time: float = 0.8
