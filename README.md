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
-   **Phase 7 (In Progress):** Focus is now on building out advanced gameplay features like the "Just Frame" mechanic and the Virtual Lab.

---

## Getting Started

1.  **Engine:** This project is developed using **Godot 4.x**.
2.  **Clone:** Clone this repository to your local machine.
3.  **Open:** Open the project in the Godot Engine. No external dependencies are required.
4.  **Run:** The main scene is `main.tscn`. Press `F5` to run the game.

---

## Project Structure Overview

The project follows a feature-first directory structure to keep related code organized and easy to find.

```
/
|- assets/         # Raw art and sound assets
|- components/     # Reusable, self-contained scenes/scripts (e.g., health.tscn)
|  |- ai/           # Reusable AI behavior resources
|- data/           # Custom Resource files (.tres) for game data
|  |- enemies/
|  |- weapons/
|  |- items/
|- features/       # Core game features, each in its own folder
|  |- actor/        # The base actor scene and script
|  |- player/
|  |- vehicle/
|- systems/        # Global manager scripts (Autoloads)
|- ui/             # UI scenes and themes
|- main.tscn       # Main scene to launch the game
