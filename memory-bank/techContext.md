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

## 6. Save/Load Architecture

### 6.1. Local Storage
- **Primary:** JSON files for save data
- **Structure:** Metadata + per-node dictionaries
- **Saveable Group:** Nodes implement `save_data()` and `load_data()`

### 6.2. Data Persistence
- Player state (position, health, glucose, ATP)
- Inventory contents
- Quest progress
- Dialogue history
- Unlocked genes/modifications
- Ecosystem restoration status

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
- **System Menu:** Inventory, equipment, character stats
- **Dialogue Panel:** NPC conversations with choices
- **BioBlitz UI:** Question display with educational feedback

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
