# Tech Context: Godot ARPG

## 1. Game Engine
- **Engine:** Godot 4.x
- **Rationale:** The user has specified Godot as the engine of choice. Version 4.x offers significant improvements in rendering, scripting, and performance, making it suitable for an ARPG.

## 2. Primary Language
- **Language:** GDScript
- **Rationale:** GDScript is tightly integrated with the Godot API, offering a rapid development workflow. Its syntax is clear and easy to learn. We will assume GDScript unless the user specifies a preference for C#.
- **Typing:** All new GDScript code **must** use static typing (`var my_var: Type = value`) to improve code clarity, enable better autocompletion, and reduce runtime errors.

## 3. Core Godot Features to Leverage
- **`Resource` System:** This is the cornerstone of our data-driven design. All game data (items, skills, enemy stats, etc.) will be defined as custom `Resource` types. This decouples data from code, making it easy for designers to manage and for the game to load.
- **Scene Composition:** We will favor composition over inheritance. Game objects will be built by composing smaller, reusable scenes (e.g., a `HealthComponent` scene, an `ActorSprite` scene) rather than creating deep inheritance hierarchies.
- **Signals:** Signals will be the primary method for communication between decoupled systems. This helps avoid hard-coded references and keeps components modular. For example, a `HealthComponent` will emit a `died` signal, which a `LootDropComponent` can listen for.
- **Autoloads (Singletons):** Global systems like the `EventManager`, `GameManager`, or `SaveManager` will be implemented as Autoloads for easy access from anywhere in the project. Use sparingly to avoid over-reliance on global state.

## 4. Version Control
- **System:** Git
- **Recommendation:** It is highly recommended to use a version control system like Git from the very beginning to track changes and collaborate effectively. We should configure it to handle Godot's text-based scene files (`.tscn`) and resources (`.tres`) properly.

## 5. Architectural Patterns

### Player-Vehicle Interaction
- **State Management:** The player's state is managed via a `PlayerState` enum (`ON_FOOT`, `IN_VEHICLE`). This determines which logic block (`_handle_on_foot_logic` or `_handle_in_vehicle_logic`) is executed in `_physics_process`.
- **Control Transfer:** When a player enters a vehicle, control is transferred to the vehicle. The player's `_physics_process` continues to run, but its primary role becomes synchronizing its position with the vehicle (`global_position = current_vehicle.global_position`) and handling passive logic (like basal metabolism). The player's visuals and physical collision shapes are disabled.
- **Camera Control:** Camera control is also transferred. The player's `Camera2D` is disabled, and the vehicle's `Camera2D` is enabled.

### Physics Model for Entities
- **Player/Enemies:** Implemented as `CharacterBody2D`. This provides direct control over movement via `velocity` and `move_and_slide()`, which is ideal for player and AI-controlled characters.
- **Vehicles:** Implemented as `RigidBody2D`. This was a deliberate choice to solve collision issues where `CharacterBody2D` enemies could push the vehicle. `RigidBody2D` is only affected by physics forces, not by `move_and_slide()` from other bodies.
- **Top-Down Physics:** For the top-down perspective, `RigidBody2D` vehicles have their `gravity_scale` set to `0` to prevent them from falling. Movement is controlled by applying forces (`apply_central_force`) and managing angular velocity for turning.

### AI Targeting
- **Persistent Tracking:** The enemy AI (`goblin.gd`) tracks the player by getting a reference to the node in the "player" group.
- **Position Sync:** Because the player node's `global_position` is continuously updated to match the vehicle's position while occupied, the enemy AI correctly tracks and follows the vehicle, even though the player's physical body is disabled. This provides a simple and effective way for AI to target the player regardless of their state.

### Physics Layers
The project uses specific physics layers to manage collisions:
- **Layer 1 (Default):** General purpose, currently unused for specific game elements.
- **Layer 2 (Actors):** Used for the Player and Enemies.
- **Layer 3 (World):** Used for static world geometry like walls and obstacles.
- **Layer 4 (Unused):** Reserved for future use.
- **Layer 5 (Vehicles):** Used for all vehicle bodies.
- **Layer 6 (Interaction):** Used for `Area2D` nodes that detect interaction ranges (e.g., entering a vehicle).

**Collision Matrix:**
- **Player (Layer 2):** Collides with Layer 3 (World). Does not collide with Vehicles.
- **Vehicle (Layer 5):** Collides with Layer 3 (World). Does not collide with Players or Enemies.
- **Vehicle InteractionArea (Layer 6):** Scans for Layer 2 (Actors) to enable interaction prompts.

### Vehicle Controls
Vehicles use a `RigidBody2D` with a custom script for tank-style controls.
- **Movement:** Force is applied based on `Vector2.UP` as the forward direction.
- **Turning:** Angular velocity is applied for turning.
  - Turning is only possible when the vehicle is moving forward or backward.
  - When reversing, the steering controls are inverted for realistic behavior.
- **Camera:** The vehicle's camera is configured to not rotate with the vehicle, providing a fixed world-view orientation.
- **Rendering:** The player (`z_index = 20`) is always rendered on top of the vehicle (`z_index = 10`).
