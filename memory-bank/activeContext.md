# Active Context: Godot ARPG Architecture

## Current Focus
The primary focus is on establishing a solid architectural foundation for the Godot ARPG project. We have just finalized the core design patterns and project structure.

## Key Decisions Made
1.  **Hybrid Architecture Model:** We will use a combination of inheritance and composition. A `base_actor` scene will provide shared functionality for all characters (player, enemies), while specific behaviors will be added as modular components. This decision was made to balance code reusability with flexibility.
2.  **Data-Driven Design:** Game data (stats, items, etc.) will be managed using Godot's `Resource` system. This decouples data from code, empowering designers and simplifying content creation.
3.  **Component-Based Scenes:** Entities will be built from small, reusable component scenes (e.g., `HealthComponent`, `AIComponent`).
4.  **Global Event Bus:** Decoupled systems will communicate via a global `EventBus` (Autoload singleton) to minimize hard dependencies.
5.  **Feature-First Directory Structure:** The project's file system will be organized by feature (e.g., `/features/player`, `/features/inventory`) to keep related files together.

## Next Steps
1.  **Create `progress.md`:** Finalize the initial memory bank setup by creating the progress tracking document.
2.  **Present the Plan:** Summarize the complete architectural plan to the user for final approval.
3.  **Transition to Implementation:** Once the plan is approved, the next logical step is to move into "Act Mode" to begin creating the directory structure and core scripts as defined in `systemPatterns.md`.
