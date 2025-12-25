# Combat System Architecture

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PLAYER INPUT                             │
│                                                                   │
│  Left Click (light_attack)    Right Click (heavy_attack)        │
│           │                              │                        │
│           │                              │                        │
└───────────┼──────────────────────────────┼────────────────────────┘
            │                              │
            ▼                              ▼
┌───────────────────────┐      ┌────────────────────────┐
│                       │      │                        │
│  perform_light_attack │      │ start_heavy_charge()   │
│                       │      │ (on press)             │
│  ActorCombatComponent │      │                        │
│                       │      │ release_heavy_attack() │
│  - Check combo timing │      │ (on release)           │
│  - Get combo stage    │      │                        │
│  - Apply multipliers  │      │ ActorCombatComponent   │
│  - Fire weapon        │      │                        │
│  - Emit signals       │      │ - Get charge level     │
│                       │      │ - Find heavy data      │
└───────────┬───────────┘      │ - Apply multipliers    │
            │                  │ - Fire weapon          │
            │                  │ - Reset charge         │
            │                  │                        │
            │                  └──────────┬─────────────┘
            │                             │
            │                             │
            ▼                             │
┌───────────────────────┐                 │
│   Fire Projectile     │◄────────────────┘
│                       │
│  - Create bullet      │
│  - Apply damage       │
│  - Detect hit         │
│                       │
└───────────┬───────────┘
            │
            │ On Enemy Hit
            ▼
┌───────────────────────┐
│  on_enemy_hit()       │
│                       │
│  - Get combo data     │
│  - Add charge         │
│  - Emit hit signal    │
│                       │
│  ActorCombatComponent │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  ChargeComponent      │
│                       │
│  add_light_attack_    │
│    charge()           │
│                       │
│  - Accumulate charge  │
│  - Emit signals       │
│  - Check max          │
└───────────┬───────────┘
            │
            │ charge_changed signal
            ▼
┌───────────────────────┐
│  ChargeDisplay UI     │
│                       │
│  - Update bar         │
│  - Update label       │
│  - Change colors      │
│  - Play animations    │
└───────────────────────┘
```

## Component Relationships

```
┌──────────────────────────────────────────────────┐
│                    Actor                         │
│  (Player / Enemy)                                │
│                                                   │
│  ┌────────────────────────────────────────────┐ │
│  │        AttributeComponent                  │ │
│  │  - Health, ATP, Speed, etc.                │ │
│  └────────────────────────────────────────────┘ │
│                                                   │
│  ┌────────────────────────────────────────────┐ │
│  │        ActorCombatComponent                │ │
│  │                                            │ │
│  │  Properties:                               │ │
│  │  - combo_counter                           │ │
│  │  - combo_stage                             │ │
│  │  - is_charging_heavy                       │ │
│  │  - actor_weapons[]                         │ │
│  │                                            │ │
│  │  Methods:                                  │ │
│  │  - perform_light_attack()                  │ │
│  │  - start_heavy_attack_charge()             │ │
│  │  - release_heavy_attack()                  │ │
│  │  - on_enemy_hit()                          │ │
│  │                                            │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │      WeaponComponent                 │ │ │
│  │  │  - weapon_data                       │ │ │
│  │  │  - fire()                            │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────┘ │
│                                                   │
│  ┌────────────────────────────────────────────┐ │
│  │        ChargeComponent                     │ │
│  │                                            │ │
│  │  Properties:                               │ │
│  │  - current_charge (0-5)                    │ │
│  │  - max_charge                              │ │
│  │  - is_charging_heavy                       │ │
│  │                                            │ │
│  │  Methods:                                  │ │
│  │  - start_heavy_charge()                    │ │
│  │  - stop_heavy_charge()                     │ │
│  │  - add_light_attack_charge()               │ │
│  │  - reset_charge()                          │ │
│  │                                            │ │
│  │  Signals:                                  │ │
│  │  - charge_changed                          │ │
│  │  - charge_level_up                         │ │
│  │  - charge_max_reached                      │ │
│  └────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

## Data Structure Hierarchy

```
┌────────────────────────────────────────────────────┐
│                  WeaponData                        │
│  (Extended ItemData)                               │
│                                                     │
│  Combat Stats:                                     │
│  - damage: float                                   │
│  - rate_of_fire: float                             │
│  - ammo_capacity: int                              │
│                                                     │
│  Combo System:                                     │
│  - combo_attacks: Array[ComboAttackData]           │
│  │    │                                            │
│  │    └──► ┌─────────────────────────────────┐    │
│  │         │   ComboAttackData               │    │
│  │         │   - combo_stage: int            │    │
│  │         │   - damage_multiplier: float    │    │
│  │         │   - armor_break_power: float    │    │
│  │         │   - stagger_power: float        │    │
│  │         │   - charge_gain: int            │    │
│  │         │   - animation_name: String      │    │
│  │         │   - duration: float             │    │
│  │         │   - combo_window: float         │    │
│  │         └─────────────────────────────────┘    │
│  │                                                 │
│  Heavy Attack System:                              │
│  - heavy_attacks: Array[HeavyAttackData]           │
│  │    │                                            │
│  │    └──► ┌─────────────────────────────────┐    │
│  │         │   HeavyAttackData               │    │
│  │         │   - charge_level: int           │    │
│  │         │   - damage_multiplier: float    │    │
│  │         │   - armor_break_power: float    │    │
│  │         │   - stagger_power: float        │    │
│  │         │   - animation_name: String      │    │
│  │         │   - effect_scene: PackedScene   │    │
│  │         │   - sound_effect: AudioStream   │    │
│  │         │   - atp_cost_multiplier: float  │    │
│  │         │   - recovery_time: float        │    │
│  │         └─────────────────────────────────┘    │
│  │                                                 │
│  Charge Properties:                                │
│  - charge_time_per_level: float                    │
│  - light_attacks_build_charge: bool                │
│  - max_combo_count: int                            │
└────────────────────────────────────────────────────┘
```

## State Machine: Combo System

```
       ┌──────────┐
       │  IDLE    │
       │ Stage: 0 │
       └────┬─────┘
            │
            │ Light Attack
            ▼
       ┌──────────┐
       │ COMBO 1  │────────┐
       │ Stage: 1 │        │ Timeout
       └────┬─────┘        │ (combo_reset_time)
            │              │
            │ Light Attack │
            │ (in window)  │
            ▼              │
       ┌──────────┐        │
       │ COMBO 2  │────────┤
       │ Stage: 2 │        │
       └────┬─────┘        │
            │              │
            │ Light Attack │
            │ (in window)  │
            ▼              │
       ┌──────────┐        │
       │ COMBO 3  │────────┤
       │ Stage: 3 │        │
       │ (Finisher)│       │
       └────┬─────┘        │
            │              │
            │ Auto-reset   │
            │ after window │
            ▼              │
       ┌──────────┐◄───────┘
       │  IDLE    │
       │ Stage: 0 │
       └──────────┘
```

## State Machine: Charge System

```
       ┌─────────────┐
       │  NO CHARGE  │
       │  Level: 0   │
       └──────┬──────┘
              │
              │ Light Attack Hit Enemy
              │ OR
              │ Hold Heavy Attack
              ▼
       ┌─────────────┐
       │ CHARGING    │
       │ Level: 1-4  │◄─────┐
       └──────┬──────┘      │
              │             │
              │ Continue    │
              │ Charging    │
              │             │
              ▼             │
       ┌─────────────┐      │
       │ MAX CHARGE  │──────┘
       │ Level: 5    │  (Can't increase)
       └──────┬──────┘
              │
              │ Release Heavy Attack
              ▼
       ┌─────────────┐
       │  NO CHARGE  │
       │  Level: 0   │
       └─────────────┘
```

## Signal Flow

```
User Input (Mouse Click)
    │
    ▼
Player._handle_combat_input()
    │
    ├──► Light Attack
    │    │
    │    ▼
    │    ActorCombatComponent.perform_light_attack()
    │    │
    │    ├──► Signals:
    │    │    - combo_updated(count, stage)
    │    │    - combo_stage_changed(stage, data)
    │    │    - weapons_fired(type, count, level)
    │    │
    │    ▼
    │    WeaponComponent.fire()
    │    │
    │    ▼
    │    Projectile spawned
    │    │
    │    ▼
    │    Enemy hit detected
    │    │
    │    ▼
    │    ActorCombatComponent.on_enemy_hit()
    │    │
    │    ├──► Signals:
    │    │    - enemy_hit(target, dmg, armor, stagger)
    │    │
    │    ▼
    │    ChargeComponent.add_light_attack_charge()
    │    │
    │    ├──► Signals:
    │    │    - charge_changed(current, max)
    │    │    - charge_level_up(level)
    │    │
    │    ▼
    │    ChargeDisplay._on_charge_changed()
    │
    └──► Heavy Attack
         │
         ▼ (Press)
         ActorCombatComponent.start_heavy_attack_charge()
         │
         ▼
         ChargeComponent.start_heavy_charge()
         │
         ▼ (Process Loop)
         ChargeComponent._update_heavy_charge()
         │
         ├──► Signals:
         │    - charge_changed(current, max)
         │    - charge_level_up(level)
         │    - charge_max_reached()
         │
         ▼
         ChargeDisplay updates in real-time
         │
         ▼ (Release)
         ActorCombatComponent.release_heavy_attack()
         │
         ├──► Signals:
         │    - heavy_attack_performed(level, data)
         │    - weapons_fired(type, count, level)
         │
         ▼
         ChargeComponent.reset_charge()
         │
         ▼
         ChargeDisplay._on_charge_changed(0, max)
```

## UI Layout

```
┌────────────────────────────────────────────────────────┐
│ Game Screen (1920x1080)                                │
│                                                         │
│  ┌──────────────┐                                      │
│  │ Player Info  │ (Top-Left)                           │
│  │ - Name       │                                      │
│  │ - Health Bar │                                      │
│  │ - ATP Bar    │                                      │
│  │ - Glucose    │                                      │
│  └──────────────┘                                      │
│                                                         │
│                    [Game Viewport]                     │
│                                                         │
│                                                         │
│                                      ┌──────────────┐  │
│                                      │ Charge       │  │
│                                      │ Display      │  │
│                                      │              │  │
│                                      │ Level 3 / 5  │  │
│                                      │ ████░░       │  │
│                                      └──────────────┘  │
│                                      (Bottom-Right)    │
└────────────────────────────────────────────────────────┘

Charge Display Position:
- Anchor: Bottom-Right (1.0, 1.0)
- Offset: (-250, -150) to (-20, -20)
- Size: 230 x 130 pixels
```
