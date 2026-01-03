# Legends of Uncharted Life

Welcome to the official repository for **Legends of Uncharted Life**, a post-apocalyptic educational Action RPG developed in Godot 4.x. This project aims to blend deep, strategic combat with a curriculum-aligned biology education, creating a unique and engaging learning experience.

---

## Gameplay Pillars

This game is built upon four core pillars that define its unique identity:

1.  **Dual System Mechanics:** The player controls both a biologically-modified human character and a customizable vehicle. These two entities have separate but interconnected stat systems, creating deep strategic choices in progression and combat.
2.  **Unified Energy-Currency:** **Glucose** is the single, central resource. It functions as both the player's life-sustaining energy and the game's universal currency. Every action, from combat to crafting to upgrading, has a direct, tangible cost, forcing meaningful strategic decisions rooted in biological principles of energy management.
3.  **Education through Gameplay:** Learning is not a separate mode but is woven into the core gameplay loop. Players learn about cellular respiration by managing their ATP, about genetics by performing gene-editing, and about ecology by restoring the wasteland.
4.  **Data-Driven Modularity:** The game is built on a highly modular, data-driven architecture. Core entities like enemies and weapons are defined as `Resource` files. This allows for immense variety and easy content creation, empowering both developers and potentially the modding community to create new challenges and tools by simply editing data, not code.

---

## Technical Highlights

The project's architecture is designed for scalability, reusability, and rapid iteration.

### Data-Driven Entity Architecture
This is the most important pattern in the project. We separate **data** (what an entity *is*) from **logic** (how it *acts*).

-   **The "Soul" (`.tres` Resources):** An entity's stats, appearance, and behaviors are defined in `Resource` files.
    -   `ActorData`: Defines an enemy's health, speed, and a list of its AI behaviors.
    -   `WeaponData`: Defines a weapon's damage, fire rate, texture, projectile type, etc.
-   **The "Container" (`.tscn` Scenes):** Generic scenes like `base_actor.tscn` act as templates. They are empty shells waiting to be given a "soul".
-   **The "Brain" (`.gd` Scripts):** Generic scripts like `actor.gd` read the data from the resource and make the entity act accordingly.

**Workflow Example: Creating a New Enemy**
1.  **Create Data:** Create a new `ActorData` resource file (e.g., `slime_data.tres`).
2.  **Configure Data:** In the Godot Inspector, set the slime's `max_hp`, `move_speed`, and add `AIBehavior` resources (like `Wander` or `JumpAttack`) to its behavior list.
3.  **Spawn in Game:** Instance the generic `base_actor.tscn` and assign your `slime_data.tres` to its `actor_data` property. The enemy is now fully functional.

### Composable AI Behaviors
Instead of monolithic AI scripts, behaviors are also `Resource` files (`AIBehaviorData`). This allows for complex AI to be built by simply mixing and matching behavior resources in an array. An enemy can have both `WanderBehavior` and `ChasePlayerBehavior`, and the `Actor` script will execute them in order.

### Component-Based Design
Common functionalities are encapsulated in reusable components (both scenes and scripts), such as:
-   `HealthComponent`
-   `StatsComponent`
-   `ATPComponent`
-   `CombatComponent`
-   `WeaponComponent`
-   `WeaponEffect`
-   Data-driven `AIBehavior`

**Unified Combat/Weapon/AI System:**  
All attack behaviors for actors, enemies, and vehicles are now handled by a unified set of components (`CombatComponent`, `WeaponComponent`, `WeaponEffect`, and data-driven `AIBehavior`). This enables any entity to perform attacks, and all logic is reusable and extensible. WeaponEffect supports flexible attack effects and visual feedback, and can be configured for different weapon types and entities. AIBehavior is assigned via data resources, allowing both player and enemy to use the same behavior system, fully data-driven.

### Game Scene Loading System
The game scene loading system takes the data-driven philosophy to the scene level, allowing complete game scenes to be configured through data resources.

**Core Architecture:**
-   `GameSceneData`: Main resource defining a complete scene configuration
-   `SpawnableEntityData`: Resource defining where and what entities to spawn (NPCs, vehicles, enemies, etc.)
-   `PlayerSpawnData`: Resource defining player spawn location and configuration
-   `game_scene.tscn`: Generic container scene that loads from GameSceneData

**Key Features:**
-   **Static Map Loading:** Reference MapData resources for map/level configuration
-   **Dynamic Entity Spawning:** Define entity types, positions, and data resources
-   **Designer-Friendly:** Configure entire scenes in the Inspector without code changes
-   **Reusable Resources:** Share entity data across multiple scenes
-   **Save/Load Integration:** Full support for SaveManager persistence

**Workflow Example: Creating a New Level**
1.  **Create GameSceneData:** Right-click in `data/game_scenes/`, create new Resource of type `GameSceneData`
2.  **Configure Map:** Set MapData reference for static map/chunks
3.  **Set Player Spawn:** Configure spawn position and optional custom player data
4.  **Add Entities:** Add SpawnableEntityData elements for enemies, vehicles, NPCs
    -   Set entity type, scene path, spawn position, and resource data
    -   Use `additional_config` for entity-specific settings
5.  **Use in Game:** Reference GameSceneData in main.tscn or load dynamically

See `docs/GAME_SCENE_SYSTEM.md` for comprehensive documentation.

### Inventory System
The inventory system provides a comprehensive item management interface with data-driven containers and intuitive UI.

**Core Components:**
-   `InventoryComponent`: Manages multiple item containers with configurable capacity and accepted item types
-   `InventoryData`: Resource defining container properties (capacity, accepted types, stored items)
-   `ItemData`: Resource defining individual items (name, description, icon, stackability, etc.)

**UI Features:**
-   **Tabbed Interface:** Multiple containers (backpack, equipment slots, etc.) displayed as separate tabs
-   **Grid Layout:** Items displayed in an 8-column grid with visual slots
-   **Item Details Panel:** Right-side panel showing selected item information (name, icon, description, quantity)
-   **Tooltip System:** Hover tooltips display formatted item information with rich text support
-   **Capacity Display:** Shows current usage vs. maximum capacity for each container

**Data-Driven Design:**
-   Container configurations stored in `ActorData` resources
-   Items defined as `Resource` files for easy content creation
-   Automatic UI generation based on container data
-   Support for unlimited capacity containers and item stacking

**Workflow Example: Adding Items to Player**
1.  **Configure Data:** Add inventory containers to `player_data.tres` (e.g., backpack with 30 slots)
2.  **Create Items:** Define new items as `ItemData` resources with icons and descriptions
3.  **Runtime Management:** Use `InventoryComponent.add_item()` to add items programmatically
4.  **UI Updates:** Inventory UI automatically reflects changes and updates displays

### Physics Model
-   **Actors (`CharacterBody2D`):** For direct, predictable control over player and AI movement.
-   **Vehicles (`RigidBody2D`):** For realistic physics-based collisions and to prevent being pushed by other entities.

---

## Current Status

The project has completed several major development phases, establishing a robust foundation for future content.

-   **Phase 1-3 (Complete):** Core architecture, save/load system, and a dynamic map-loading system are in place.
-   **Phase 4 (Complete):** The foundational biological energy system (Glucose-ATP metabolism) and sprint mechanics are fully implemented.
-   **Phase 5 (Complete):** The core combat loop, including player-vehicle systems, weapon mechanics, and visual feedback (damage numbers, effects), is complete.
-   **Phase 6 (Complete):** A major refactor to a fully data-driven architecture has been completed. Enemies, weapons, and core stats are now defined almost entirely by `Resource` files.
-   **Phase 7 (Complete):** Comprehensive inventory system with tabbed containers, item management, and detailed UI implemented.
-   **Phase 8 (Complete):** Game scene loading system implemented - complete scenes can now be configured through data resources without code changes.
-   **Phase 9 (In Progress):** Focus is now on building out advanced gameplay features like the "Just Frame" mechanic and the Virtual Lab.

---

## Getting Started

1.  **Engine:** This project is developed using **Godot 4.x**.
2.  **Clone:** Clone this repository to your local machine.
3.  **Open:** Open the project in the Godot Engine. No external dependencies are required.
4.  **Run:** The main scene is `scenes/main.tscn`. Press `F5` to run the game.

---

## Data-Driven Resource Management

- All scene, data, and resource references are managed via Inspector-exported variables or custom Resource types (e.g., WorldData), eliminating hard-coded paths.
- Map chunk scene references are managed centrally via `data/definitions/world_data.gd`.
- Each entity (player, enemy, vehicle) has a dedicated data folder, with animation and related resources colocated.

---

## Project Structure Overview

The project follows a feature-first directory structure to keep related code organized and easy to find.

```
/
├── scenes/                 # Entry scenes (main.tscn)
├── features/               # Core feature modules (actor, player, enemy, vehicle, effects, etc.)
├── components/             # Reusable components (health_component, inventory_component, etc.)
├── data/                   # All data resources and definitions (actors, vehicles, weapons, items, ai_behavior, definitions, etc.)
├── assets/                 # Raw art and audio assets
├── systems/                # Global managers (event_bus, map_manager, inventory_manager, etc.)
├── ui/                     # UI scenes and scripts (system_menu, backpack, character_creation, hud, etc.)
│   ├── system_menu/        # System menu UI (inventory, character, settings)
│   ├── backpack/           # Legacy backpack UI (superseded by system_menu)
│   └── ...
└── project.godot           # Godot project file
