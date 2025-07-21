# System Patterns: Godot ARPG

This document outlines the architectural patterns for building the ARPG, based on a hybrid model of inheritance and composition.

## 1. Directory Structure
A clean directory structure is crucial. We will follow a feature-first approach.

```
/
|- addons/         # For third-party plugins
|- assets/         # Raw art and sound assets (e.g., .blend, .psd, .wav)
|- components/     # Reusable, self-contained scenes/scripts (e.g., health.tscn, stats.tscn)
|- data/           # Custom Resource files (.tres) for game data
|  |- items/
|  |- skills/
|  |- enemies/
|- features/       # Core game features, each in its own folder
|  |- actor/        # The base actor scene and script
|  |  |- base_actor.tscn
|  |  |- actor.gd
|  |- player/
|  |  |- player.tscn
|  |  |- player.gd
|  |- enemy/
|  |  |- goblin.tscn
|  |  |- goblin.gd
|  |- inventory/
|  |  |- inventory_ui.tscn
|  |  |- inventory_system.gd
|- systems/        # Global manager scripts (Autoloads)
|  |- event_bus.gd
|  |- save_manager.gd
|- ui/             # UI scenes and themes
|  |- hud/
|  |  |- hud.tscn
|  |- main_menu/
|- main.tscn       # Main scene to launch the game
```

## 2. Scene & Entity Architecture: A Hybrid Approach
We will use a base `Actor` scene for shared functionality (inheritance) and add specific behaviors via components (composition).

**Step 1: The `base_actor.tscn` (Inheritance Base)**
- **Scene Root:** `CharacterBody2D`
- **Script:** `actor.gd` - This script defines core logic and properties common to all characters, like `health`, `stats`, and a `take_damage()` function.
- **Core Components (Composition):**
    - `StatsComponent`: A node holding all character stats (strength, dexterity, etc.).
    - `HealthComponent`: A node managing current/max health and emitting signals like `health_changed` and `died`.
    - `HurtboxComponent`: An `Area2D` for detecting incoming damage.

**Step 2: Creating Specific Entities (Inheritance + Composition)**
- **`player.tscn`:**
    - **Inherits from:** `base_actor.tscn`.
    - **Additional Components (Composition):**
        - `PlayerInputComponent`: Handles keyboard/gamepad input.
        - `InventoryComponent`: Manages the player's items.
        - `PlayerSprite`: Handles player-specific animations.

- **`goblin.tscn`:**
    - **Inherits from:** `base_actor.tscn`.
    - **Additional Components (Composition):**
        - `AIComponent`: Controls the goblin's behavior (e.g., chase, attack).
        - `LootDropComponent`: Determines what items to drop on death.
        - `HitboxComponent`: An `Area2D` for dealing damage to the player.

**Benefits of this Hybrid Model:**
- **Code Reusability:** Common logic lives in `actor.gd`.
- **Flexibility:** Easily create new actors by inheriting from `base_actor.tscn` and composing new components.
- **Clear Separation of Concerns:** Each component has a single, well-defined responsibility.

## 3. Communication Patterns
- **Pattern 1: Direct Signal Usage (Within an Actor):** For communication inside a single entity. The `HurtboxComponent` emits a `was_hurt` signal, and the `actor.gd` script listens to it.
- **Pattern 2: Global Event Bus (Between Decoupled Systems):** An Autoload script `EventBus` for game-wide events. When an actor's `HealthComponent` emits `died`, the `actor.gd` script tells the `EventBus` to emit a global `actor_died` event, which other systems (UI, quests) can listen to.

## 4. Data Management: `Resource`-Driven Design
All game data (stats, items, skills) will be defined using custom `Resource` scripts to separate data from code.
- **`ActorData.gd` (extends `Resource`):** `base_stats`, `initial_health`, etc.
- **`ItemData.gd` (extends `Resource`):** `item_name`, `icon`, `effects`.
- The `StatsComponent` in `base_actor.tscn` will have an `export var data: ActorData` to link the data file. This makes creating new character types as simple as creating a new data resource.

## 5. Chunk-Based Map Streaming
- **Pattern:** The game world is divided into a grid of chunks, each represented by a separate scene file (`.tscn`). A manager loads and unloads these chunks based on player proximity.
- **Implementation:** The `MapManager` autoload singleton tracks the player's position, calculates the current chunk coordinate, and instances/frees chunk scenes as needed.
- **Benefit:** Allows for massive game worlds with minimal memory footprint and fast initial load times.

## 6. Dual System (Player/Vehicle)
- **Pattern:** The player's capabilities are split between two distinct but interconnected entities: the biological **Player Character** and the mechanical **Vehicle**.
- **Implementation:** The Player node will manage biological stats (HP, ATP, etc.), while a separate Vehicle node (to be created) will manage mechanical stats (Armor, Mobility). The two will interact through well-defined interfaces.
- **Benefit:** Creates deep, strategic gameplay where players must balance the development of both systems.

## 7. Unified Resource (Glucose as Energy/Currency)
- **Pattern:** A single resource, **Glucose**, serves as the foundation for both the energy system (actions, skills) and the economic system (currency, crafting).
- **Implementation:** A global `PlayerData` singleton will track the player's current Glucose total. All systems that consume or award resources will interface with this singleton.
- **Benefit:** Tightly couples the game's economy with its core gameplay loop, making every economic decision a strategic gameplay decision.
