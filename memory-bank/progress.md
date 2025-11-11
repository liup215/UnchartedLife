# Progress Tracker

## Phase 1: Core Architecture & Setup (Complete)

- [x] Design and implement a feature-first project structure.
- [x] Create a global event bus for decoupled communication.
- [x] Implement a data-driven actor system with `ActorData` resources.
- [x] Create base components for `Health` and `Stats`.
- [x] Build a base `Actor` scene and script.
- [x] Create `Player` and `Goblin` actors inheriting from the base actor.
- [x] Implement a main game scene (`main.tscn`).
- [x] Implement a main menu (`main_menu.tscn`) with navigation.
- [x] Implement a character creation screen (`character_creation.tscn`).
- [x] Implement a basic in-game HUD (`hud.tscn`) to display player info.
- [x] Implement a pausable in-game system menu (`system_menu.tscn`).
- [x] Debug and resolve all startup crashes and input handling issues.

## Phase 2: Save/Load System (Complete)

- [x] Design a save/load manager.
- [x] Implement logic to save player data (name, position, stats).
- [x] Implement logic to load player data.
- [x] Integrate save/load functionality with the UI (e.g., "Continue" button).
- [x] Implement multi-slot save/load functionality.
- [x] Add "Quit to Menu" and "Quit to Desktop" options.
- [x] Change system menu to be full-screen.
- [x] Debug and resolve all scene hierarchy and loading issues.

## Phase 3: World & Map System (Complete)

- [x] Debugged and fixed complex collision and AI behavior issues.
- [x] Resolved node initialization order and group lookup timing problems.
- [x] Designed a chunk-based dynamic map loading system.
- [x] Created a `TileSet` resource from image assets.
- [x] Implemented a `MapManager` singleton to handle loading map chunks.
- [x] Integrated the `MapManager` to load the initial map chunk based on player position.

## Phase 4: Core Gameplay & Biology Systems (Complete)

- [x] **Implement Glucose-ATP System:**
    - [x] Refactor `ActorData` to include new biological stats (`max_hp`, `max_atp`, etc.).
    - [x] Create `ATPComponent` to manage ATP logic with float precision.
    - [x] Implement dynamic glucose consumption based on ATP demand.
    - [x] Update HUD to display real-time Glucose and ATP values.
    - [x] Implement biological energy conversion system (glucose → ATP).
    - [x] Add basal metabolic rate for basic cellular maintenance.
- [x] **Implement Sprint System:**
    - [x] Add sprint functionality with Shift key input.
    - [x] Implement speed boost during sprinting (1.8x multiplier).
    - [x] Create tiered ATP consumption: Rest (2/sec) → Walking (5/sec) → Sprinting (11/sec).
    - [x] Integrate sprint mechanics with glucose-ATP metabolism.
- [x] **Refine Biological Accuracy:**
    - [x] Implement demand-driven glucose consumption (only when ATP < max).
    - [x] Balance ATP recovery rate to match consumption rate exactly.
    - [x] Create realistic energy management system with resource pressure.

## Phase 5: Enhanced Gameplay Systems (Complete)

- [x] **Implement Player-Vehicle System:**
    - [x] Create a base `Vehicle` scene.
    - [x] Implement logic for player to enter/exit vehicle.
    - [x] Separate player and vehicle stats and controls.
    - [x] Implement `RigidBody2D` physics for the vehicle for realistic collisions.
    - [x] Implement tank-style controls (forward/backward movement, realistic reverse steering).
    - [x] Simplify exit mechanism by removing collisions between player and vehicle.
    - [x] Ensure AI correctly tracks the player inside the vehicle.
    - [x] Implement comprehensive HUD integration for real-time vehicle status display.
- [x] **Implement Core Combat Loop:**
    - [x] Implement secondary weapon combo system with asynchronous, rhythmic firing.
    - [x] Implement main weapon charging system.
    - [x] Fix weapon data duplication bug for multiple secondary weapons.
    - [x] Implement a centralized weapon effect system for vehicles.
    - [x] Implement projectile system using `Area2D` for non-physical collision.
    - [x] Implement dynamic, animated damage numbers on actors.
    - [x] Implement projectile hit effects (explosions).
    - [x] Implement a generic actor death sequence (animation and cleanup).

## Phase 6: Data-Driven Architecture Refactor (Complete)

- [x] **Data-Driven Weapon System:**
    - [x] Refactored `WeaponData` to include all visual and behavioral properties (texture, offset, scale, bullet type, etc.).
    - [x] `WeaponComponent` now purely reads data from the `WeaponData` resource to configure itself.
    - [x] Fixed resource duplication issues to ensure weapon stats load correctly.
- [x] **Data-Driven Health System:**
    - [x] Removed hard-coded `max_health` from `HealthComponent`.
    - [x] `Actor` now sets its `HealthComponent`'s max health from `ActorData` on initialization.
- [x] **Data-Driven AI System:**
    - [x] Created a generic `AIBehaviorData` resource system.
    - [x] Implemented specific, reusable behaviors like `WanderBehavior` and `ChasePlayerBehavior` as resources.
    - [x] Refactored `ActorData` to include an array of `AIBehaviorData` resources.
    - [x] Refactored the base `Actor` script to execute behaviors from its data, removing all hard-coded AI logic.
    - [x] Cleaned up the old `goblin.gd` script and `goblin.tscn` scene to use the new data-driven approach.
- [x] **Achieved "Resource-Only" Entity Creation:**
    - [x] The system now supports creating new enemies by simply creating a new `ActorData` `.tres` file and composing behaviors, without writing new code or creating new scenes.
    - [x] Fixed collision issues with dynamically spawned actors by ensuring `base_actor.tscn` has a default, valid `CollisionShape2D`.

## Phase 7: Next Steps (In Progress)

- [ ] **目录结构与资源引用规范化：**
    - [x] 目录结构已完成梳理与规范化，所有资源、组件、功能模块分层清晰。
    - [x] WorldData资源类型已引入，地图区块场景引用已实现数据驱动，消除硬编码路径。
    - [ ] 持续推进所有资源、场景、数据的Inspector导出变量引用，彻底消除硬编码路径。
- [ ] **Implement "Just Frame" mechanic.**
- [ ] **Implement Virtual Lab (First Pass):**
    - [ ] Create the basic UI for the lab.
    - [ ] Implement the "Virtual Microscope" feature for viewing item details.
- [ ] **Advanced Energy Systems:**
    - [ ] Implement Hemo-Energy and Entropy Energy systems.
    - [ ] Create skill-based energy consumption mechanics.
    - [ ] Add environmental factors affecting metabolism.

## Key Achievements Summary

### Biological Systems Foundation ✅
The game now has a complete, scientifically-grounded energy management system:
- **Glucose as Universal Resource**: Serves as both currency and energy source
- **ATP as Action Energy**: Required for all player activities with realistic consumption rates  
- **Demand-Driven Metabolism**: Glucose consumption matches actual energy needs
- **Activity-Responsive System**: Energy costs scale realistically with activity intensity

### Core Gameplay Mechanics ✅  
- **Multi-tiered Movement System**: Walk and sprint with appropriate energy costs
- **Real-time Resource Management**: Live glucose and ATP tracking via HUD
- **Biological Accuracy**: System reflects real cellular energy processes
- **Strategic Depth**: Players must balance speed vs energy conservation
- **Vehicle System**: Robust vehicle implementation with `RigidBody2D` physics, tank-style controls, and a simplified enter/exit mechanism based on a non-collision design.
- **Combat Visuals & Feedback**: A rich and responsive combat experience with animated damage numbers, projectile hit effects, and a unified weapon effect system.
- **Actor Lifecycle**: A complete lifecycle for actors, including a generic death sequence with animation and cleanup.

### Technical Excellence ✅
- **Combat/Weapon/AI Unified & Reusable**: All attack behaviors for actors, enemies, and vehicles are now handled by a unified set of components (`CombatComponent`, `WeaponComponent`, `WeaponEffect`, and data-driven `AIBehavior`). This enables any entity to perform attacks, and all logic is reusable and extensible.
- **Data-Driven Architecture**: Core entities like enemies and weapons are now defined almost entirely by `Resource` files, enabling rapid content creation and iteration without new code.
- **Component-Based Design**: Logic is encapsulated in reusable components (`HealthComponent`, `StatsComponent`) and composable behaviors (`WanderBehavior`, `ChasePlayerBehavior`).
- **Float Precision Energy**: Accurate per-frame energy calculations.
- **Asynchronous Logic**: Use of `await` for timed, non-blocking actions like rhythmic combo firing.
- **Advanced Physics Handling**: Solved complex `RigidBody2D` interaction issues by using physics layers to prevent collisions between players and vehicles.
- **目录结构与资源引用规范化**：所有核心资源（如地图区块、武器、组件等）已按功能和用途分层，WorldData等资源型引用已替代硬编码路径，资源引用逐步数据驱动化。
