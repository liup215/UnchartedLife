# Tech Context: Godot ARPG

## 1. Game Engine
- **Engine:** Godot 4.x
- **Rationale:** The user has specified Godot as the engine of choice. Version 4.x offers significant improvements in rendering, scripting, and performance, making it suitable for an ARPG.

## 2. Primary Language
- **Language:** GDScript
- **Rationale:** GDScript is tightly integrated with the Godot API, offering a rapid development workflow. Its syntax is clear and easy to learn. We will assume GDScript unless the user specifies a preference for C#.
- **Typing:** All new GDScript code **must** use static typing (`var my_var: Type = value`) to improve code clarity, enable better autocompletion, and reduce runtime errors.

## 3. Core Architectural Patterns

### 3.1. Data-Driven Entity Architecture
This is the most important pattern in the project.
- **Philosophy:** Separate data from logic. An entity's properties and behaviors are defined in `Resource` files (`.tres`), while the scenes (`.tscn`) and scripts (`.gd`) are generic "containers" that interpret that data.
- **Actor Creation:**
    - **`base_actor.tscn`**: A generic `CharacterBody2D` scene that acts as a template for all living entities. It contains common components (`HealthComponent`, `StatsComponent`) but no specific logic.
    - **`ActorData.gd`**: A custom `Resource` that defines an actor's stats (`max_hp`, `move_speed`) and, crucially, its **behaviors**.
    - **`AIBehaviorData.gd`**: A custom `Resource` that defines a piece of AI logic (e.g., `WanderBehavior`, `ChasePlayerBehavior`). These are composable.
    - **Workflow:** To create a new enemy, a designer creates a new `ActorData` `.tres` file, configures its stats, and populates its `behaviors` array with `AIBehaviorData` resources. The game then spawns a `base_actor.tscn` instance and assigns this new `.tres` file to it.
- **Weapon Creation:**
    - A similar pattern is used for weapons. `WeaponData.gd` is a `Resource` that defines everything about a weapon (damage, fire rate, visual appearance, projectile type, etc.). The `WeaponComponent` is a generic script that simply reads from a `WeaponData` resource to function.

### 3.2. Component-Based Design
- **Scenes as Components:** We favor composition over deep inheritance. Game objects are built by composing smaller, reusable scenes (e.g., `HealthComponent.tscn`, `StatsComponent.tscn`).
- **Scripts as Components:** The `Actor` script itself acts as a central "brain" component that coordinates the other components attached to it.

### 3.3. Global Event Bus
- **`EventBus` Autoload:** A global singleton used for communication between decoupled systems. This is preferred for game-wide events (e.g., `actor_died`, `quest_completed`) to avoid direct references between major systems like UI, Questing, and Actors.

## 4. Version Control
- **System:** Git
- **Recommendation:** It is highly recommended to use a version control system like Git from the very beginning to track changes and collaborate effectively. We should configure it to handle Godot's text-based scene files (`.tscn`) and resources (`.tres`) properly.

## 5. Specific System Implementations

### 5.1. Physics Model for Entities
- **Player/Enemies:** Implemented as `CharacterBody2D`. This provides direct control over movement via `velocity` and `move_and_slide()`, which is ideal for player and AI-controlled characters.
- **Vehicles:** Implemented as `RigidBody2D`. This was a deliberate choice to solve collision issues where `CharacterBody2D` enemies could push the vehicle. `RigidBody2D` is only affected by physics forces, not by `move_and_slide()` from other bodies.
- **Top-Down Physics:** For the top-down perspective, `RigidBody2D` vehicles have their `gravity_scale` set to `0` to prevent them from falling. Movement is controlled by applying forces (`apply_central_force`) and managing angular velocity for turning.

### 5.2. Player-Vehicle Interaction
- **State Management:** The player's state is managed via a `PlayerState` enum (`ON_FOOT`, `IN_VEHICLE`). This determines which logic block (`_handle_on_foot_logic` or `_handle_in_vehicle_logic`) is executed in `_physics_process`.
- **Control Transfer:** When a player enters a vehicle, control is transferred to the vehicle. The player's `_physics_process` continues to run, but its primary role becomes synchronizing its position with the vehicle (`global_position = current_vehicle.global_position`) and handling passive logic (like basal metabolism). The player's visuals and physical collision shapes are disabled.
- **Camera Control:** Camera control is also transferred. The player's `Camera2D` is disabled, and the vehicle's `Camera2D` is enabled.

### 5.3. Physics Layers
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

### 5.4. Vehicle Controls
Vehicles use a `RigidBody2D` with a custom script for tank-style controls.
- **Movement:** Force is applied based on `Vector2.UP` as the forward direction.
- **Turning:** Angular velocity is applied for turning.
  - Turning is only possible when the vehicle is moving forward or backward.
  - When reversing, the steering controls are inverted for realistic behavior.
- **Camera:** The vehicle's camera is configured to not rotate with the vehicle, providing a fixed world-view orientation.
- **Rendering:** The player (`z_index = 20`) is always rendered on top of the vehicle (`z_index = 10`).
