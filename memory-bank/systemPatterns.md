# System Patterns: Legends of Uncharted Life

This document outlines the architectural patterns for building the biology-focused educational ARPG, based on a data-driven and component-based philosophy.

## 1. Directory Structure
A clean directory structure is crucial. The project follows a feature-first and data-driven approach, with clear separation of assets, components, data, features, systems, and UI. All resource references use data-driven (Inspector-exported) patterns.

```
/
├── scenes/                 # Top-level entry scenes (e.g., main.tscn)
│   └── main.tscn
│
├── features/               # Core game features, each as a folder
│   ├── actor/              # Base actor scene and script
│   │   ├── base_actor.tscn
│   │   └── actor.gd
│   ├── player/             # Player-specific scenes/scripts
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── enemy/              # Enemy templates and logic
│   │   └── enemy.tscn
│   ├── vehicle/            # Vehicle base and logic
│   │   ├── base_vehicle.tscn
│   │   └── base_vehicle.gd
│   └── effects/            # Reusable effect/projectile scenes
│       ├── base_bullet.tscn
│       └── base_weapon_effect.tscn
│
├── components/             # Reusable, self-contained components
│   ├── health_component.tscn
│   ├── combat_component.tscn
│   ├── metabolism_component.tscn
│   ├── weapon_component.tscn
│   ├── inventory_component.tscn
│   └── dialogue_component.tscn
│
├── data/                   # All game data resources and definitions
│   ├── definitions/        # Resource class scripts
│   │   └── dialogue/       # Dialogue-specific definitions
│   ├── actors/             # Actor data (player, enemies)
│   ├── vehicles/           # Vehicle data and components
│   │   ├── basic_tank_data.tres
│   │   └── components/
│   │       ├── engines/
│   │       └── chips/
│   ├── weapons/            # Weapon data (actor_weapons, vehicle_weapons)
│   ├── ai_behavior/        # AI behavior resource instances
│   ├── dialogue/           # Dialogue resource instances
│   └── items/              # Item data
│
├── systems/                # Global managers (Autoloads)
│   ├── event_bus.gd
│   ├── save_manager.gd
│   ├── map_manager.gd
│   ├── dialogue_manager.gd
│   └── quest_manager.gd
│
├── ui/                     # UI scenes and scripts
│   ├── hud/
│   ├── main_menu/
│   ├── dialogue/
│   └── system_menu/
│
├── world/                  # World-level scenes and data
│   ├── chunks/
│   └── world_data.tres
│
└── assets/                 # Raw assets (textures, audio, fonts)
    ├── sprites/
    ├── audio/
    └── fonts/
```

## 2. Data-Driven Entity System ("Soul-Container-Brain")

### The Soul (Data - `.tres` Resources)
Define what an entity *is* and how it *behaves*. Examples:
- `ActorData`: Defines enemy health, speed, behaviors
- `WeaponData`: Defines damage, fire rate, projectile type
- `AIBehaviorData`: Defines specific AI patterns
- `ItemData`: Defines items, icons, effects
- `DialogueData`: Defines conversation trees

### The Container (Scene - `.tscn`)
Generic scenes serve as shells. Examples:
- `base_actor.tscn`: Generic enemy container
- `base_vehicle.tscn`: Generic vehicle container
- `base_bullet.tscn`: Generic projectile

### The Brain (Logic - `.gd` Scripts)
Generic scripts read data and configure components:
- `actor.gd`: Reads `ActorData`, configures components
- `base_vehicle.gd`: Reads vehicle data
- Behavior scripts interpret `AIBehaviorData`

**Workflow:** Create new enemy → Make `ActorData` resource → Assign to `base_actor.tscn` → Done!

## 3. Component-Based Composition

Prefer composition over inheritance. Functionality encapsulated in small, reusable components:

### Core Components
- `HealthComponent`: Manages HP, death signals
- `MetabolismComponent`: Handles glucose/ATP energy
- `ActorCombatComponent`: Actor attack logic
- `VehicleCombatComponent`: Vehicle weapon management
- `InventoryComponent`: Item storage
- `AttributeComponent`: Bridges data to runtime stats

### Biology-Specific Components
- `MetabolismComponent`: Simulates cellular respiration
- `GeneticComponent`: Handles genetic modifications
- `BionicComponent`: Manages vehicle bionic upgrades
- `EcologyComponent`: Tracks ecosystem restoration

## 4. AI System

### Composable AI Behaviors
AI defined as data, not code. Behaviors are `AIBehaviorData` resources:
- `WanderBehaviorData`: Random patrol
- `ChasePlayerBehaviorData`: Pursuit
- `AttackBehaviorData`: Combat actions

Enemy AI = array of behavior resources, executed in priority order.

## 5. Biology Integration Patterns

### Energy Management
- `MetabolismComponent` simulates cellular respiration
- Glucose → ATP conversion based on real biology
- Sprint costs more ATP (anaerobic respiration)
- Visual feedback shows energy flow

### Educational Moments
- Tooltips explain biological processes
- BioBlitz questions pause combat for learning
- Gene editing mini-game teaches CRISPR
- Ecosystem simulation demonstrates ecology

### Vehicle Bionics
- Bionic modifications based on animal adaptations
- Each upgrade teaches evolutionary concepts
- Visual representation of biological principles

## 6. Save/Load Pattern

Nodes in "saveable" group implement:
```gdscript
func save_data() -> Dictionary:
    return {
        "position": global_position,
        "health": current_health,
        # ... other state
    }

func load_data(data: Dictionary) -> void:
    global_position = data.get("position", global_position)
    current_health = data.get("health", current_health)
```

## 7. Event Bus Communication

Global events for system decoupling:
```gdscript
# EventBus signals
signal player_health_changed(current: int, max: int)
signal glucose_changed(amount: int)
signal bioblitz_started(enemy: Node)
signal gene_unlocked(gene_id: String)
signal ecosystem_restored(region: String)
```

## 8. Educational Content Integration

### Question System
- `QuestionData` resources define biology questions
- Multiple question types (multiple choice, fill-in-blank)
- Difficulty progression system
- Hint system (costs ATP)

### Learning Progression
- Complete tutorials unlock concepts
- Defeat enemies to master topics
- Gene modifications require understanding
- Ecosystem restoration validates learning

## Best Practices

1. **Always use Resource files** for data
2. **Keep scenes generic** - no hardcoded values
3. **Static typing required** in GDScript
4. **Use EventBus** for cross-system communication
5. **Add to "saveable" group** for persistence
6. **Export variables** via Inspector, not hardcoded paths
7. **Educational first** - biology concepts drive mechanics
