# Tech Context: Legends of Uncharted Life

## 1. Game Engine
- **Engine:** Godot 4.x
- **Language:** GDScript (Static typing required)
- **Rationale:** Godot 4.x provides powerful features and performance, while GDScript's tight engine integration enables rapid development. Static typing significantly improves code quality and maintainability.

## 2. Core Architectural Patterns

### 2.1. Data-Driven Entity Architecture
This is the project's foundation.
- **Philosophy:** Separate data from logic. Entity attributes and behaviors defined in `Resource` files (`.tres`), while scenes (`.tscn`) and scripts (`.gd`) are generic "containers" that interpret this data.
- **Implementation:**
    - **`base_actor.tscn`**: Universal template for all characters
    - **`ActorData.gd`**: `Resource` defining character attributes and behaviors
    - **`WeaponData.gd`**: `Resource` defining weapon properties
    - **`AIBehaviorData.gd`**: `Resource` defining AI patterns
    - **`DialogueData.gd`**: `Resource` defining conversation trees
    - **`ItemData.gd`**: `Resource` defining items and their effects

### 2.2. Component-Based Design
- **Principle:** Favor composition over inheritance. Game objects composed of multiple reusable small scenes/scripts (components).
- **Examples:** `HealthComponent`, `MetabolismComponent`, `CombatComponent`, `VehicleCombatComponent`, `InventoryComponent`, `DialogueComponent`

### 2.3. Global Event Bus
- **`EventBus` Autoload:** Primary solution for decoupled system communication, broadcasting global events like `player_health_changed`, `glucose_collected`, `bioblitz_started`, etc.

## 3. Biology Education Integration

### 3.1. Glucose-ATP Energy System
- **MetabolismComponent:** Simulates cellular respiration
- **Real Biology:** Glucose consumed, ATP generated
- **Gameplay Integration:** 
  - Sprint = higher ATP consumption (anaerobic)
  - Rest = ATP regeneration (aerobic)
  - Upgrades = mitochondria improvements

### 3.2. BioBlitz Question System
- **QuestionData Resources:** Biology questions in `.tres` format
- **Evaluation:** Client-side question validation
- **Integration:** Combat pauses when enemy health low
- **Educational Feedback:** Explanations for correct/incorrect answers

### 3.3. Vehicle Bionic System
- **Evolutionary Adaptations:** Each modification teaches evolution
- **Real Biology:** Based on actual animal traits
- **Visual Learning:** See biological principles in action

## 4. Version Control
- **System:** Git
- **Configuration:** Properly configured `.gitattributes` to optimize handling of Godot text-format scenes (`.tscn`) and resources (`.tres`)

## 5. Physics System

### 5.1. Entity Types
- **Characters:** `CharacterBody2D` for precise movement control (player, enemies)
- **Vehicles:** `RigidBody2D` for realistic physics (momentum, collisions)
- **Projectiles:** `Area2D` for hit detection

### 5.2. Physics Layers
Clear separation of collision types:
- Layer 1: Player
- Layer 2: Enemies
- Layer 3: Vehicles
- Layer 4: Environment
- Layer 5: Projectiles
- Layer 6: Pickups

## 6. Save/Load Architecture (Updated December 2025)

### 6.1. Binary Serialization System
- **Primary:** Binary serialization using `var_to_bytes` / `bytes_to_var`
- **Format:** `.dat` files for save data (not JSON)
- **Advantages:** 
  - Supports all Godot data types (Resources, Arrays, Dictionaries)
  - Faster than JSON parsing
  - Smaller file sizes
  - No manual type conversion needed

### 6.2. Data Persistence Strategy

#### Multi-Slot System
- **Slot Management:** Create, save, load, continue from multiple save files
- **Metadata Tracking:** Player name, timestamp, difficulty, seed, play time
- **Latest Slot:** Continue game loads most recent save automatically

#### Complete Game State Persistence
- **Player State:** Position, health, glucose, ATP, current vehicle state
- **Vehicle State:** Position, rotation, occupied flag, fuel level
- **Map State:** Loaded chunk coordinates for restoration
- **Global Singletons:** PlayerData, GameProperties, MapManager
- **Scene Nodes:** All nodes in "saveable" group

#### Resource Path Serialization
Resources cannot be binary-serialized directly, so they're converted to paths:
```gdscript
# Save: Convert Resource → Path (String)
var weapons_paths = []
for weapon in weapons:
    if weapon and weapon.resource_path != "":
        weapons_paths.append(weapon.resource_path)

# Load: Load Resource from Path
for path in data["weapons_paths"]:
    var weapon = load(path)
    if weapon:
        weapons.append(weapon)
```

#### Vector2 Serialization
Always serialize Vector2 as dictionary for binary compatibility:
```gdscript
# Save
"position": {"x": global_position.x, "y": global_position.y}

# Load with backward compatibility
if typeof(pos_data) == TYPE_DICTIONARY:
    global_position = Vector2(pos_data["x"], pos_data["y"])
else:
    global_position = pos_data
```

### 6.3. Error Handling
- **Corrupted Files:** Skip with warning, don't crash game
- **Missing Metadata:** Log warning and continue
- **Invalid Data Types:** Type checking before deserialization
- **Null Safety:** Check for null after `bytes_to_var()`

### 6.4. Deferred Loading Pattern
For scene-dependent data (vehicles, map chunks):
```gdscript
# Store data when global singleton loads
func load_data(data: Dictionary):
    chunks_to_restore = data["chunk_coords"]

# Restore when scene is ready
func set_map_parent(parent: Node):
    for coords in chunks_to_restore:
        _load_chunk(coords)
    chunks_to_restore.clear()
```

### 6.5. State Management
- **New Game:** Reset MapManager, initialize PlayerData, create new slot
- **Continue:** Load latest save, restore all state including map chunks
- **Load Specific:** Select slot, restore that save's complete state
- **Save Game:** Collect all state, serialize to binary, write to file

## 7. Educational Content Management

### 7.1. Question Bank
- **Format:** JSON files with biology questions
- **Categories:** Cell biology, genetics, ecology, evolution
- **Difficulty:** Progressive from basic to advanced
- **Metadata:** Topic tags, curriculum alignment

### 7.2. Learning Analytics (Future)
- Track question performance
- Identify weak areas
- Adaptive difficulty
- Progress reports for educators

## 8. Performance Considerations

### 8.1. Map System
- **Chunk Loading:** Dynamic loading/unloading based on player position
- **WorldData:** Resource manages chunk references
- **Optimization:** Only visible chunks active

### 8.2. Object Pooling
- **Projectiles:** Reuse bullet instances
- **Effects:** Pool particle systems
- **Optimization:** Reduce GC pressure

## 9. UI Architecture

### 9.1. Separation of Concerns
- **UI Scenes:** Handle presentation only
- **Game Logic:** Managed in features/ and systems/
- **Communication:** EventBus signals, no direct references

### 9.2. Key UI Systems
- **HUD:** Health, glucose, ATP bars with biological context
- **System Menu:** Inventory, equipment, character stats, save game
- **Dialogue Panel:** NPC conversations with choices
- **BioBlitz UI:** Question display with educational feedback
- **Main Menu:** New game, continue, load game, options
- **New Game Settings:** Difficulty and seed configuration

### 9.3. Menu System Patterns (Updated December 2025)
- **Visibility Management:** Hide specific containers, not entire parent nodes
- **Signal-Based Flow:** Connect signals in _ready(), emit on actions
- **State Preservation:** Background and labels remain visible during transitions
- **Error Handling:** Graceful degradation for corrupted save files

Example: NewGameSettings shows while hiding only menu buttons:
```gdscript
# Hide menu_container (buttons), not entire MainMenu
if main_menu_ref and "menu_container" in main_menu_ref:
    main_menu_ref.menu_container.visible = false
```

## 10. Future Technical Enhancements

### 10.1. Advanced Biology Simulations
- Gene expression visualization
- Ecosystem simulation engine
- Cellular process animations
- Virtual microscope system

### 10.2. Educational Features
- Progress tracking dashboard
- Teacher analytics portal
- Custom content creation tools
- Community question bank

### 10.3. Performance & Polish
- Shader effects for biological processes
- Advanced particle systems
- Audio feedback for learning moments
- Accessibility features

## Best Practices

1. **Static Typing:** Always use type hints in GDScript
2. **Data-Driven:** Never hardcode game data
3. **EventBus First:** Use for cross-system communication
4. **Component Composition:** Prefer over inheritance
5. **Educational Integration:** Biology concepts drive mechanics
6. **Performance:** Profile before optimizing
7. **Testing:** Validate educational effectiveness with target audience
8. **Binary Serialization:** Use var_to_bytes/bytes_to_var for save files
9. **Resource Path Storage:** Convert Resources to paths for persistence
10. **Vector2 as Dictionaries:** Serialize as {x, y} for binary compatibility
11. **Null Safety:** Always check deserialization results
12. **Deferred Loading:** Wait for scene initialization before restoring state
13. **Animation Motion First:** Place motion frames at start of sequences
14. **NodePath to String:** Convert for save data to avoid type issues
