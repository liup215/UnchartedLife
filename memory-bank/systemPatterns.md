# System Patterns: Godot ARPG

This document outlines the architectural patterns for building the ARPG, based on a hybrid model of inheritance and composition.

## 1. Directory Structure
A clean directory structure is crucial. The project now follows a feature-first and data-driven approach, with clear separation of assets, components, data, features, systems, and UI. All resource references are moving toward data-driven (Inspector-exported) patterns.

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
├── components/             # Reusable, self-contained scenes/scripts (e.g., health_component.tscn)
│   ├── health_component.tscn
│   ├── combat_component.tscn
│   ├── stats_component.tscn
│   └── weapon_component.tscn
│
├── data/                   # All game data resources and definitions
│   ├── definitions/        # Resource class scripts (e.g., actor_data.gd, world_data.gd)
│   ├── actors/             # Actor data (player, enemies, with per-entity folders)
│   ├── vehicles/           # Vehicle data and components
│   │   ├── basic_tank_data.tres
│   │   └── components/
│   │       ├── engines/
│   │       └── chips/
│   ├── weapons/            # Weapon data (actor_weapons, vehicle_weapons)
│   ├── ai_behavior/        # AI behavior resource instances
│   └── items/              # Item data
│
├── assets/                 # Raw art/audio assets (png, wav, etc.)
│   ├── sprites/
│   ├── tilesets/
│   └── effects/
│
├── systems/                # Global manager scripts (Autoloads)
│   ├── event_bus.gd
│   ├── save_manager.gd
│   ├── main_game_manager.gd
│   └── map_manager.gd
│
├── ui/                     # UI scenes and themes
│   ├── hud/
│   ├── main_menu/
│   └── character_creation/
│
└── project.godot           # Godot project file
```

**Notes:**
- All map chunk scene references are now managed via a WorldData resource (`data/definitions/world_data.gd`), eliminating hard-coded paths.
- All resource, scene, and data references are moving toward Inspector-exported variables for maximum flexibility and maintainability.
- Each entity (player, enemy, vehicle) has its own data folder for core data and animation resources.

## 2. Data-Driven Entity Creation
**Goal:** To create new enemies, weapons, or items by only creating and modifying `Resource` (`.tres`) files, without needing new scenes (`.tscn`) or scripts (`.gd`).

### 2.1. Component-Based Actor (The "Container")
- **`base_actor.tscn`**: This is the universal template for all living entities.
    - **Root Node**: `CharacterBody2D`.
    - **Script**: `actor.gd`. This script is a generic "brain" that knows how to use its components but contains no specific logic (like "how to be a goblin").
    - **Core Components**:
        - `HealthComponent`: Manages health.
        - `StatsComponent`: A bridge to the data resource.
        - `ATPComponent`: Manages energy.
        - `CollisionShape2D`: Provides a default physical body.
- **`actor.gd`'s Role**:
    - It has an `@export var actor_data: ActorData`. This is the **only** thing that needs to be set from the outside to define what the actor *is*.
    - In `_ready()`, it reads from `actor_data` and configures its components (e.g., `health_component.set_max_health(actor_data.max_hp)`).
    - In `_physics_process()`, it iterates through the behaviors defined in `actor_data` and executes them.

### 2.2. Data Resources (The "Soul")
- **`ActorData.gd`**: A `Resource` script that defines everything an actor *is*.
    - **Stats**: `max_hp`, `move_speed`, etc.
    - **Behaviors**: An array of `AIBehaviorData` resources that define how the actor acts.
- **`WeaponData.gd`**: A `Resource` script defining a weapon's stats, appearance, and projectile type.
- **`AIBehaviorData.gd`**: A base `Resource` for AI behaviors.
    - **Concrete Behaviors**: `WanderBehaviorData.gd`, `ChasePlayerBehaviorData.gd`. These are also `Resource` scripts, allowing their parameters (like `detection_radius`) to be tweaked in the Inspector.

### 2.3. The Workflow
1.  **To Create a New Enemy ("Slime")**:
    - **Create `slime_data.tres`**: A new `ActorData` resource.
    - **Configure `slime_data.tres`**:
        - Set `max_hp = 20`, `move_speed = 100`.
        - In the `behaviors` array, add a `WanderBehavior.tres` and maybe a new `JumpAttackBehavior.tres`.
    - **To Spawn a Slime**:
        - Instance `base_actor.tscn`.
        - Set its `actor_data` property to the `slime_data.tres` resource.
        - Add it to the scene.

**Benefits:**
- **Rapid Iteration**: Designers can create and balance dozens of enemies without programmer intervention.
- **Decoupling**: The `Actor` scene is completely decoupled from any specific enemy type.
- **Flexibility**: Behaviors can be mixed and matched to create complex AI with minimal effort.

## 3. Communication Patterns
- **Pattern 1: Direct Signal Usage (Within an Actor):** For communication inside a single entity. The `HealthComponent` emits a `died` signal, and the `actor.gd` script listens to it to trigger the death sequence.
- **Pattern 2: Global Event Bus (Between Decoupled Systems):** An Autoload script `EventBus` for game-wide events. When an actor's `HealthComponent` emits `died`, the `actor.gd` script tells the `EventBus` to emit a global `actor_died` event, which other systems (UI, quests) can listen to.

## 4. Combat and Visual Effects Logic

- **Unified Combat/Weapon/AI System**:
    - All attack behaviors for actors, enemies, and vehicles are now handled by a unified set of components: `CombatComponent`, `WeaponComponent`, `WeaponEffect`, and data-driven `AIBehavior`. This enables any entity to perform attacks, and all logic is reusable and extensible.
    - `WeaponEffect` supports flexible attack effects and visual feedback, and can be configured for different weapon types and entities.
    - `AIBehavior` is assigned via data resources, allowing both player and enemy to use the same behavior system, fully data-driven.

- **Prejecsilm2D`)**: (`Area2D`)
    - Projectiresj(liees ull(tu)l)eemimplpmnnted atd`Are 2D` aosAs. Tre` nll. sTthlmoto dececttllllisiiowtwith hPhysicsB`dy` dodysd(lik  ekeeiis) wishoutwouplyi g physical poryeg prevehtingsunwcnaef pushr,g effectsn
w   - an g`bodf_ected`igo triggr ht ogic
    - U`borhigtingaa va  ddt rget, oheiprojg hiletoesmagespwsvsal"ht ec"(.g.,xplotinvattmheien) deada, svsimmudiatll"hremtvefeic(glf.(`qu un_ideh()`)n immediately removes itself (`queue_free()`).

- **CrnlralizeddWpaponnEffect
    - Instead sf eaahewwaponeona  vehicensh viage tno tn vihuall`ffscrinide,ttieatVes sle` icript shwdWnstantfatec sle,sd`WoE` node
    - When firing, then ComfatComping, ` rtthieves thisComnble effect aode tndopapens`i  drwnethrouvh the `WeaponComponent` to ttes`WeapsnData`le effect node and passes it down through the `WeaponComponent` to the `WeaponData`.
    - The `WeaponData`'s `fire` method then calls a `fire` method on this shared effect node, passing in parameters like origin, target, and damage. This allows the single effect node to handle different weapon types (e.g., spawning different projectiles).

- **Dynamic Visual Feedback**:
    - **Damage Numbers**: When an `Actor`'s `take_damage` method is called, it dynamically creates a `Label` node, adds it to the scene root, and uses a `Tween` to animate it moving upwards and fading out. This provides clear, immediate feedback for damage dealt.
    - **Hit Effects**: When a projectile hits a target, it dynamically creates a `Sprite2D` with an explosion animation, also managed by a `Tween` for playback and automatic cleanup.

## 5. Chunk-Based Map Streaming
- **Pattern:** The game world is divided into a grid of chunks, each represented by a separate scene file (`.tscn`). A manager loads and unloads these chunks based on player proximity.
- **Implementation:** The `MapManager` autoload singleton tracks the player's position, calculates the current chunk coordinate, and instances/frees chunk scenes as needed.
- **Benefit:** Allows for massive game worlds with minimal memory footprint and fast initial load times.

## 6. Dual System (Player/Vehicle)
- **Pattern:** The player's capabilities are split between two distinct but interconnected entities: the biological **Player Character** and the mechanical **Vehicle**.
- **Implementation:** The Player node will manage biological stats (HP, ATP, etc.), while a separate Vehicle node will manage mechanical stats (Armor, Mobility). The two will interact through well-defined interfaces.
- **Benefit:** Creates deep, strategic gameplay where players must balance the development of both systems.

## 7. Unified Resource (Glucose as Energy/Currency)
- **Pattern:** A single resource, **Glucose**, serves as the foundation for both the energy system (actions, skills) and the economic system (currency, crafting).
- **Implementation:** A global `PlayerData` singleton will track the player's current Glucose total. All systems that consume or award resources will interface with this singleton.
- **Benefit:** Tightly couples the game's economy with its core gameplay loop, making every economic decision a strategic gameplay decision.
