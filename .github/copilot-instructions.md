# Legends of Uncharted Life - AI Coding Instructions

## Project Context
- **Engine:** Godot 4.x
- **Language:** GDScript (Static typing required)
- **Genre:** Educational Action RPG (Biology focus)
- **Core Philosophy:** Data-Driven & Component-Based. Logic is generic; content is defined in `Resource` files.

## Architecture & Patterns

### 1. Data-Driven Entity System ("Soul-Container-Brain")
- **The Soul (Data):** Define entities (Enemies, Weapons, Items) using `Resource` files (`.tres`), NOT by creating new scenes/scripts for every variant.
    - Example: Create a new enemy by making a new `ActorData` resource, not a `Slime.tscn`.
    - Key Classes: `ActorData`, `WeaponData`, `AIBehaviorData`.
- **The Container (Scene):** Use generic scenes as shells.
    - Key Scenes: `features/actor/base_actor.tscn`, `features/vehicle/base_vehicle.tscn`.
- **The Brain (Logic):** Generic scripts read data and configure components.
    - Key Scripts: `features/actor/actor.gd`, `features/vehicle/base_vehicle.gd`.

### 2. Component-Based Composition
- Prefer **composition over inheritance**.
- Functionality is encapsulated in small, reusable components located in `features/components/`.
- **Common Components:**
    - `HealthComponent`: Manages HP and death signals.
    - `ActorCombatComponent` / `VehicleCombatComponent`: Handles attacks and weapon management.
    - `InventoryComponent`: Manages items.
    - `AttributeComponent`: Bridges data resources to runtime stats.

### 3. Global Systems (Autoloads)
- Use Autoloads for global state and cross-system communication.
- **EventBus (`systems/event_bus.gd`):** Use for decoupling systems. Emit signals here rather than direct node-to-node calls when possible.
- **Managers:** `SaveManager`, `MapManager`, `InventoryManager`, `AudioManager`.

## Code Style & Conventions

### GDScript Best Practices
- **Static Typing:** ALWAYS use static typing for variables and function returns.
    - `var health: int = 100`
    - `func take_damage(amount: int) -> void:`
- **Naming:** `snake_case` for variables/functions, `PascalCase` for classes/types.
- **Path References:** Avoid hardcoded paths (`"res://..."`). Use `class_name` or `@export` variables to reference resources and scenes.

### Creating New Content
1.  **New Enemy:** Create `ActorData` resource -> Assign `AIBehaviorData` resources -> Use `base_actor.tscn`.
2.  **New Weapon:** Create `WeaponData` resource -> Assign to Actor/Vehicle data.
3.  **New Logic:** Create a Component (`Node` or `Node2D`) -> Add to the entity scene -> Expose configuration via `@export`.

## Critical Workflows

- **Testing:** Run tests via the Godot Editor or specific test scenes in `tests/`.
- **UI:** UI logic should be separate from game logic, communicating via `EventBus` or signals.
- **Save System:** Add nodes to `saveable` group and implement `save_data() -> Dictionary` to persist state.

## Educational Systems (BioBlitz)

### BioBlitz Core Mechanics
- **Question-Triggered Combat:** Enemies enter "BioBlitz" mode when health drops below threshold, requiring players to answer biology questions to continue combat.
- **Question Data Structure:** Questions defined in JSON files (`data/question_bank/`) with fields: `question_text`, `options`, `correct_option_index`, `type`.
- **Offline Evaluation:** Questions evaluated locally using simple string matching or SymPy for math problems (future enhancement).
- **Workflow:** Combat → Health Threshold → Quiz UI → Answer Evaluation → Resume Combat.

### BioBlitz Manager
- **Location:** `features/bio_blitz/bio_blitz_manager.gd` (Autoload)
- **Responsibilities:** Load questions from JSON, manage quiz state, evaluate answers, trigger combat pauses/resumes.
- **Key Methods:** `load_questions_from_dir()`, `start_quiz()`, `evaluate_answer()`.

## Dual-Entity System (Player + Vehicle)

### Player-Vehicle Interaction
- **States:** `ON_FOOT` (walking), `IN_VEHICLE` (driving).
- **Transition:** Press 'E' near vehicle to enter/exit. Vehicle becomes player's avatar when occupied.
- **Shared Stats:** Player and vehicle share some attributes (health, ATP) but have separate combat systems.
- **Camera Switching:** Player camera follows character, vehicle camera follows tank.

### Vehicle Physics
- **Base Class:** `RigidBody2D` for realistic physics (collisions, momentum).
- **Movement:** Tank-style controls (forward/backward + rotation).
- **Fuel System:** Vehicles consume glucose as fuel during movement.

## Energy Systems (ATP/Glucose Metabolism)

### Biological Energy Model
- **Glucose:** Universal currency and energy source. Consumed for all actions (movement, combat, upgrades).
- **ATP:** Short-term energy buffer. Generated from glucose via cellular respiration simulation.
- **Metabolism:** Continuous glucose consumption with ATP regeneration. Sprinting drains ATP faster.
- **Realism:** Based on actual cellular respiration (glycolysis, citric acid cycle).

### Component Integration
- **MetabolismComponent:** Handles energy calculations and depletion.
- **AttributeComponent:** Bridges `ActorData` energy stats to runtime values.
- **UI Display:** HUD shows glucose/ATP bars with real-time updates.

## AI Behavior System

### Behavior Composition
- **AIBehaviorData Resources:** Define behaviors as data (not code). Examples: `WanderBehaviorData`, `ChasePlayerBehaviorData`, `AttackBehaviorData`.
- **Execution Priority:** Behaviors checked in array order; first executable behavior runs.
- **Data-Driven AI:** Complex enemy behavior created by combining simple behavior resources.

### Behavior Types
- **Movement:** `WanderBehaviorData` (random patrol), `ChasePlayerBehaviorData` (pursuit).
- **Combat:** `AttackBehaviorData` (weapon firing), `PatrolBehaviorData` (waypoint following).
- **Conditional:** Behaviors can have `should_execute()` methods for state-dependent activation.

## Inventory & Equipment System

### Inventory Architecture
- **InventoryData Resources:** Define container configurations (backpack, equipment slots).
- **InventoryComponent:** Manages item storage, retrieval, and UI updates.
- **Item Categories:** Weapons, armor, consumables, quest items.

### Equipment Integration
- **WeaponData:** Defines damage, fire rate, ammo capacity, visual effects.
- **Equipping:** Weapons assigned to actors/vehicles via `ActorData.equipped_weapons` array.
- **Combat Integration:** `ActorCombatComponent`/`VehicleCombatComponent` read equipped weapons and create `WeaponComponent` instances.

## Save/Load System

### Save Mechanics
- **SaveManager Autoload:** Handles serialization of all `saveable` group nodes.
- **Save Data Format:** JSON with metadata (timestamp, player name) + per-node dictionaries.
- **Global Data:** `PlayerData` singleton saved separately from scene nodes.

### Implementation Pattern
```gdscript
# In any saveable node:
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

## Testing Patterns

### Test Structure
- **Test Scenes:** Located in `tests/` directory (e.g., `backpack_test.tscn`).
- **Test Scripts:** Extend `SceneTree` for standalone execution.
- **BioBlitz Testing:** `test_bio_blitz_json.gd` validates question loading and parsing.

## Testing Patterns

### Test Structure
- **Test Scenes:** Located in `tests/` directory (e.g., `backpack_test.tscn`).
- **Test Scripts:** Extend `SceneTree` for standalone execution.
- **BioBlitz Testing:** `test_bio_blitz_json.gd` validates question loading and parsing.

### Running Tests
- **Godot Editor:** Open test scene and run.
- **Command Line:** `godot --script test_script.gd` for headless testing.
- **Validation Focus:** Data loading, component integration, system interactions.

## Component Examples & Patterns

### Core Component Structure
```gdscript
# Example: HealthComponent
extends Node
class_name HealthComponent

@export var max_health: int = 100
var current_health: int

signal health_changed(current: int, max: int)
signal died()

func _ready():
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        died.emit()
```

### Component Communication
- **Signals:** Components emit signals for state changes (health_changed, died, etc.)
- **EventBus:** Use for cross-component communication when direct coupling isn't appropriate
- **Parent References:** Components access parent entity data through exported references

### Weapon System Integration
```gdscript
# ActorCombatComponent pattern
@onready var weapon_components: Array[WeaponComponent] = []

func _ready():
    # Initialize weapons from ActorData
    for weapon_data in actor_data.equipped_weapons:
        var weapon_comp = WeaponComponent.new()
        weapon_comp.weapon_data = weapon_data
        add_child(weapon_comp)
        weapon_components.append(weapon_comp)
```

## Map Generation & Loading System

### WorldData Resource
- **Central Configuration:** `data/definitions/world_data.gd` defines all map chunk references
- **No Hardcoded Paths:** All scene references managed through WorldData resource
- **Dynamic Loading:** MapManager loads chunks based on player position

### Chunk-Based Loading
```gdscript
# MapManager pattern
func load_chunk_at(position: Vector2) -> void:
    var chunk_key = get_chunk_key(position)
    if not loaded_chunks.has(chunk_key):
        var chunk_scene = world_data.get_chunk_scene(chunk_key)
        if chunk_scene:
            var chunk = chunk_scene.instantiate()
            add_child(chunk)
            loaded_chunks[chunk_key] = chunk
```

## UI Communication Patterns

### EventBus Integration
```gdscript
# UI updates via EventBus
func _ready():
    EventBus.actor_health_changed.connect(_on_health_changed)
    EventBus.inventory_item_added.connect(_on_item_added)

func _on_health_changed(actor: Node, current: int, max: int):
    if actor.is_in_group("player"):
        health_bar.value = current
        health_bar.max_value = max
```

### UI-Game Logic Separation
- **UI Scenes:** Handle presentation only (`ui/hud/`, `ui/main_menu/`)
- **Game Logic:** Managed in features/ and systems/
- **Communication:** Always through EventBus signals, never direct references

## Input Handling Patterns

### Player Input Processing
```gdscript
# Player.gd input pattern
func _physics_process(delta: float):
    match current_state:
        PlayerState.ON_FOOT:
            _handle_movement_input()
            _handle_interaction_input()
        PlayerState.IN_VEHICLE:
            # Input delegated to vehicle
            pass

func _handle_movement_input():
    var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = input_vector * move_speed
```

### Vehicle Controls
- **Tank-Style:** Forward/backward + rotation (no strafing)
- **Fuel Consumption:** Movement costs glucose
- **Combat Integration:** Mouse aiming for weapons

## Animation & Visual Effects

### AnimationData Resources
- **Centralized Animation Config:** `data/definitions/animation/animation_data.gd`
- **Sprite Management:** AnimatedSprite2D controlled by AnimationData
- **State-Based Animation:** Walking, idle, combat states

### Weapon Effects
```gdscript
# WeaponComponent effect pattern
func fire(target: Vector2):
    # Create bullet
    var bullet = bullet_scene.instantiate()
    bullet.global_position = muzzle_position
    bullet.target = target
    get_tree().root.add_child(bullet)
    
    # Play muzzle flash
    if muzzle_flash_effect:
        var flash = muzzle_flash_effect.instantiate()
        add_child(flash)
```

## Error Handling & Validation

### Data Validation
```gdscript
# Actor.gd validation pattern
func _ready():
    if not actor_data:
        push_error("Actor requires ActorData resource")
        return
    
    if actor_data.behaviors.is_empty():
        push_warning("Actor has no AI behaviors assigned")
```

### Runtime Safety Checks
- **Null Checks:** Always validate references before use
- **Type Hints:** Use static typing to catch errors early
- **Assert Statements:** For critical invariants in debug builds

## Performance Considerations

### Node Management
- **Object Pooling:** Reuse bullet/projectile instances
- **Chunk Loading:** Only load visible map sections
- **Component Optimization:** Disable unused components when possible

### Physics Optimization
- **RigidBody2D for Vehicles:** Realistic physics but higher CPU cost
- **CharacterBody2D for Actors:** Predictable movement, lower cost
- **Collision Layers:** Separate player, enemy, environment, projectiles

## Build & Deployment Workflows

### Godot Project Settings
- **Autoloads:** EventBus, SaveManager, MapManager, etc. configured in project.godot
- **Input Actions:** Defined in project.godot (move_forward, fire_weapon, etc.)
- **Groups:** "player", "saveable", "vehicle" used for node categorization

## Build & Deployment Workflows

### Godot Project Settings
- **Autoloads:** EventBus, SaveManager, MapManager, etc. configured in project.godot
- **Input Actions:** Defined in project.godot (move_forward, fire_weapon, etc.)
- **Groups:** "player", "saveable", "vehicle" used for node categorization

### Export Configuration
- **Presets:** `export_presets.cfg` for different platforms
- **Resource Optimization:** Compress textures, optimize audio
- **Standalone Builds:** Include all required assets and data files

## Weapon & Combat System Details

### Combat Component Architecture
- **ActorCombatComponent:** Manages actor weapons, handles firing logic
- **VehicleCombatComponent:** Manages vehicle weapons with main/sub-weapon support
- **WeaponComponent:** Individual weapon instances with charge, ammo, and effect management

### Weapon Mechanics
- **Charge System:** Weapons build charge over time (1-5 levels), consuming ATP per level
- **Ammo Management:** Weapons have capacity limits, some require BioBlitz quiz reload
- **Damage Types:** Physical, Fire, Ice, Electric, Explosive with different effects
- **Projectile System:** Bullets inherit from `base_bullet.tscn` with configurable properties

### Combat Integration
```gdscript
# Combat component firing pattern
func fire_weapon(weapon_index: int, target: Vector2):
    var weapon_comp = weapon_components[weapon_index]
    if weapon_comp and weapon_comp.can_fire():
        weapon_comp.fire(target)
        # Consume ATP based on charge level
        metabolism_component.consume_atp(weapon_comp.get_atp_cost())
```

## Debugging Workflows

### Energy System Debugging
- **ATP/Glucose Monitoring:** Use HUD bars and debug prints to track energy flow
- **Metabolism Validation:** Check `MetabolismComponent` calculations against expected values
- **Sprint Mechanics:** Verify ATP drain rates during movement vs. sprinting

### Combat System Debugging
- **Weapon Firing:** Check WeaponComponent signals and projectile instantiation
- **Damage Application:** Verify HealthComponent receives and processes damage correctly
- **BioBlitz Triggers:** Monitor health thresholds and quiz state transitions

### Common Debug Commands
```gdscript
# In debug builds, add these to Player.gd or use console
func _input(event):
    if event.is_action_pressed("debug_toggle"):
        print("Player ATP: ", attribute_component.current_atp)
        print("Player Glucose: ", attribute_component.current_glucose)
        print("Current Vehicle: ", current_vehicle)
```

## External Tool Integration

### Python Evaluation Engine
- **Architecture:** Godot client ↔ Local Python server via HTTP
- **Purpose:** Evaluate math expressions using SymPy for BioBlitz questions
- **Communication:** JSON requests with question data, responses with evaluation results

### Integration Pattern
```gdscript
# BioBlitzManager evaluation pattern
func evaluate_answer(question: QuestionData, answer: String) -> bool:
    var request_data = {
        "question": question.question_text,
        "answer": answer,
        "type": question.type
    }
    
    # Send to local Python service
    var result = await http_request.post("http://localhost:5000/evaluate", request_data)
    return result["correct"]
```

## Content Creation Patterns

### Creating New Enemy Types
1. **Create ActorData Resource:** `data/actors/enemies/new_enemy_data.tres`
2. **Configure Stats:** Set health, speed, ATP/glucose values
3. **Assign Behaviors:** Add AIBehaviorData resources (Wander, Chase, Attack)
4. **Set Visuals:** Assign AnimationData and sprite configurations
5. **Test Spawn:** Use base_actor.tscn with the new data

### Creating New Weapons
1. **Create WeaponData Resource:** `data/weapons/new_weapon_data.tres`
2. **Configure Combat Stats:** Damage, fire rate, ammo capacity
3. **Set Visual Effects:** Bullet texture, muzzle flash, hit effects
4. **Assign to Entities:** Add to ActorData.equipped_weapons array
5. **Test Integration:** Verify in ActorCombatComponent/VehicleCombatComponent

### Creating New Questions
1. **Add to JSON:** `data/question_bank/biology_questions.json`
2. **Follow Schema:** question_text, options array, correct_option_index, type
3. **Test Loading:** Run `test_bio_blitz_json.gd` to validate
4. **Offline Evaluation:** Implement simple string matching or prepare for SymPy integration

## Code Review Guidelines

### Data-Driven Focus
- **Resource Usage:** Prefer Resource files over hardcoded values
- **Component Composition:** Use existing components rather than custom logic
- **Static Typing:** All variables and function returns must be typed

### Architecture Compliance
- **EventBus Usage:** Use signals for cross-system communication
- **Group Membership:** Add nodes to appropriate groups ("saveable", "player")
- **Path Avoidance:** Never hardcode "res://" paths

### Performance Standards
- **Node Pooling:** Reuse projectiles and effects
- **Chunk Loading:** Only load visible map sections
- **Component Optimization:** Disable unused components

## Version Control Practices

### Git Configuration
- **.gitattributes:** Optimized for Godot binary files (.tscn, .tres, .png)
- **Large Files:** Use Git LFS for audio/video assets
- **Binary Conflicts:** .tscn/.tres files should be handled carefully

### Commit Patterns
- **Feature Commits:** "feat: add new enemy type with WanderBehavior"
- **Data Commits:** "data: update slime enemy stats"
- **Fix Commits:** "fix: correct ATP consumption calculation"
- **Refactor Commits:** "refactor: extract weapon firing logic to component"

## Asset Management Patterns

### Sprite Organization
- **AnimationData Resources:** Centralize animation configurations
- **Sprite Scaling:** Use consistent scale factors across similar entities
- **Texture Optimization:** Compress textures in export settings

### Audio Integration
- **AudioManager:** Centralized audio playback through autoload
- **Sound Categories:** UI sounds, combat effects, ambient music
- **Dynamic Audio:** Adjust volumes based on game state

## Localization Patterns

### Text Management
- **No Hardcoded Strings:** All UI text through translation keys
- **CSV Files:** `i18n/` directory for translation tables
- **Dynamic Updates:** UI elements update when language changes

### Implementation
```gdscript
# UI text pattern
@onready var health_label: Label = $HealthLabel

func _ready():
    health_label.text = tr("HEALTH_LABEL")
    # Updates automatically when language changes
```

## Scene Management Patterns

### Scene Loading
- **SceneManager Autoload:** Handles all scene transitions
- **Loading States:** Show progress bars for large scenes
- **State Preservation:** Save game state before scene changes

### Scene Structure
- **Main Scene:** `scenes/main.tscn` as entry point
- **Feature Scenes:** Modular scenes in `features/` directory
- **UI Scenes:** Overlay scenes in `ui/` directory

## Directory Structure
- `features/`: Core gameplay modules (actor, player, vehicle).
- `components/`: Reusable logic blocks.
- `data/definitions/`: GDScript `Resource` definitions (the schema).
- `data/[type]/`: The actual `.tres` data files (the content).
- `systems/`: Global managers (Autoloads).
- **UI:** UI logic should be separate from game logic, communicating via `EventBus` or signals.
- **Save System:** Add nodes to `saveable` group and implement `save_data() -> Dictionary` to persist state.

## Directory Structure
- `features/`: Core gameplay modules (actor, player, vehicle).
- `components/`: Reusable logic blocks.
- `data/definitions/`: GDScript `Resource` definitions (the schema).
- `data/[type]/`: The actual `.tres` data files (the content).
- `systems/`: Global managers (Autoloads).
