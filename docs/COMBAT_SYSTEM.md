# Combat System - Combo & Heavy Attack Guide

## Overview
The combat system now supports light attack combos and heavy charge attacks with a sophisticated charge accumulation mechanic.

## System Components

### 1. Data Resources

#### ComboAttackData (`combo_attack_data.gd`)
Defines properties for each stage in a combo sequence:
- `combo_stage`: Stage number (1, 2, 3, etc.)
- `damage_multiplier`: Damage multiplier for this stage
- `armor_break_power`: Ability to penetrate enemy defense (0-100)
- `stagger_power`: Ability to interrupt enemy attacks (0-100)
- `charge_gain`: Charge accumulated per hit at this stage
- `animation_name`: Animation to play for this combo stage
- `duration`: Duration of this combo stage (seconds)
- `combo_window`: Time window to input next combo (seconds)

#### HeavyAttackData (`heavy_attack_data.gd`)
Defines properties for heavy attacks at different charge levels:
- `charge_level`: Minimum charge level required (1-5)
- `damage_multiplier`: Damage multiplier for this charge level
- `armor_break_power`: Armor penetration at this level (0-100)
- `stagger_power`: Stagger ability at this level (0-100)
- `animation_name`: Animation to play
- `effect_scene`: Visual effect to spawn (optional)
- `sound_effect`: Sound effect to play (optional)
- `atp_cost_multiplier`: ATP cost multiplier
- `recovery_time`: Recovery time after attack (seconds)

#### WeaponData Extensions
New properties added to `WeaponData`:
- `combo_attacks`: Array of `ComboAttackData` resources
- `max_combo_count`: Maximum combo stages
- `heavy_attacks`: Array of `HeavyAttackData` resources
- `charge_time_per_level`: Time to charge one level (seconds)
- `light_attacks_build_charge`: Whether light attacks accumulate charge

### 2. ChargeComponent (`charge_component.gd`)
Manages charge accumulation for combat:

**Methods:**
- `start_heavy_charge()`: Start charging for heavy attack
- `stop_heavy_charge()`: Stop charging and return charge level
- `add_light_attack_charge(amount)`: Add charge from light attack hit
- `reset_charge()`: Reset charge to zero
- `get_current_charge()`: Get current charge level
- `set_max_charge(new_max)`: Set maximum charge

**Signals:**
- `charge_changed(current, max)`: Emitted when charge changes
- `charge_level_up(level)`: Emitted when charge increases
- `charge_max_reached()`: Emitted when max charge is reached

### 3. ActorCombatComponent Updates
New methods for combo and heavy attack:

**Methods:**
- `perform_light_attack()`: Execute light attack with combo progression
- `start_heavy_attack_charge()`: Begin charging heavy attack
- `release_heavy_attack()`: Release charged heavy attack
- `on_enemy_hit(target, damage)`: Called when projectile hits enemy

**Signals:**
- `combo_updated(combo_count, combo_stage)`: Combo state changed
- `combo_stage_changed(stage, combo_data)`: Combo stage advanced
- `heavy_attack_performed(charge_level, heavy_data)`: Heavy attack executed
- `enemy_hit(target, damage, armor_break, stagger)`: Enemy was hit

### 4. ChargeDisplay UI (`charge_display.gd`)
Bottom-right UI displaying charge level:

**Features:**
- Real-time charge level display
- Color-coded progress bar (white → yellow → orange → red)
- Level indicator showing current/max charge
- Visual feedback on level up (scale animation)
- Flash effect when max charge reached

**Position:** Bottom-right corner with offset (-250, -150, -20, -20)

## Input Controls

### Light Attack
- **Input:** Left Mouse Button (`light_attack`)
- **Behavior:** 
  - Executes next combo stage
  - Builds charge when hitting enemies
  - Resets if combo window expires
  - ATP cost based on weapon

### Heavy Attack
- **Input:** Right Mouse Button (`heavy_attack`)
- **Press & Hold:** Builds charge over time
- **Release:** Executes heavy attack with accumulated charge
- **Behavior:**
  - Charge builds automatically while holding
  - Higher charge = stronger attack
  - Consumes all accumulated charge
  - ATP cost scales with charge level

## Combo System Flow

1. **First Light Attack**
   - Stage 1 combo executes
   - Base damage and effects
   - Gains charge on hit

2. **Second Light Attack (within combo window)**
   - Stage 2 combo executes
   - Increased damage multiplier
   - Higher armor break and stagger
   - Gains more charge on hit

3. **Third Light Attack (within combo window)**
   - Stage 3 combo executes (finisher)
   - Maximum damage multiplier
   - Highest armor break and stagger
   - Maximum charge gain on hit
   - Combo resets after completion

4. **Combo Timeout**
   - If next attack not input within `combo_window`
   - Combo resets to stage 1
   - Charge accumulation persists

## Charge System Flow

### Building Charge

**Method 1: Light Attack Hits**
- Land light attacks on enemies
- Each hit adds charge (amount depends on combo stage)
- Charge accumulates across combos
- Does not reset on combo timeout

**Method 2: Heavy Attack Hold**
- Press and hold heavy attack button
- Charge builds automatically over time
- One level per `charge_time_per_level` seconds
- Visual feedback on UI shows progress

### Using Charge

**Heavy Attack Release:**
1. Press heavy attack to start charging
2. Hold to build charge (or use accumulated charge from light attacks)
3. Release to execute heavy attack
4. Attack power based on final charge level
5. All charge consumed on release

## Example Weapon Configuration

```gdscript
# Example weapon data setup
weapon_data.combo_attacks = [
    combo_stage_1,  # Base combo
    combo_stage_2,  # Stronger combo
    combo_stage_3   # Finisher combo
]

weapon_data.heavy_attacks = [
    heavy_level_1,  # Minimum heavy (1-2 charge)
    heavy_level_3,  # Medium heavy (3-4 charge)
    heavy_level_5   # Maximum heavy (5 charge)
]

weapon_data.charge_time_per_level = 0.5  # 2.5 seconds for max charge
weapon_data.light_attacks_build_charge = true
```

## Combat Stats Explained

### Damage Multiplier
- Multiplies weapon base damage
- Combo Stage 1: 1.0x
- Combo Stage 2: 1.3x
- Combo Stage 3: 1.8x
- Heavy Level 1: 2.0x
- Heavy Level 5: 5.0x

### Armor Break Power (0-100)
- Penetrates enemy armor/defense
- Higher values bypass more defense
- Useful against heavily armored enemies

### Stagger Power (0-100)
- Interrupts enemy attacks
- Higher values more likely to stun
- Can break enemy combos

### Charge Gain
- Amount of charge added per hit
- Combo Stage 1: +1 charge
- Combo Stage 2: +1 charge
- Combo Stage 3: +2 charge (finisher bonus)

## ATP Cost System

### Light Attack
- Base weapon ATP cost
- Same for all combo stages
- Consumed immediately on attack

### Heavy Attack
- Base ATP × Charge Level × ATP Cost Multiplier
- Example: 10 ATP base × 5 charge × 2.0 = 100 ATP
- Consumed on release

## Animation Integration

### Combat Animation Naming
- Light attacks: `attack_light_1`, `attack_light_2`, `attack_light_3`
- Heavy attacks: `attack_heavy_1`, `attack_heavy_3`, `attack_heavy_max`
- Animations played via `Actor.play_combat_animation()`

### Adding Animations
1. Create AnimationData resource
2. Set animation_name matching combo/heavy data
3. Add to ActorData.animations array
4. System automatically triggers on attack

## UI Customization

### ChargeDisplay Styling
Located in `ui/hud/charge_display.tscn`:
- Modify colors via theme overrides
- Adjust position via anchors and offsets
- Change bar size via `custom_minimum_size`
- Customize labels via font size overrides

### Color Coding
- White: Low charge (0-30%)
- Yellow: Medium charge (30-60%)
- Orange: High charge (60-100%)
- Red: Maximum charge (100%)
- Flash Yellow: Max charge reached

## Testing Tips

1. **Combo Testing**
   - Rapid left clicks for combo progression
   - Wait between clicks to test combo reset
   - Check damage numbers increase per stage

2. **Charge Testing**
   - Land light attacks to build charge gradually
   - Hold right mouse button to charge quickly
   - Watch UI for charge level feedback
   - Release at different charge levels

3. **Integration Testing**
   - Mix light and heavy attacks
   - Build charge with light attacks
   - Finish with charged heavy attack
   - Verify ATP consumption is correct

## Future Enhancements

Potential additions to the system:
- Perfect dodge mechanics
- Parry/counter attacks
- Charge-specific visual effects
- Weapon-specific combo variations
- Charge decay over time
- Super moves at max charge
- Combo multiplier system
- Hit confirm feedback
