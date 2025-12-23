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

### Binary Serialization System (Updated December 2025)
The save system uses **binary serialization** (var_to_bytes/bytes_to_var) to support all custom data types including Resources, Arrays, and complex objects.

#### Core Save/Load Implementation
Nodes in "saveable" group implement:
```gdscript
func save_data() -> Dictionary:
    return {
        "position": {"x": global_position.x, "y": global_position.y},
        "health": current_health,
        "vehicle_path": str(current_vehicle.get_path()) if current_vehicle else "",
        # ... other state
    }

func load_data(data: Dictionary) -> void:
    if data.has("position"):
        var pos = data["position"]
        global_position = Vector2(pos.get("x", 0), pos.get("y", 0))
    current_health = data.get("health", current_health)
    # ... restore other state
```

#### Resource Path Serialization Pattern
Resources cannot be directly serialized with binary format, so use resource paths:

```gdscript
# Saving - Convert Resource to path
func to_dict() -> Dictionary:
    var weapons_paths = []
    for weapon in weapons:
        if weapon and weapon.resource_path != "":
            weapons_paths.append(weapon.resource_path)
    return {"weapons_paths": weapons_paths}

# Loading - Load Resource from path
func from_dict(data: Dictionary) -> void:
    if data.has("weapons_paths"):
        weapons.clear()
        for path in data["weapons_paths"]:
            var weapon = load(path)
            if weapon:
                weapons.append(weapon)
```

#### Global Singleton Persistence
Global autoloads (PlayerData, GameProperties, MapManager) are saved/loaded separately from scene nodes:
- `PlayerData`: Stores player name, current slot, complete ActorData
- `GameProperties`: Stores difficulty, seed, tutorial state
- `MapManager`: Stores loaded chunk coordinates for restoration

#### Deferred Loading Pattern
For scene-dependent data (vehicles, map chunks):
```gdscript
func load_data(data: Dictionary) -> void:
    # Store data for deferred restoration
    chunks_to_restore = data["chunk_coords"]
    
func set_map_parent(parent: Node):
    # Restore when scene is ready
    for coords in chunks_to_restore:
        _load_chunk(coords)
    chunks_to_restore.clear()
```

#### Vector2 Serialization
Always serialize Vector2 as dictionary for binary compatibility:
```gdscript
# Save
"position": {"x": global_position.x, "y": global_position.y}

# Load
if typeof(pos_data) == TYPE_DICTIONARY:
    global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
else:
    global_position = pos_data  # Backward compatibility
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

## 9. Animation Data Pattern

### Animation Frame Configuration (Updated December 2025)
Animation sequences must start with **motion frames**, not idle frames, to prevent visual glitches.

#### Correct Frame Order
```gdscript
# ✅ CORRECT - Motion frames first, idle frame at end
walk_down: [1, 2, 3, 0]  # Frames 1-3 are motion, frame 0 is idle
walk_up:   [13, 14, 15, 12]
walk_left: [5, 6, 7, 4]
walk_right: [9, 10, 11, 8]

# ❌ INCORRECT - Idle frame first causes visual issues
walk_down: [0, 1, 2, 3]  # Frame 0 (idle) displays on first movement
```

#### Animation Update Logic with Safety Check
Actor animation updates include defensive checks for stopped animations:
```gdscript
# Check both name change AND playing state
if visuals.animation != final_anim_name or not visuals.is_playing():
    visuals.play(final_anim_name)
```

This prevents edge cases where animations stop unexpectedly during gameplay.

#### Animation Architecture
- `AnimationData` resources define frame sequences
- `AnimatedSprite2D` controlled by animation system
- State-based animation (walking, idle, combat)
- Generic animation logic in `actor.gd` reads from data

## 10. Error Handling Patterns

### Corrupted Save File Handling
```gdscript
# Check for null/invalid deserialization
if data == null or typeof(data) != TYPE_DICTIONARY:
    push_warning("Skipping corrupted save file: %s" % file_name)
    continue
elif data.has("metadata"):
    # Process valid save
else:
    push_warning("Save file missing metadata: %s" % file_name)
```

### Node Path Conversion
Always convert NodePath to String for save data to avoid type mismatches:
```gdscript
# Save
var vehicle_path = str(current_vehicle.get_path())  # NodePath → String

# Load  
var vehicle_node = get_node_or_null(vehicle_path)  # String works with get_node
```

## 11. State Restoration Patterns

### Vehicle Re-entry Pattern
When loading a save where player is in vehicle:
```gdscript
# Temporarily reset occupied flag to allow re-entry
var was_occupied = vehicle_node.occupied
vehicle_node.occupied = false
vehicle_node.enter_vehicle(self)
# enter_vehicle() sets all state correctly (visibility, camera, controls)
```

### MapManager Reset for New Game
Clear singleton state when starting new game:
```gdscript
func reset_for_new_game() -> void:
    loaded_chunks.clear()
    chunks_to_restore.clear()
    map_parent = null
```

## Best Practices

1. **Always use Resource files** for data
2. **Keep scenes generic** - no hardcoded values
3. **Static typing required** in GDScript
4. **Use EventBus** for cross-system communication
5. **Add to "saveable" group** for persistence
6. **Export variables** via Inspector, not hardcoded paths
7. **Educational first** - biology concepts drive mechanics
8. **Binary serialization** for save files (var_to_bytes/bytes_to_var)
9. **Resource path serialization** for complex Resources
10. **Vector2 as dictionaries** in save data
11. **Animation motion frames first** to avoid visual glitches
12. **Defensive animation checks** (name change + is_playing)
13. **NodePath to String conversion** for save data
14. **Deferred loading** for scene-dependent data
15. **Error handling** for corrupted save files
