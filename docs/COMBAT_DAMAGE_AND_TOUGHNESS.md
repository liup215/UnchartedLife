# Combat System - Damage Calculation & Toughness System

## Overview
This document describes the comprehensive damage calculation system and toughness/stagger mechanics implemented in response to user feedback.

## New Features

### 1. Comprehensive Damage Calculation

The damage system now considers multiple factors from both attacker and defender:

#### Damage Formula
```
Step 1: Base Damage = (Weapon Damage + Attacker Attack) × Stage Multiplier
Step 2: With Bonuses = Base Damage × Attacker Bonus Multiplier
Step 3: Effective Defense = Defender Defense × (1 - Armor Break / 100)
Step 4: After Defense = With Bonuses × (100 / (100 + Effective Defense))
Step 5: Final Damage = After Defense × Defender Reduction × Type Effectiveness
Step 6: Toughness Damage = Final Damage × 0.5 × (1 + Stagger Power / 100)
```

#### Factors Considered

**Attacker Side:**
- Base attack value (from ActorData.base_attack)
- Weapon damage (from WeaponData.damage)
- Combo/heavy attack multiplier (from ComboAttackData/HeavyAttackData)
- Armor break power (reduces defender's effective defense)
- Item/buff damage bonuses (TODO: extensible system)

**Defender Side:**
- Base defense value (from ActorData.base_defense)
- Equipment defense bonuses (TODO: from inventory system)
- Item/buff damage reduction (TODO: extensible system)
- Damage type resistances (TODO: elemental system)

### 2. Toughness/Stagger System (韧性/僵直系统)

#### Toughness Mechanics
- **Max Toughness**: Configurable per actor (default: 100)
- **Current Toughness**: Decreases when taking hits
- **Recovery Rate**: Passive regeneration (default: 10/sec)
- **Stagger Threshold**: When toughness reaches 0, stagger occurs

#### Stagger State
When an actor's toughness is broken:
1. **Enter Stagger**: 2-second stagger duration (configurable)
2. **Input Disabled**: All player input ignored
3. **AI Disabled**: All AI behaviors suspended
4. **Movement Locked**: Velocity forced to zero
5. **Visual Feedback**: 
   - Red color tint (modulate)
   - Flash effect if no stagger animation
   - Play "stagger" animation if available
6. **Recovery**: After duration, restore 30% toughness

#### Toughness Damage Calculation
```
Toughness Damage = Final Damage × 0.5 × (1 + Stagger Power / 100)
```

Stagger power from combo/heavy attack data amplifies toughness damage.

## ActorData Extensions

New combat attributes added to `ActorData`:

```gdscript
@export_group("Combat Attributes")
@export var base_attack: float = 10.0           # Base attack power
@export var base_defense: float = 5.0           # Base defense
@export var max_toughness: float = 100.0        # Max toughness
@export var current_toughness: float = 100.0    # Current toughness
@export var toughness_recovery_rate: float = 10.0  # Recovery per second
```

## Components

### DamageCalculator (Static Class)

Located: `features/components/damage_calculator.gd`

**Key Method:**
```gdscript
static func calculate_damage(
    attacker: Node,
    defender: Node,
    base_weapon_damage: float,
    damage_type: WeaponData.DamageType,
    damage_multiplier: float = 1.0,
    armor_break_power: float = 0.0
) -> Dictionary
```

**Returns:**
```gdscript
{
    "final_damage": float,          # Damage to apply to health
    "toughness_damage": float,      # Damage to apply to toughness
    "is_critical": bool,            # Future: critical hit flag
    "damage_breakdown": Dictionary  # Step-by-step calculation
}
```

**Damage Breakdown Structure:**
```gdscript
{
    "base": float,                      # Base damage
    "with_attacker_bonuses": float,     # After attacker bonuses
    "effective_defense": float,         # Defender's effective defense
    "after_defense": float,             # Damage after defense reduction
    "final": float,                     # Final damage value
    "type_effectiveness": float         # Elemental multiplier
}
```

### ToughnessComponent

Located: `features/components/toughness_component.gd`

**Properties:**
- `max_toughness: float` - Maximum toughness value
- `current_toughness: float` - Current toughness
- `toughness_recovery_rate: float` - Recovery per second
- `is_staggered: bool` - Whether in stagger state
- `stagger_duration: float` - Duration of stagger (2.0s default)
- `stagger_threshold: float` - Threshold to trigger stagger (0.0)

**Signals:**
- `toughness_changed(current, max)` - Toughness value changed
- `toughness_broken()` - Toughness reached 0
- `stagger_started()` - Entered stagger state
- `stagger_ended()` - Exited stagger state

**Key Methods:**
```gdscript
func set_actor_data(data: ActorData)  # Initialize from ActorData
func apply_toughness_damage(damage: float, stagger_power: float = 0.0)
func reset_toughness()  # Force reset to max
func is_in_stagger() -> bool  # Check stagger state
```

## Integration Flow

### Damage Application Flow

```
Projectile hits enemy
    ↓
base_bullet._on_body_entered(body)
    ↓
ActorCombatComponent.on_enemy_hit(target, base_weapon_damage)
    ↓
DamageCalculator.calculate_damage(...)
    ↓
Returns: {final_damage, toughness_damage, breakdown}
    ↓
target.take_damage(final_damage)  # Apply health damage
target.AttributeComponent.toughness_component.apply_toughness_damage(...)
    ↓
If toughness <= 0:
    ToughnessComponent.trigger_stagger()
    ↓
    Actor._on_stagger_started()
    ↓
    [2 seconds pass - input disabled]
    ↓
    ToughnessComponent.end_stagger()
    ↓
    Actor._on_stagger_ended()
```

### Stagger State Handling

**In Actor._physics_process():**
```gdscript
if attribute_component.toughness_component.is_in_stagger():
    velocity = Vector2.ZERO  # Lock movement
    move_and_slide()
    return  # Skip AI execution
```

**In Player._handle_on_foot_logic():**
```gdscript
if attribute_component.toughness_component.is_in_stagger():
    return  # Ignore all input
```

## Combat Stats Examples

### Example 1: Light Attack Combo

**Attacker:**
- Base Attack: 10
- Weapon Damage: 25
- Combo Stage 1: 1.0× multiplier, 10 armor break, 15 stagger

**Defender:**
- Base Defense: 5
- No equipment bonuses

**Calculation:**
1. Base = (25 + 10) × 1.0 = 35
2. With Bonuses = 35 × 1.0 = 35
3. Effective Defense = 5 × (1 - 10/100) = 4.5
4. After Defense = 35 × (100 / 104.5) ≈ 33.5
5. Final = 33.5 × 1.0 × 1.0 = 33.5
6. Toughness = 33.5 × 0.5 × 1.15 ≈ 19.3

**Result:** 33 HP damage, 19 toughness damage

### Example 2: Heavy Attack Level 5

**Attacker:**
- Base Attack: 10
- Weapon Damage: 25
- Heavy Level 5: 5.0× multiplier, 100 armor break, 100 stagger

**Defender:**
- Base Defense: 5

**Calculation:**
1. Base = (25 + 10) × 5.0 = 175
2. With Bonuses = 175 × 1.0 = 175
3. Effective Defense = 5 × (1 - 100/100) = 0
4. After Defense = 175 × (100 / 100) = 175
5. Final = 175 × 1.0 × 1.0 = 175
6. Toughness = 175 × 0.5 × 2.0 = 175

**Result:** 175 HP damage, 175 toughness damage (instant stagger!)

### Example 3: Against High Defense Enemy

**Attacker:**
- Base Attack: 10
- Weapon Damage: 25
- Combo Stage 3: 1.8× multiplier, 40 armor break

**Defender:**
- Base Defense: 50 (heavily armored)

**Calculation:**
1. Base = (25 + 10) × 1.8 = 63
2. With Bonuses = 63 × 1.0 = 63
3. Effective Defense = 50 × (1 - 40/100) = 30
4. After Defense = 63 × (100 / 130) ≈ 48.5
5. Final = 48.5 × 1.0 × 1.0 = 48.5

**Result:** 48 HP damage (armor break was crucial!)

## Weapon Configuration

Combo and heavy attack data are configured per weapon, allowing different weapons to have unique combat characteristics.

### Configuring a Weapon

In `weapon_data.tres`:
```gdscript
# Combo attacks (light attacks)
combo_attacks = [
    combo_stage_1,  # 1.0× dmg, 10 armor break, 15 stagger
    combo_stage_2,  # 1.3× dmg, 20 armor break, 25 stagger
    combo_stage_3   # 1.8× dmg, 40 armor break, 50 stagger
]

# Heavy attacks (charge levels)
heavy_attacks = [
    heavy_level_1,  # 2.0× dmg, 50 armor break, 75 stagger
    heavy_level_3,  # 3.5× dmg, 75 armor break, 90 stagger
    heavy_level_5   # 5.0× dmg, 100 armor break, 100 stagger
]
```

When switching weapons, the combat system automatically uses the new weapon's data.

## Extensibility

The system is designed for future expansion:

### Item/Buff System (TODO)
```gdscript
# In DamageCalculator
static func _get_damage_bonus_multiplier(attacker: Node) -> float:
    # Check inventory for damage-boosting items
    # Check active buffs for damage increases
    return 1.0 + item_bonuses + buff_bonuses
```

### Elemental Resistance (TODO)
```gdscript
# In DamageCalculator
static func _get_damage_type_effectiveness(damage_type, defender) -> float:
    # Check defender's elemental resistances
    # Fire vs Ice enemy = 1.5×
    # Ice vs Fire enemy = 0.5×
    return effectiveness_multiplier
```

### Critical Hits (TODO)
```gdscript
# In calculate_damage
if randf() < crit_chance:
    final_damage *= crit_multiplier
    result["is_critical"] = true
```

## Stagger Animation

To add a stagger animation to an actor:

1. Create `AnimationData` with `animation_name = "stagger"`
2. Add to `ActorData.animations` array
3. System will automatically play it during stagger

If no stagger animation exists, a flash effect is used instead.

## Testing

### Test Scenario 1: Basic Combat
1. Attack enemy with light attacks
2. Observe damage numbers
3. Watch toughness bar decrease (if UI implemented)
4. After 5-6 hits, enemy should stagger
5. Enemy should show red tint and be unable to move

### Test Scenario 2: Heavy Attack Stagger
1. Charge heavy attack to level 5
2. Release on enemy
3. Enemy should immediately stagger (high toughness damage)

### Test Scenario 3: Player Stagger
1. Let enemies hit player multiple times
2. Player should enter stagger when toughness breaks
3. All input should be disabled
4. Visual feedback should appear
5. After 2 seconds, player recovers

## Debugging

Enable debug output to see damage calculations:
```
[COMBAT] Hit Slime - Damage: 33.5 Toughness: 19.3
[COMBAT] Damage breakdown: {"base": 35, "with_attacker_bonuses": 35, ...}
[TOUGHNESS] Damage: 19.3 Current: 80.7/100
[TOUGHNESS] Toughness broken! Entering stagger state for 2s
[ACTOR] Slime entered stagger state!
[TOUGHNESS] Stagger ended, toughness restored to 30
[ACTOR] Slime recovered from stagger!
```

## Summary

This enhancement provides:
1. ✅ Weapon-specific combo/charge configurations (already implemented)
2. ✅ Comprehensive damage calculation with all requested factors
3. ✅ Toughness/stagger system with full mechanics

The system is data-driven, extensible, and ready for future enhancements like item bonuses, elemental resistances, and critical hits.
