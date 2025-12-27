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

## 11. Combat System Architecture

### Combo & Heavy Attack System
The combat system uses a data-driven approach with configurable combo stages and heavy charge attacks.

#### Core Components
- **ChargeComponent**: Universal charge management supporting light hit accumulation and heavy hold-to-charge
- **ComboAttackData**: Resource defining combo stage properties (damage multiplier, armor break, stagger power, charge gain)
- **HeavyAttackData**: Resource defining charge level configurations (multipliers, effects, recovery time)
- **DamageCalculator**: Static class for comprehensive damage calculation
- **ToughnessComponent**: Manages toughness/poise system for stagger mechanics

#### Combo System Pattern
```gdscript
# Weapon configuration (data-driven)
weapon_data.combo_attacks = [
    combo_stage_1,  # 1.0× damage, 10 armor break, 15 stagger
    combo_stage_2,  # 1.3× damage, 20 armor break, 25 stagger
    combo_stage_3   # 1.8× damage, 40 armor break, 50 stagger (finisher)
]

# Combat component handles progression
func perform_light_attack():
    combo_stage = combo_counter % weapon_data.combo_attacks.size()
    var combo_data = weapon_data.combo_attacks[combo_stage]
    # Apply multipliers, play animation, fire weapon
    combo_counter += 1
```

#### Heavy Attack Charge System
```gdscript
# Charge builds from two sources:
# 1. Light attack hits accumulate charge
# 2. Holding heavy attack button charges over time

# Heavy attack configuration
weapon_data.heavy_attacks = [
    heavy_level_1,  # 2.0× damage, 50 armor break
    heavy_level_3,  # 3.5× damage, 75 armor break
    heavy_level_5   # 5.0× damage, 100 armor break (max)
]

# Release all accumulated charge
func release_heavy_attack():
    var charge_level = charge_component.stop_heavy_charge()
    # Find appropriate heavy data for charge level
    # Fire weapon with heavy multiplier
    charge_component.reset_charge()
```

#### Comprehensive Damage Calculation
```gdscript
# Formula considers all combat factors:
Base = (Weapon Damage + Attacker Attack) × Stage Multiplier
With Bonuses = Base × Attacker Bonus Multiplier
Effective Defense = Defender Defense × (1 - Armor Break / 100)
After Defense = With Bonuses × (100 / (100 + Effective Defense))
Final Damage = After Defense × Defender Reduction × Type Effectiveness
Toughness Damage = Final Damage × 0.5 × (1 + Stagger Power / 100)

# Usage in combat component
var damage_result = DamageCalculator.calculate_damage(
    attacker, defender,
    base_weapon_damage,
    damage_type,
    damage_multiplier,
    armor_break_power
)
# Returns: {final_damage, toughness_damage, damage_breakdown}
```

#### Toughness/Stagger System
```gdscript
# Toughness tracking
actor_data.max_toughness = 100.0
actor_data.current_toughness = 100.0
actor_data.toughness_recovery_rate = 10.0  # per second

# Stagger state management
func apply_toughness_damage(damage: float, stagger_power: float):
    current_toughness -= damage × (1.0 + stagger_power / 100)
    if current_toughness <= 0:
        trigger_stagger()  # 2-second duration, input disabled

# Integration with Actor
func _physics_process(delta):
    if toughness_component.is_in_stagger():
        velocity = Vector2.ZERO  # Lock movement
        return  # Skip AI/input processing
```

#### Weapon-Specific Configuration
Each weapon can have unique combo sequences and heavy attack properties:
```gdscript
# Weapon switches automatically update combat behavior
# System reads from current weapon's combo_attacks and heavy_attacks arrays
# No code changes needed for new weapon types
```

### Combat UI Pattern
- **ChargeDisplay**: Bottom-right UI showing real-time charge (0-5 levels)
- Color-coded feedback: White → Yellow → Orange → Red
- Timer-based player discovery for performance
- Signal-based updates from ChargeComponent

## 12. Map System Architecture

### MapData Resource System
Maps are defined as data resources with configurable properties:

#### MapData Structure
```gdscript
class_name MapData extends Resource

@export var map_id: String                    # Unique identifier (e.g., "main_world")
@export var map_name: String                  # Display name
@export var chunk_scenes: Dictionary          # Vector2i -> scene path mapping
@export var default_spawn_position: Vector2   # Player spawn point
@export var use_chunk_loading: bool = true    # Chunk-based vs full map loading
```

#### Multi-Map Management
```gdscript
# MapManager (Autoload)
var available_maps: Dictionary[String, MapData]  # All registered maps
var current_map_id: String                        # Active map
var current_map_data: MapData                     # Active map data

# Register new map
func register_map(map_data: MapData) -> void:
    available_maps[map_data.map_id] = map_data

# Switch between maps
func switch_to_map(map_id: String, spawn_position: Vector2 = Vector2.ZERO) -> bool:
    # 1. Unload all current chunks
    # 2. Update current_map_id and current_map_data
    # 3. Load chunks for new map
    # 4. Emit EventBus.map_changed signal
    # 5. Return success/failure
```

### Vehicle-Map Binding
Vehicles can be assigned to specific maps:

```gdscript
# In Vehicle scene
@export var assigned_map_id: String = ""  # Empty = available on all maps

func _ready():
    EventBus.map_changed.connect(_on_map_changed)
    _update_visibility_for_current_map()

func _on_map_changed(new_map_id: String, _spawn_pos: Vector2):
    _update_visibility_for_current_map()

func _update_visibility_for_current_map():
    if assigned_map_id.is_empty():
        visible = true  # Available on all maps
    else:
        visible = (MapManager.current_map_id == assigned_map_id)
```

### Portal/Transition Pattern
```gdscript
# Example portal implementation
extends Area2D
@export var target_map_id: String = "dungeon_1"
@export var target_spawn_position: Vector2 = Vector2(640, 360)

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        if MapManager.switch_to_map(target_map_id, target_spawn_position):
            body.global_position = target_spawn_position
```

### Map-Specific Save/Load
```gdscript
# MapManager save/load
func save_data() -> Dictionary:
    return {
        "current_map_id": current_map_id,
        "loaded_chunks": _serialize_loaded_chunks()
    }

func load_data(data: Dictionary):
    current_map_id = data.get("current_map_id", DEFAULT_MAP_ID)
    # Restore chunks after scene ready
    chunks_to_restore = data.get("loaded_chunks", [])

# Vehicle save/load includes map binding
func save_data() -> Dictionary:
    return {
        "assigned_map_id": assigned_map_id,
        "position": {"x": global_position.x, "y": global_position.y},
        # ... other state
    }
```

## 13. State Restoration Patterns

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
16. **Combat data-driven** - combo/heavy attacks configured per weapon
17. **Comprehensive damage** - use DamageCalculator for all combat
18. **Toughness management** - integrate ToughnessComponent for stagger mechanics
19. **Map data resources** - define maps using MapData resources
20. **Vehicle-map binding** - assign vehicles to specific maps via assigned_map_id
21. **Map transitions** - use EventBus.map_changed for system notifications
22. **Map-specific saves** - persist current_map_id in save data
