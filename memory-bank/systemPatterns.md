# System Patterns: 《执笔问道录》

This document outlines the architectural patterns for building the ARPG, based on a hybrid model of inheritance and composition. The core data-driven and component-based philosophy is retained and adapted for the new game design.

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
        - `InkEnergyComponent`: Manages "文气" (Ink Energy).
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
    - **2025.11系统升级及后续扩展：**
        - 新增 `VehicleCombatComponent`，支持主副武器管理、充能、发射、连击、ATP 消耗等机制，专为载具战斗设计。
        - 新增 `ActorCombatComponent`，专为角色（玩家/敌人）管理武器发射、蓄力、连击等机制。
        - `WeaponComponent` 负责武器逻辑（发射、蓄力、弹药管理）。
        - 新增 `AttributeComponent`，统一管理角色属性（如生命、代谢等）。
        - 新增 `VehicleStatsComponent`，管理载具性能。
        - 新增 `InteractableComponent`，支持玩家与拾取物交互。
        - 新增 `InventoryComponent`，支持物品存取与背包管理。
        - 新增 `Pickup` 类，实现物品收集与视觉反馈。
        - 玩家机关枪武器及其资源、场景已集成至上述组件体系。
        - 组件间通过唯一数据引用和接口解耦，支持灵活扩展与维护。
        - `BioBlitzManager` 负责基于答题的战斗循环，`BioBlitzSelection` 场景支持章节/知识点选择。
        - 新增角色菜单 UI，支持玩家选项操作。
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

## 6. Data-Driven System Extensions for 《执笔问道录》

The following patterns extend the core data-driven architecture to support the unique mechanics of the new game design.

### 6.1. "乱墨妖" (Enemy) and "题目" (Question) Integration
The existing `ActorData` is extended to integrate the educational core.
- **`EnemyData.gd`** (formerly `ActorData.gd`): This `Resource` now includes a critical new property:
    - **`question_data: QuestionData`**: A direct link to a `QuestionData` resource. A "乱墨妖" cannot be defeated by simply reducing its HP to zero. The final blow must be a correct answer to its associated question.
- **`QuestionData.gd`**: A new `Resource` script defining a question.
    - **`content`**: The question's text, images, or formulas.
    - **`type`**: The question type (e.g., multiple choice, fill-in-the-blank, structured solution).
    - **`answer_key`**: A structured representation of the correct answer.
    - **`evaluation_nodes`**: For complex problems, an array of sub-problems or key steps for procedural evaluation.
    - **`knowledge_link`**: A link to the specific `KnowledgeUnitData` this question assesses.

### 6.2. "书魂印" (Book-Soul Seal) as a Skill System
This system replaces the generic `WeaponData` for the player's primary abilities.
- **`BookSoulSealData.gd`**: A `Resource` defining a skill.
    - **`seal_type`**: An enum (`MAIN_SEAL`, `SUB_SEAL`) to determine if it's a main or auxiliary skill.
    - **`effects`**: An array of `EffectData` resources (e.g., `DealDamageEffect`, `ApplyStatusEffect`, `ModifyStatEffect`). This allows for highly composable skill design.
    - **`ultimate_attack`**: If it's a `MAIN_SEAL`, this defines the "破妄一击" (Ultimate Attack) triggered by a correct answer.
- **`CombatComponent.gd`**: This component is updated with slots for `main_seal` and an array of `sub_seals`. It reads the `BookSoulSealData` to execute skill logic.

### 6.3. "百川归海" (Inverted) Skill Tree
- **`SkillTreeData.gd`**: A `Resource` that defines the relationship between basic and advanced skills.
    - **`source_seals`**: An array of `BookSoulSealData` resources representing the foundational "leaf" skills.
    - **`trunk_seal`**: The advanced `BookSoulSealData` that is unlocked upon mastery.
    - **`mastery_requirements`**: Defines the proficiency level needed for each `source_seal` to trigger the "顿悟三阶试炼" (Enlightenment Trial).
- **`PlayerProgress.gd`**: A global singleton (or part of `SaveManager`) that tracks the player's proficiency with each `BookSoulSealData`. The `GameManager` monitors this progress to initiate trials.

## 7. Offline Evaluation Engine
This is a critical new system for local, offline-first question evaluation.
- **Pattern:** Client-Local Service.
- **Implementation:**
    1.  **Godot-Side (`EvaluationClient.gd`):**
        - When a player submits an answer, this script packages the `QuestionData` and the player's input into a standardized format (e.g., JSON).
        - It sends this data via a local HTTP request to the background evaluation service.
    2.  **Local Evaluation Service (Python/SymPy):**
        - A lightweight Python service, bundled with the game executable, runs silently in the background.
        - It uses a library like **SymPy** for symbolic mathematics.
        - **Capabilities:**
            - **Expression Parsing:** Converts string inputs like `(x+1)*x` into a symbolic representation.
            - **Equivalence Checking:** Determines if the player's answer is mathematically equivalent to the `answer_key` (e.g., `x**2 + x`).
            - **Numerical Tolerance:** Compares floating-point answers within an acceptable margin of error.
            - **Procedural Validation:** For structured problems, it checks the player's solution against the `evaluation_nodes`.
        - The service returns a structured result (e.g., `{"correct": true, "feedback": "Excellent!"}`) to Godot.

## 8. PBL Project Evaluation
This system evaluates open-ended projects using a rule-based, offline approach.
- **`PBLProjectData.gd`**: A `Resource` defining a project.
    - **`objective`**: The goal of the project.
    - **`constraints`**: An array of `ConstraintRule` resources (e.g., `EnergyConservationRule`, `MaxBudgetRule`). Each rule is a script that can validate the player's submission.
    - **`kpis`**: An array of `KeyPerformanceIndicator` resources that define how to score the project (e.g., `EfficiencyKPI`, `CostKPI`).
- **Evaluation Flow:**
    1.  **Constraint Validation:** The system first iterates through all `constraints`. If any rule fails, the submission is rejected.
    2.  **Simulation & KPI Calculation:** If constraints are met, the system runs a simulation (using Godot's physics or a custom model) and calculates the values for each KPI.
    3.  **Scoring:** A final score is calculated based on the KPI results using a predefined formula.
