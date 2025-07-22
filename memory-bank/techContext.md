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

### Safe Exiting Mechanism
- To prevent physics glitches (like the vehicle being "flung" away) when the player exits, a robust multi-step process is used:
    1.  **Find Safe Position:** A `find_safe_exit_position` function checks multiple offset points around the vehicle to find a spot where the player's collision shape won't overlap with any other physics body.
    2.  **Temporarily Disable Collisions:** Both the player's and the vehicle's collision shapes are temporarily disabled during the exit sequence.
    3.  **Temporarily Freeze Vehicle Physics:** The vehicle's `sleeping` state is set to `true` to completely freeze it for a single frame.
    4.  **Sequence with `await`:** The process is managed using `await get_tree().process_frame` to ensure physics states are updated correctly across frames before re-enabling collisions.
    5.  **Failsafe Push:** As a final failsafe, if a collision is still detected after re-enabling physics, the player is pushed slightly further away from the vehicle to resolve the overlap without moving the vehicle.

### AI Targeting
- **Persistent Tracking:** The enemy AI (`goblin.gd`) tracks the player by getting a reference to the node in the "player" group.
- **Position Sync:** Because the player node's `global_position` is continuously updated to match the vehicle's position while occupied, the enemy AI correctly tracks and follows the vehicle, even though the player's physical body is disabled. This provides a simple and effective way for AI to target the player regardless of their state.
