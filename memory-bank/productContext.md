# UnchartedLife Product Context

## 1. Core Vision
"UnchartedLife" is a top-down 2D RPG with a focus on exploration, character progression, and tactical combat. The player explores a mysterious world, grows stronger by defeating enemies, and customizes their character through stats, equipment, and skills.

## 2. Core Gameplay Loop
1.  **Explore:** The player navigates through the game world.
2.  **Combat:** The player engages in real-time combat with enemies.
3.  **Progress:** The player gains experience, levels up, and finds items.
4.  **Customize:** The player uses new items, equipment, and skills to enhance their abilities.
5.  **Repeat:** The player, now stronger, can explore new, more dangerous areas.

## 3. Key Features (Current & Next)

### Implemented
-   **Data-Driven Actors:** Player and enemies are built on a flexible, data-driven `Actor` base class.
-   **Component-Based Stats:** Core attributes like health and speed are managed by reusable components.
-   **EventBus System:** A global event bus allows for decoupled communication between game systems.
-   **Basic Combat:** Actors can take damage.
-   **UI:** Main Menu, Character Creation, HUD, and a pausable System Menu are in place.
-   **Save/Load System:** A robust, multi-slot save system allows players to save and load their progress.

### Next Up: Phase 3 - Core Gameplay Systems
-   **Stats System:** Expand the existing `StatsComponent` to include a wider range of RPG attributes like attack power, defense, critical hit chance, etc. This will form the numerical backbone of the game.
-   **Inventory System:** Create a system for the player to acquire, store, and manage items found in the world (e.g., potions, materials). This involves both data structures and a UI.
-   **Equipment System:** A specialized part of the Inventory System. Players can equip specific items (weapons, armor) into designated slots, which will directly modify their stats from the Stats System.
-   **Skill System:** A framework for defining and using character skills. This could include passive bonuses or active abilities used in combat.

## 4. Target Architecture
-   **Feature-First Structure:** The project is organized by features (e.g., `player`, `enemy`, `ui`) rather than by asset type.
-   **Decoupled Systems:** Use of singletons and the `EventBus` to keep systems independent and maintainable.
-   **Data-Driven Design:** Use of `Resource` files (`ActorData`, `ItemData`, etc.) to define game entities, making it easy to add new content without changing code.
-   **Component-Based Actors:** Actors are composed of smaller, reusable components (e.g., `HealthComponent`, `StatsComponent`, `InventoryComponent`) to promote flexibility.
